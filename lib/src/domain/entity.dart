part of dorm;

abstract class Entity extends ChangeNotifier implements Externalizable {
  
  static final EntityAssembler ASSEMBLER = new EntityAssembler();
  static final EntityFactory FACTORY = new EntityFactory();
  static Serializer _serializerWorkaround;
  static Timer _observableDirtyCheckTimeout;
  static int _nextUid = 1;
  
  //-----------------------------------
  //
  // Private properties
  //
  //-----------------------------------
  
  EntityScan _scan;
  bool _isPointer = false;
  int _uid = _nextUid++;
  
  bool get isPointer => _isPointer;
  
  static void DO_SCAN([String R, Function C]) {}
  
  //-----------------------------------
  //
  // Public properties
  //
  //-----------------------------------

  bool lastDeserializationWasUpdate = false;
  
  //-----------------------------------
  // uid
  //-----------------------------------
  
  int get uid => _uid;
  
  //-----------------------------------
  // isMutable
  //-----------------------------------
  
  bool get isMutable => _scan._root.isMutableEntity;
  
  //-----------------------------------
  // refClassName
  //-----------------------------------
  
  String get refClassName;
  
  //-----------------------------------
  //
  // Operator overloads
  //
  //-----------------------------------
  
  dynamic operator [](Symbol propertyField) {
    if (propertyField == #hashCodeInternal) return _uid;
    
    final _DormProxyPropertyInfo result = _scan._proxies.firstWhere(
      (_DormProxyPropertyInfo entry) => (entry.info.propertySymbol == propertyField),
      orElse: () => null
    );
    
    return (result != null) ? (result.proxy.isLazy) ?  result.proxy.getLazyValue(this) : result.proxy._value : null;
  }
  
  void operator []=(Symbol propertyField, dynamic propertyValue) {
    final _DormProxyPropertyInfo result = _scan._proxies.firstWhere(
        (_DormProxyPropertyInfo entry) => (entry.info.propertySymbol == propertyField),
        orElse: () => null
    );
    
    if (result != null) result.proxy.value = notifyPropertyChange(
        result.proxy._propertySymbol, 
        result.proxy._value,
        propertyValue
    );
  }
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  @override
  /**
   * Notify that the field [name] of this object has been changed.
   *
   * The [oldValue] and [newValue] are also recorded. If the two values are
   * equal, no change will be recorded.
   *
   * For convenience this returns [newValue].
   */
  dynamic notifyPropertyChange(Symbol field, Object oldValue, Object newValue) {
    if (oldValue != newValue) _scheduleDirtyCheck(
        super.notifyPropertyChange(field, oldValue, newValue)    
    );
    
    return newValue;
  }
  
  /**
   * Updates the default value for the field [propertyName] to [propertyValue] on the [Entity].
   * 
   * Use this feature to clear the [Entity]'s dirty state, typically after the [Entity]
   * was persisted.
   * 
   * Example:
   *  - Entity entity = new Entity();
   *  - entity.foo = bar;
   *  - print(entity.isDirty()); //true
   *  - entity.setDefaultPropertyValue('foo', bar);
   *  - print(entity.isDirty()); //false
   */
  bool setDefaultPropertyValue(Symbol propertyField, dynamic propertyValue) {
    final _DormProxyPropertyInfo result = _scan._proxies.firstWhere(
        (_DormProxyPropertyInfo entry) => (entry.info.propertySymbol == propertyField),
        orElse: () => null
    );
    
    if (result != null) {
      result.proxy._defaultValue = propertyValue;
      result.proxy._value = propertyValue;
      
      if (!isUnsaved()) {
        _scan.buildKey();
        
        if (!_scan._keyChain.entityScans.contains(_scan)) _scan._keyChain.entityScans.add(_scan);
      }
      
      return true;
    }
    
    return false;
  }
  
  /**
   * Updates all [Entity] properties' default values to the current values.
   * 
   * Similar to [setDefaultPropertyValue], except this method will run on all fields.
   */
  void setCurrentStatusIsDefaultStatus({bool recursively: false}) => _setCurrentStatusIsDefaultStatusImpl(recursively, <Entity>[]);
  
  void _setCurrentStatusIsDefaultStatusImpl(bool recursively, List<Entity> list) {
    if (!list.contains(this)) list.add(this);
    else return;
    
    if (recursively) {
      _scan._proxies.forEach(
            (_DormProxyPropertyInfo entry) {
              entry.proxy._defaultValue = entry.proxy._value;
              
              if (entry.proxy.value is Entity) entry.proxy.value._setCurrentStatusIsDefaultStatusImpl(true, list);
              else if (entry.proxy.value is Iterable) {
                entry.proxy.value.forEach(
                   (dynamic listItem) {
                     if (listItem is Entity) listItem._setCurrentStatusIsDefaultStatusImpl(true, list);
                   }
                );
              }
            }
          );
    }
    else _scan._proxies.forEach(
        (_DormProxyPropertyInfo entry) => entry.proxy._defaultValue = entry.proxy._value
    );
  }
  
  /**
   * Resets all [Entity] properties so that all fields are again equal to the default values.
   * 
   * Use this feature to revert any changes to the [Entity]'s fields.
   */
  void revertChanges() => _scan._proxies.forEach(
      (_DormProxyPropertyInfo entry) => this[entry.proxy._propertySymbol] = entry.proxy._defaultValue
  );
  
  /**
   * Unrolls all [Entity] properties and collections to a one-dimensional [List].
   * 
   * This feature is very handy when preparing an [Entity] and all its related [Entity] instances
   * for data persistance.
   * 
   * Example:
   *  - Entity foo = new Entity();
   *  - foo.bar = new Bar();
   *  - foo.bar.bazList = <Baz>[new Baz(), new Baz()];
   *  - foo.getEntityTree(); // List containing [foo, bar, bazA, bazB]
   */
  List<Entity> getEntityTree({List<Entity> traversedEntities}) {
    final List<Entity> tree = (traversedEntities != null) ? traversedEntities : <Entity>[];
    
    tree.add(this);
    
    _scan._proxies.forEach(
        (_DormProxyPropertyInfo entry) {
          if (entry.proxy._value is Entity) {
            final Entity entity = entry.proxy._value as Entity;
            
            if (!tree.contains(entity)) entity.getEntityTree(traversedEntities: tree);
          } else if (entry.proxy._value is ObservableList) {
            final ObservableList subList = entry.proxy._value as ObservableList;
          
            subList.forEach(
              (dynamic subListEntry) {
                if (subListEntry is Entity) {
                  final Entity subListEntity = subListEntry as Entity;
                  
                  if (!tree.contains(subListEntity)) subListEntity.getEntityTree(traversedEntities: tree);
                }
              }
            );
          }
        }
    );
    
    return tree;
  }
  
  static final Map<String, HashSet<Symbol>> _identityFieldsMap = <String, HashSet<Symbol>>{};
  
  /**
   * Unrolls all [Entity] identity fields to a one-dimensional [List]
   */
  HashSet<Symbol> getIdentityFields() {
    HashSet<Symbol> fields = _identityFieldsMap[refClassName];
    
    if (fields != null) return fields;
    
    fields = new HashSet<Symbol>.identity();
    
    _scan._identityProxies.forEach(
      (_DormProxyPropertyInfo entry) => fields.add(entry.info.propertySymbol) 
    );
    
    _identityFieldsMap[refClassName] = fields;
    
    return fields;
  }
  
  HashMap<Symbol, dynamic> _insertValuesMap;
  bool _hasInsertValuesMap = false;
  
  /**
   * Returns a [Map] of all identity fields where the key is the field's name
   * and the value is the corresponding insert value.
   * 
   * Example:
   *  - entity Foo has an identity field fooId
   *  - Hibernate will create an insert statement when the value of fooId = 0
   *  - Hibernate will create an update statement when the value of fooId != 0
   *  - foo.getInsertValues() // key: 'fooId', value: 0
   */
  Map<Symbol, dynamic> getInsertValues() {
    if (_hasInsertValuesMap) return _insertValuesMap;
    
    _insertValuesMap = new HashMap<Symbol, dynamic>.identity();
    
    _scan._identityProxies.forEach(
      (_DormProxyPropertyInfo entry) => _insertValuesMap[entry.info.propertySymbol] = entry.proxy._insertValue 
    );
    
    _hasInsertValuesMap = true;
    
    return _insertValuesMap;
  }
  
  /**
   * Returns the String representation of a property using the property symbol
   */
  String getPropertyByField(Symbol propertyField) => _scan._root._symbolToProperty[propertyField];
  
  /**
   * Returns the Symbol representation of a property using the property name as String
   */
  Symbol getFieldByProperty(String property) => _scan._root._propertyToSymbol[property];
  
  /**
   * Returns generic annotation attached to a property field, if any exists
   */
  Map<String, dynamic> getGenericAnnotations(Symbol propertyField) {
    final Map<String, dynamic> defaultReturn = const <String, dynamic>{};
    final _DormProxyPropertyInfo matchingInfo = _scan._proxies.firstWhere(
      (_DormProxyPropertyInfo proxyInfo) => (proxyInfo.info.propertySymbol == propertyField)    
    );
    
    final Map<String, dynamic> result = (matchingInfo != null) ? matchingInfo.proxy.genericAnnotations : defaultReturn;
    
    return (result == null) ? defaultReturn : result;
  }
  
  /**
   * Will return [true] when all identity fields are equal to the corresponding insert values.
   * 
   * Will return [false] when at least one identity field does not match its insert value.
   * 
   * Example:
   *  - Entity entity = new Entity()..entityId = 0; // inserts when entityId = 0
   *  - print(entity.isUnsaved()); // true
   *  - entity.entityId = 1;
   *  - print(entity.isUnsaved()); // false
   */
  bool isUnsaved() {
    final int len = _scan._identityProxies.length;
    
    for (int i=0; i<len; i++) {
      _DormProxyPropertyInfo entry = _scan._identityProxies[i];
      
      if (entry.proxy._value != entry.proxy._insertValue) return false;
    }
    
    return true;
  }
  
  /**
   * Resets all identity fields to their corresponding insert values so that this [Entity]
   * 
   * will be treated as a new [Entity] with an insert statement rather than an update statement.
   * 
   * Use this to quickly create a duplicate of one [Entity].
   */
  void setUnsaved({bool recursively: false, bool asNewDefaultValue: false}) => _setUnsavedImpl(recursively, asNewDefaultValue, <Entity>[]);
  
  void _setUnsavedImpl(bool recursively, bool asNewDefaultValue, List<Entity> list) {
    if (!list.contains(this)) list.add(this);
    else return;
    
    if (!isMutable) return;
    
    if (recursively) {
      _setUnsavedImpl(false, asNewDefaultValue, list);
      
      _scan._proxies.forEach(
         (_DormProxyPropertyInfo entry) {
           if (entry.proxy.value is Entity) entry.proxy.value._setUnsavedImpl(true, asNewDefaultValue, list);
           else if (entry.proxy.value is Iterable) {
             entry.proxy.value.forEach(
                (dynamic listItem) {
                  if (listItem is Entity) listItem._setUnsavedImpl(true, asNewDefaultValue, list);
                }
             );
           }
         }
      );
    }
    
    _scan._identityProxies.forEach(
      (_DormProxyPropertyInfo entry) => entry.proxy._value = notifyPropertyChange(
          entry.proxy._propertySymbol, 
          entry.proxy._value,
          entry.proxy._insertValue
      )
    );
    
    if (asNewDefaultValue) setCurrentStatusIsDefaultStatus();
  }
  
  static final Map<String, HashSet<Symbol>> _propertyList = <String, HashSet<Symbol>>{};
  
  /**
   * Returns a [List] containing [Symbol]s of all properties belonging to this [Entity].
   */
  HashSet<Symbol> getPropertyList() {
    HashSet<Symbol> properties = _propertyList[refClassName];
    
    if (properties != null) return properties;
    
    properties = new HashSet<Symbol>.identity();
    
    _scan._proxies.forEach(
      (_DormProxyPropertyInfo entry) => properties.add(entry.info.propertySymbol)
    );
    
    _propertyList[refClassName] = properties;
    
    return properties;
  }
  
  List<String> getAmfEncodingSequence() => _scan._root._amfSeq;
  
  /**
   * Returns the metadata attached to a specific property.
   * 
   * The metadata can be combination of the following :
   * [Id], [Lazy], [NotNullable], [DefaultValue], [Transient], [Immutable], [LabelField] or [Annotation]
   */
  MetadataExternalized getMetadata(Symbol propertyField) {
    final _DormProxyPropertyInfo result = _scan._proxies.firstWhere(
        (_DormProxyPropertyInfo entry) => (entry.info.propertySymbol == propertyField),
        orElse: () => null
    );
    
    return (result != null) ? result.info.metadataCache._getMetadataExternal() : null;
  }
  
  /**
   * Duplicates the [Entity] and any recusrive entities to a new [Entity].
   */
  Entity duplicate({List<Symbol> ignoredSymbols: null}) => _duplicateImpl(<_ClonedEntityEntry>[], ignoredSymbols);
  
  /**
   * Duplicates the [Entity] and any recusrive entities to a new [Entity].
   */
  void duplicateFrom(Entity otherEntity, {List<Symbol> ignoredSymbols: null}) {
    Entity clone = otherEntity.duplicate(ignoredSymbols: ignoredSymbols);
    
    _scan._proxies.forEach(
      (_DormProxyPropertyInfo proxyInfo) {
        if (
          (ignoredSymbols == null) ||
          !ignoredSymbols.contains(proxyInfo.info.propertySymbol)
        ) this[proxyInfo.info.propertySymbol] = clone[proxyInfo.info.propertySymbol];
      }
    );
  }
  
  /**
   * Validates the values of this [Entity] using the associated metadata.
   * 
   * Returns a [List] of [MetadataValidationResult].
   */
  List<MetadataValidationResult> validate() {
    MetadataValidationResult validationResult;
    List<MetadataValidationResult> validationResultList = <MetadataValidationResult>[];
    
    _scan._proxies.forEach(
        (_DormProxyPropertyInfo entry) {
          validationResult = entry.proxy.validate(this);
          
          if (validationResult != null) validationResultList.add(validationResult);
        }
    );
    
    return validationResultList;
  }
  
  /**
   * Scans the [Entity]'s properties for any changes, returns [true] if the [Entity] has changes,
   * or returns [false] if it is untouched.
   */
  bool isDirty({bool ignoresUnsavedStatus: false, Iterable<String> ignoredProperties}) {
    if (!isMutable) return false;
    
    final bool isNew = ignoresUnsavedStatus ? false : isUnsaved();
    
    bool hasDirtyProperty = false;
    
    if (!isNew) {
      final _DormProxyPropertyInfo dirtyProperty = _scan._proxies.firstWhere(
          (_DormProxyPropertyInfo entry) => (
              !entry.proxy.isSilent &&
              !entry.proxy.isTransient &&
              (entry.proxy._value != entry.proxy._defaultValue) &&
              ((ignoredProperties == null) || !ignoredProperties.contains(entry.info.property)) &&
              (
                !(entry.proxy._value is Iterable) &&
                !(entry.proxy._defaultValue is Iterable)  
              )
          ),
          orElse: () => null
      );
      
      hasDirtyProperty = (dirtyProperty != null);
    }
    
    return (isNew || hasDirtyProperty);
  }
  
  Map<String, dynamic> getDirtyStates({bool ignoresUnsavedStatus: false, Iterable<String> ignoredProperties}) {
    final Map<String, dynamic> DS = <String, dynamic>{};
    
    if (!isMutable) return DS;
    
    final bool isNew = ignoresUnsavedStatus ? false : isUnsaved();
    
    if (!isNew) {
      _scan._proxies.where(
          (_DormProxyPropertyInfo entry) => (
              !entry.proxy.isSilent &&
              !entry.proxy.isTransient &&
              (entry.proxy._value != entry.proxy._defaultValue) &&
              ((ignoredProperties == null) || !ignoredProperties.contains(entry.info.property)) &&
              (
                !(entry.proxy._value is Iterable) &&
                !(entry.proxy._defaultValue is Iterable)  
              )
          )
      ).forEach(
        (_DormProxyPropertyInfo entry) => DS[entry.info.property] = Entity._serializerWorkaround.outgoing(entry.proxy.value)
      );
    }
    
    return DS;
  }
  
  /**
   * Converts raw [Map] data into an [Entity], including the full cyclic chain.
   * 
   * The [Serializer] is used to perform special conversions if needed, i.e. to create a [DateTime] from an [int]
   * value which contains the millisecondsSinceEpoch value.
   * 
   * The [OnConflictFunction] will take care of discrepantions (if any exist) should the [Entity] have
   * already been loaded and/or modified prior to reloading it.
   */
  void readExternal(Map<String, dynamic> data, Serializer serializer, OnConflictFunction onConflict) {
    _isPointer = (data[SerializationType.POINTER] != null);
    
    final Iterable<_DormProxyPropertyInfo> proxies = _isPointer ? _scan._identityProxies : _scan._proxies;
    final int len = proxies.length;
    _DormProxyPropertyInfo E;
    
    for (int i=0; i<len; i++) {
      E = proxies.elementAt(i);
      
      final DormProxy proxy = E.proxy..hasDelta = true;
      final dynamic entryValue = data[E.info.property];
       
      proxy._fromRaw(
         (proxy.isLazy) ? null :
         (entryValue is Map) ? serializer.convertIn(Entity, FACTORY.spawnSingle(entryValue, serializer, onConflict, proxy:proxy, forType: E.info.typeStatic)) :
         (entryValue is Iterable) ? serializer.convertIn(E.info.type, FACTORY.spawn(entryValue, serializer, onConflict, proxy:proxy, forType: E.info.typeStatic)) :
         (entryValue != null) ? serializer.convertIn(E.info.type, entryValue) : null
      );
    }
  }
  
  void fastSetPropertyValue(String property, dynamic entryValue, Serializer serializer) => 
      _scan._proxyMap[property]._proxy._fromRaw(serializer.convertIn(entryValue.runtimeType, entryValue));
  
  /**
   * Converts the [Entity] into raw [Map] data, including the full cyclic chain.
   * 
   * The [Serializer] is used to perform special conversions if needed, i.e. to create an [int] value from a [DateTime] value
   * value which contains the millisecondsSinceEpoch value.
   */
  void writeExternal(Map<String, dynamic> data, Serializer serializer) => _writeExternalImpl(data, serializer);
  
  /**
   * Converts the [Entity] into a JSON representation.
   */
  String toJson({Map<String, Map<String, dynamic>> convertedEntities}) {
    final Map<String, dynamic> jsonMap = <String, dynamic>{};
    
    writeExternal(jsonMap, _serializerWorkaround);
    
    return JSON.encode(jsonMap);
  }
  
  /**
   * Converts the [Entity] into a String representation.
   */
  String toString() {
    final List<String> result = <String>[];
    
    _scan._proxies.forEach(
      (_DormProxyPropertyInfo entry) {
        if (entry.proxy.isLabelField) result.add(entry.proxy._value.toString());
      }
    );
    
    return result.join(', ');
  }
  
  //---------------------------------
  //
  // Private methods
  //
  //---------------------------------
  
  void _scheduleDirtyCheck(dynamic newValue) {
    if (_observableDirtyCheckTimeout == null) {
      _observableDirtyCheckTimeout = new Timer(
        new Duration(milliseconds: 30),
        () {
          _observableDirtyCheckTimeout = null;
          
          Observable.dirtyCheck();
        }
      );
    }
  }
  
  Entity _duplicateImpl(List<_ClonedEntityEntry> clonedEntities, List<Symbol> ignoredSymbols) {
    if (_scan._root.isMutableEntity) {
      final _ClonedEntityEntry clonedEntity = clonedEntities.firstWhere(
         (_ClonedEntityEntry cloneEntry) => (cloneEntry.original == this),
         orElse: () => null
      );
      
      if (clonedEntity != null) return clonedEntity.clone;
      
      final Entity clone = _scan._root._entityCtor();
      
      clonedEntities.add(new _ClonedEntityEntry(this, clone));
      
      clone._scan._proxies.forEach(
          (_DormProxyPropertyInfo entry) {
            if (
              (ignoredSymbols == null) ||
              !ignoredSymbols.contains(entry.info.propertySymbol)
            ) {
              if (entry.info.metadataCache.isId) entry.proxy.setInitialValue(entry.proxy._insertValue);
              else {
                dynamic value = this[entry.proxy._propertySymbol];
                
                if (value is ObservableList) {
                  final ObservableList listCast = value as ObservableList;
                  final ObservableList listClone = new ObservableList();
                  
                  listCast.forEach(
                    (dynamic listEntry) {
                      if (listEntry is Entity) {
                        final Entity listEntryCast = listEntry as Entity;
                        
                        listClone.add(listEntryCast._duplicateImpl(clonedEntities, ignoredSymbols));
                      } else listClone.add(listEntry);
                    }
                  );
                  
                  entry.proxy.setInitialValue(_serializerWorkaround.convertIn(entry.info.type, listClone));
                } else if (value is Entity) {
                  final Entity entryCast = value as Entity;
                  
                  entry.proxy.setInitialValue(entryCast._duplicateImpl(clonedEntities, ignoredSymbols));
                } else entry.proxy.setInitialValue(value);
              }
            }
          }
      );
      
      return clone;
    }
    
    return this;
  }
  
  int compare(Entity otherEntity) {
    if (this == otherEntity) return 0;
    
    final int len = _scan._identityProxies.length;
    _DormProxyPropertyInfo entryA, entryB;
    int i;
    
    for (i=0; i<len; i++) {
      entryA = _scan._identityProxies[i];
      entryB = otherEntity._scan._identityProxies[i];
      
      if (entryA.proxy.value < entryB.proxy.value) return -1;
      else if (entryA.proxy.value > entryB.proxy.value) return 1;
    }
    
    return 0;
  }
  
  bool identical(Entity E) => (E._scan == _scan);
  
  void _writeExternalImpl(Map<String, dynamic> data, Serializer serializer) {
    data[SerializationType.ENTITY_TYPE] = _scan._root.refClassName;
    data[SerializationType.UID] = _uid;
    
    serializer.convertedEntities[this] = data;
    
    final int len = _scan._proxies.length;
    
    for (int i=0; i<len; _writeExternalProxy(_scan._proxies[i++], data, serializer));
  }
  
  void _writeExternalProxy(_DormProxyPropertyInfo entry, Map<String, dynamic> data, Serializer serializer) {
    Map<String, dynamic> pointerMap;
    List<dynamic> subList, dataList;
    Entity S;
          
    if (entry.proxy._value is Entity) {
      if (!entry.info.metadataCache.isTransient) {
        S = entry.proxy._value;

        if (serializer.convertedEntities[S] != null) {
          pointerMap = <String, dynamic>{
            SerializationType.POINTER: S._uid,
            SerializationType.ENTITY_TYPE: S._scan._root.refClassName
          };

          S._scan._identityProxies.forEach(
              (_DormProxyPropertyInfo I) =>
          pointerMap[I.info.property] = I.proxy._value
          );

          data[entry.info.property] = pointerMap;
        } else {
          data[entry.info.property] = <String, dynamic>{};

          S._writeExternalImpl(data[entry.info.property], serializer);
        }
      }
    } else if (entry.proxy._value is List) {
      if (!entry.info.metadataCache.isTransient) {
        subList = serializer.convertOut(entry.info.type, entry.proxy._value);
        dataList = <dynamic>[];

        subList.forEach(
            (dynamic listEntry) {
          if (listEntry is Entity) {
            if (serializer.convertedEntities[listEntry] != null) {
              pointerMap = <String, dynamic>{
                SerializationType.POINTER: listEntry._uid,
                SerializationType.ENTITY_TYPE: listEntry._scan._root.refClassName
              };

              listEntry._scan._identityProxies.forEach(
                  (_DormProxyPropertyInfo I) => pointerMap[I.info.property] = I.proxy._value
              );

              dataList.add(pointerMap);
            } else {
              dataList.add(<String, dynamic>{});

              listEntry._writeExternalImpl(dataList.last, serializer);
            }
          } else dataList.add(serializer.convertOut(entry.info.type, entry.proxy._value));
        }
        );

        data[entry.info.property] = dataList;
      }
    } else if (!entry.info.metadataCache.isTransient) data[entry.info.property] = serializer.convertOut(entry.info.type, entry.proxy._value);
   }
}

class _ClonedEntityEntry {
  
  final Entity original;
  final Entity clone;
  
  _ClonedEntityEntry(this.original, this.clone);
  
}