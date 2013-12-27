part of dorm;

class Entity extends Observable implements Externalizable {
  
  static final EntityAssembler ASSEMBLER = EntityAssembler._instance;
  static final EntityFactory FACTORY = EntityFactory._instance;
  static Serializer _serializerWorkaround;
  static Timer _observableDirtyCheckTimeout;
  
  //-----------------------------------
  //
  // Private properties
  //
  //-----------------------------------
  
  EntityScan _scan;
  bool _isPointer;
  
  //-----------------------------------
  //
  // Public properties
  //
  //-----------------------------------
  
  //-----------------------------------
  // isMutable
  //-----------------------------------
  
  bool get isMutable => _scan._root.isMutableEntity;
  
  //-----------------------------------
  // refClassName
  //-----------------------------------
  
  String get refClassName => null;
  
  //-----------------------------------
  //
  // Operator overloads
  //
  //-----------------------------------
  
  dynamic operator [](Symbol propertyField) {
    _DormProxyListEntry result = _scan._proxies.firstWhere(
      (_DormProxyListEntry entry) => (entry.propertySymbol == propertyField),
      orElse: () => null
    );
    
    return (result != null) ? result.proxy._value : null;
  }
  
  void operator []=(Symbol propertyField, dynamic propertyValue) {
    _DormProxyListEntry result = _scan._proxies.firstWhere(
        (_DormProxyListEntry entry) => (entry.propertySymbol == propertyField),
        orElse: () => null
    );
    
    if (result != null) {
      result.proxy._value = notifyPropertyChange(
          result.proxy._propertySymbol, 
          result.proxy._value,
          propertyValue
      );
    }
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
  dynamic notifyPropertyChange(Symbol field, Object oldValue, Object newValue) => _scheduleDirtyCheck(
    super.notifyPropertyChange(field, oldValue, newValue)    
  );
  
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
    _DormProxyListEntry result = _scan._proxies.firstWhere(
        (_DormProxyListEntry entry) => (entry.propertySymbol == propertyField),
        orElse: () => null
    );
    
    if (result != null) {
      result.proxy._defaultValue = propertyValue;
      result.proxy._value = propertyValue;
      
      return true;
    }
    
    return false;
  }
  
  /**
   * Updates all [Entity] properties' default values to the current values.
   * 
   * Similar to [setDefaultPropertyValue], except this method will run on all fields.
   */
  void setCurrentStatusIsDefaultStatus() {
    _scan._proxies.forEach(
        (_DormProxyListEntry entry) => entry.proxy._defaultValue = entry.proxy._value
    );
  }
  
  /**
   * Resets all [Entity] properties so that all fields are again equal to the default values.
   * 
   * Use this feature to revert any changes to the [Entity]'s fields.
   */
  void revertChanges() {
    _scan._proxies.forEach(
        (_DormProxyListEntry entry) => this[entry.proxy._propertySymbol] = entry.proxy._defaultValue
    );
  }
  
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
    List<Entity> tree = (traversedEntities != null) ? traversedEntities : <Entity>[];
    
    tree.add(this);
    
    _scan._proxies.forEach(
        (_DormProxyListEntry entry) {
          if (entry.proxy._value is Entity) {
            Entity entity = entry.proxy._value as Entity;
            
            if (!tree.contains(entity)) {
              List<Entity> subTree = entity.getEntityTree(traversedEntities: tree);
            }
          } else if (entry.proxy._value is ObservableList) {
            ObservableList subList = entry.proxy._value as ObservableList;
          
            subList.forEach(
              (dynamic subListEntry) {
                if (subListEntry is Entity) {
                  Entity subListEntity = subListEntry as Entity;
                  
                  if (!tree.contains(subListEntity)) {
                    List<Entity> subTree = subListEntity.getEntityTree(traversedEntities: tree);
                  }
                }
              }
            );
          }
        }
    );
    
    return tree;
  }
  
  /**
   * Unrolls all [Entity] identity fields to a one-dimensional [List]
   */
  List<Symbol> getIdentityFields() {
    List<Symbol> result = <Symbol>[];
    
    _scan._identityProxies.forEach(
      (_DormProxyListEntry entry) => result.add(entry.propertySymbol) 
    );
    
    return result;
  }
  
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
    Map<Symbol, dynamic> result = <Symbol, dynamic>{};
    
    _scan._identityProxies.forEach(
      (_DormProxyListEntry entry) => result[entry.propertySymbol] = entry.proxy._insertValue 
    );
    
    return result;
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
    _DormProxyListEntry nonInsertIdentityProxy = _scan._identityProxies.firstWhere(
        (_DormProxyListEntry entry) => (entry.proxy._value != entry.proxy._insertValue),
        orElse: () => null
    );
    
    return (nonInsertIdentityProxy == null);
  }
  
  /**
   * Resets all identity fields to their corresponding insert values so that this [Entity]
   * 
   * will be treated as a new [Entity] with an insert statement rather than an update statement.
   * 
   * Use this to quickly create a duplicate of one [Entity].
   */
  void setUnsaved() {
    _scan._identityProxies.forEach(
        (_DormProxyListEntry entry) => entry.proxy._value = notifyPropertyChange(
            entry.proxy._propertySymbol, 
            entry.proxy._value,
            entry.proxy._insertValue
        )
    );
  }
  
  /**
   * Returns a [List] containing [Symbol]s of all properties belonging to this [Entity].
   */
  List<Symbol> getPropertyList() {
    List<Symbol> result = <Symbol>[];
    
    _scan._proxies.forEach(
      (_DormProxyListEntry entry) => result.add(entry.propertySymbol)
    );
    
    return result;
  }
  
  /**
   * Returns the metadata attached to a specific property.
   * 
   * The metadata can be combination of the following :
   * [Id], [Lazy], [NotNullable], [DefaultValue], [Transient], [Immutable], [LabelField] or [Annotation]
   */
  MetadataExternalized getMetadata(Symbol propertyField) {
    _DormProxyListEntry result = _scan._proxies.firstWhere(
        (_DormProxyListEntry entry) => (entry.propertySymbol == propertyField),
        orElse: () => null
    );
    
    return (result != null) ? result.metadataCache._getMetadataExternal() : null;
  }
  
  /**
   * Duplicates the [Entity] and any recusrive entities to a new [Entity].
   */
  Entity duplicate() => _duplicateImpl(<_ClonedEntityEntry>[]);
  
  /**
   * Validates the values of this [Entity] using the associated metadata.
   * 
   * Returns a [List] of [MetadataValidationResult].
   */
  List<MetadataValidationResult> validate() {
    MetadataValidationResult validationResult;
    List<MetadataValidationResult> validationResultList = <MetadataValidationResult>[];
    
    _scan._proxies.forEach(
        (_DormProxyListEntry entry) {
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
  bool isDirty() => (
      isMutable &&
      (
          _scan._proxies.firstWhere(
              (_DormProxyListEntry entry) => (
                  (entry.proxy._value != entry.proxy._defaultValue) ||
                  (
                      entry.metadataCache.isId && 
                      (entry.proxy._value == entry.proxy._insertValue)
                  )
              ),
              orElse: () => null
          ) != null
      )    
  );
  
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
    
    final Iterable<_DormProxyListEntry> proxies = _isPointer ? _scan._identityProxies : _scan._proxies;
    
    proxies.forEach(
       (_DormProxyListEntry entry) {
         DormProxy proxy = entry.proxy..hasDelta = true;
         
         dynamic entryValue = data[entry.property];
         dynamic value;
         
         if (entryValue is Map) value = FACTORY.spawnSingle(entryValue, serializer, onConflict, proxy:proxy);
         else if (entryValue is Iterable) {
           proxy.owner = serializer.convertIn(entry.type, FACTORY.spawn(entryValue, serializer, onConflict));
           
           value = proxy.owner;
         } else if (entryValue != null) value = serializer.convertIn(entry.type, entryValue);
         
         try {
           proxy.setInitialValue(value);
         } catch (error) {
           throw new DormError('Could not set the value of ${proxy._propertySymbol} using the value ${value}, perhaps you need to add a rule to the serializer?');
         }
       }
    );
  }
  
  /**
   * Converts the [Entity] into raw [Map] data, including the full cyclic chain.
   * 
   * The [Serializer] is used to perform special conversions if needed, i.e. to create an [int] value from a [DateTime] value
   * value which contains the millisecondsSinceEpoch value.
   */
  void writeExternal(Map<String, dynamic> data, Serializer serializer) => _writeExternalImpl(data, null, serializer);
  
  /**
   * Converts the [Entity] into a JSON representation.
   */
  String toJson({Map<String, Map<String, dynamic>> convertedEntities}) {
    Map<String, dynamic> jsonMap = new Map<String, dynamic>();
    
    writeExternal(jsonMap, _serializerWorkaround);
    
    return JSON.encode(jsonMap);
  }
  
  /**
   * Converts the [Entity] into a String representation.
   */
  String toString() {
    List<String> result = <String>[];
    
    _scan._proxies.forEach(
      (_DormProxyListEntry entry) {
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
  
  dynamic _scheduleDirtyCheck(dynamic newValue) {
    if (_observableDirtyCheckTimeout == null) {
      _observableDirtyCheckTimeout = new Timer(
        new Duration(milliseconds: 30),
        () {
          _observableDirtyCheckTimeout = null;
          
          Observable.dirtyCheck();
        }
      );
    }
    
    return newValue;
  }
  
  Entity _duplicateImpl(List<_ClonedEntityEntry> clonedEntities) {
    if (_scan._root.isMutableEntity) {
      _ClonedEntityEntry clonedEntity = clonedEntities.firstWhere(
         (_ClonedEntityEntry cloneEntry) => (cloneEntry.original == this),
         orElse: () => null
      );
      
      if (clonedEntity != null) return clonedEntity.clone;
      
      Entity clone = _scan._root._entityCtor();
      
      clonedEntities.add(new _ClonedEntityEntry(this, clone));
      
      clone._scan._proxies.forEach(
          (_DormProxyListEntry entry) {
            if (entry.metadataCache.isId) {
              entry.proxy.setInitialValue(entry.proxy._insertValue);
            } else {
              dynamic value = this[entry.proxy._propertySymbol];
              
              if (value is ObservableList) {
                ObservableList listCast = value as ObservableList;
                ObservableList listClone = new ObservableList();
                
                listCast.forEach(
                  (dynamic listEntry) {
                    if (listEntry is Entity) {
                      Entity listEntryCast = listEntry as Entity;
                      
                      listClone.add(listEntryCast._duplicateImpl(clonedEntities));
                    } else {
                      listClone.add(listEntry);
                    }
                  }
                );
                
                entry.proxy.setInitialValue(listClone);
              } else if (value is Entity) {
                Entity entryCast = value as Entity;
                
                entry.proxy.setInitialValue(entryCast._duplicateImpl(clonedEntities));
              } else {
                entry.proxy.setInitialValue(value);
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
    _DormProxyListEntry entryA, entryB;
    int i;
    
    for (i=0; i<len; i++) {
      entryA = _scan._identityProxies[i];
      entryB = otherEntity._scan._identityProxies[i];
      
      if (entryA.proxy.value < entryB.proxy.value) return -1;
      else if (entryA.proxy.value > entryB.proxy.value) return 1;
    }
    
    return 0;
  }
  
  void _writeExternalImpl(Map<String, dynamic> data, Map<int, Map<String, dynamic>> convertedEntities, Serializer serializer) {
    final int uid = hashCode;
    
    data[SerializationType.ENTITY_TYPE] = _scan._root.refClassName;
    data[SerializationType.UID] = uid;
    
    if (convertedEntities == null) convertedEntities = new Map<int, Map<String, dynamic>>();
    
    convertedEntities[uid] = data;
    
    _scan._proxies.forEach(
      (_DormProxyListEntry entry) {
        if (entry.proxy._value is Entity) {
          Entity subEntity = entry.proxy._value;
          
          if (convertedEntities[subEntity.hashCode] != null) {
            Map<String, dynamic> pointerMap = new Map<String, dynamic>();
            
            pointerMap[SerializationType.POINTER] = subEntity.hashCode;
            pointerMap[SerializationType.ENTITY_TYPE] = subEntity._scan._root.refClassName;
            
            subEntity._scan._proxies.forEach(
                (_DormProxyListEntry subEntry) {
                  if (subEntry.proxy.isId) pointerMap[subEntry.property] = subEntry.proxy._value;
                }
            );
            
            data[entry.property] = pointerMap;
          } else {
            data[entry.property] = new Map<String, dynamic>();
            
            subEntity._writeExternalImpl(data[entry.property], convertedEntities, serializer);
          }
        } else if (entry.proxy._value is List) {
          List<dynamic> subList = serializer.convertOut(entry.type, entry.proxy._value);
          List<dynamic> dataList = <dynamic>[];
          
          subList.forEach(
              (dynamic listEntry) {
                if (listEntry is Entity) {
                  Entity subEntity = listEntry as Entity;
                  Map<String, dynamic> entryData;
                  
                  if (convertedEntities[subEntity.hashCode] != null) {
                    Map<String, dynamic> pointerMap = new Map<String, dynamic>();
                    
                    pointerMap[SerializationType.POINTER] = subEntity.hashCode;
                    pointerMap[SerializationType.ENTITY_TYPE] = subEntity._scan._root.refClassName;
                    
                    subEntity._scan._proxies.forEach(
                        (_DormProxyListEntry subEntry) {
                          if (subEntry.proxy.isId) pointerMap[subEntry.property] = subEntry.proxy._value;
                        }
                    );
                    
                    dataList.add(pointerMap);
                  } else {
                    entryData = new Map<String, dynamic>();
                    
                    subEntity._writeExternalImpl(entryData, convertedEntities, serializer);
                    
                    dataList.add(entryData);
                  }
                } else dataList.add(serializer.convertOut(entry.type, entry.proxy._value));
              }
            );
            
            data[entry.property] = dataList;
          } else data[entry.property] = serializer.convertOut(entry.type, entry.proxy._value);
      }
    );
  }
}

class _ClonedEntityEntry {
  
  final Entity original;
  final Entity clone;
  
  _ClonedEntityEntry(this.original, this.clone);
  
}