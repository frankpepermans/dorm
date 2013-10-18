part of dorm;

class Entity extends ObservableBase implements Externalizable {
  
  static final EntityAssembler ASSEMBLER = new EntityAssembler();
  
  // ugly workaround because toJSON can not take in any arguments
  static Serializer _serializerWorkaround;
  
  // TO_DO: remove these
  int encReference;
  int encType;
  
  //-----------------------------------
  //
  // Private properties
  //
  //-----------------------------------
  
  List<DormProxy> _proxies = <DormProxy>[];
  Map _source;
  EntityScan _scan;
  bool _isPointer;
  int get _uid => hashCode;
  
  //-----------------------------------
  //
  // Public properties
  //
  //-----------------------------------
  
  //-----------------------------------
  // isMutable
  //-----------------------------------
  
  bool get isMutable => _scan.isMutableEntity;
  
  //-----------------------------------
  // refClassName
  //-----------------------------------
  
  String get refClassName => null;
  
  //-----------------------------------
  //
  // Operator overloads
  //
  //-----------------------------------
  
  dynamic operator [](String propertyName) {
    _ProxyEntry result = _scan._proxies.firstWhere(
      (_ProxyEntry entry) => (entry.property == propertyName),
      orElse: () => null
    );
    
    return (result != null) ? result.proxy._value : null;
  }
  
  void operator []=(String propertyName, dynamic propertyValue) {
    _ProxyEntry result = _scan._proxies.firstWhere(
        (_ProxyEntry entry) => (entry.property == propertyName),
        orElse: () => null
    );
    
    if (result != null) {
      result.proxy._value = notifyPropertyChange(
          result.proxy.propertySymbol, 
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
  
  String getPropertyNameFromSymbol(Symbol propertySymbol) {
    _ProxyEntry match = _scan._proxies.firstWhere(
        (_ProxyEntry entry) => (entry.propertySymbol == propertySymbol),
        orElse: () => null
    );
    
    return (match != null) ? match.property : null;
  }
  
  bool setDefaultPropertyValue(String propertyName, dynamic propertyValue) {
    _ProxyEntry result = _scan._proxies.firstWhere(
        (_ProxyEntry entry) => (entry.property == propertyName),
        orElse: () => null
    );
    
    if (result != null) {
      result.proxy._defaultValue = propertyValue;
      result.proxy._value = propertyValue;
      
      return true;
    }
    
    return false;
  }
  
  List<Entity> getEntityTree({List<Entity> traversedEntities}) {
    List<Entity> tree = (traversedEntities != null) ? traversedEntities : <Entity>[];
    
    tree.add(this);
    
    _scan._proxies.forEach(
        (_ProxyEntry entry) {
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
  
  List<String> getIdentityFields() {
    List<String> result = <String>[];
    
    _scan._identityProxies.forEach(
      (_ProxyEntry entry) => result.add(entry.property) 
    );
    
    return result;
  }
  
  Map<String, dynamic> getInsertValues() {
    Map<String, dynamic> result = <String, dynamic>{};
    
    _scan._identityProxies.forEach(
      (_ProxyEntry entry) => result[entry.property] = entry.proxy._insertValue 
    );
    
    return result;
  }
  
  bool isUnsaved() {
    _ProxyEntry nonInsertIdentityProxy = _scan._identityProxies.firstWhere(
        (_ProxyEntry entry) => (entry.proxy._value != entry.proxy._insertValue),
        orElse: () => null
    );
    
    return (nonInsertIdentityProxy == null);
  }
  
  void setUnsaved() {
    _scan._identityProxies.forEach(
        (_ProxyEntry entry) => entry.proxy._value = notifyPropertyChange(
            entry.proxy.propertySymbol, 
            entry.proxy._value,
            entry.proxy._insertValue
        )
    );
  }
  
  List<String> getPropertyList() {
    List<String> result = <String>[];
    
    _scan._proxies.forEach(
      (_ProxyEntry entry) => result.add(entry.property)
    );
    
    return result;
  }
  
  MetadataExternalized getMetadata(String propertyName) {
    _ProxyEntry result = _scan._proxies.firstWhere(
        (_ProxyEntry entry) => (entry.property == propertyName),
        orElse: () => null
    );
    
    return (result != null) ? result.metadataCache._getMetadataExternal() : null;
  }
  
  Entity duplicate() => _duplicateImpl(<_ClonedEntityEntry>[]);
  
  List<MetadataValidationResult> validate() {
    MetadataValidationResult validationResult;
    List<MetadataValidationResult> validationResultList = <MetadataValidationResult>[];
    
    _scan._proxies.forEach(
        (_ProxyEntry entry) {
          validationResult = entry.proxy.validate(this);
          
          if (validationResult != null) validationResultList.add(validationResult);
        }
    );
    
    return validationResultList;
  }
  
  bool isDirty() => (
      _scan._proxies.firstWhere(
          (_ProxyEntry entry) => (
              (entry.proxy._value != entry.proxy._defaultValue) ||
              (
                  entry.isIdentity && 
                  (entry.proxy._value == entry.proxy._insertValue)
              )
          ),
          orElse: () => null
      ) != null
  );
  
  void readExternal(Map<String, dynamic> data, Serializer serializer, OnConflictFunction onConflict) {
    final EntityFactory<Entity> factory = new EntityFactory();
    
    Iterable<_ProxyEntry> proxies;
    
    _isPointer = data.containsKey(SerializationType.POINTER);
    
    proxies = _isPointer ? _scan._identityProxies : _scan._proxies;
    
    proxies.forEach(
       (_ProxyEntry entry) {
         DormProxy proxy = entry.proxy..hasDelta = true;
         
         dynamic entryValue = data[entry.property];
         
         if (entryValue is Map) {
           proxy.setInitialValue(factory.spawnSingle(entryValue, serializer, onConflict, proxy:proxy));
         } else if (entryValue is Iterable) {
           proxy.owner = factory.spawn(entryValue, serializer, onConflict);
           
           proxy.setInitialValue(proxy.owner);
         } else if (entryValue != null) {
           proxy.setInitialValue(serializer.convertIn(entry.type, entryValue));
         }
       }
    );
  }
  
  void writeExternal(Map<String, dynamic> data, Serializer serializer) => _writeExternalImpl(data, null, serializer);
  
  String toJson({Map<String, Map<String, dynamic>> convertedEntities}) {
    Map<String, dynamic> jsonMap = new Map<String, dynamic>();
    
    writeExternal(jsonMap, _serializerWorkaround);
    
    return JSON.encode(jsonMap);
  }
  
  String toString() {
    List<String> result = <String>[];
    
    _scan._proxies.forEach(
      (_ProxyEntry entry) {
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
  
  Entity _duplicateImpl(List<_ClonedEntityEntry> clonedEntities) {
    if (_scan.isMutableEntity) {
      _ClonedEntityEntry clonedEntity = clonedEntities.firstWhere(
         (_ClonedEntityEntry cloneEntry) => (cloneEntry.original == this),
         orElse: () => null
      );
      
      if (clonedEntity != null) return clonedEntity.clone;
      
      Entity clone = _scan._entityCtor();
      
      clonedEntities.add(new _ClonedEntityEntry(this, clone));
      
      clone._scan._proxies.forEach(
          (_ProxyEntry entry) {
            if (entry.isIdentity) {
              entry.proxy.setInitialValue(entry.proxy._insertValue);
            } else {
              dynamic value = this[entry.proxy.property];
              
              if (value is ObservableList) {
                ObservableList listCast = value as ObservableList;
                ObservableList listClone = new ObservableList();
                
                listCast.forEach(
                  (dynamic listEntry) {
                    if (listEntry is Entity) {
                      Entity listEntryCast = listEntry as Entity;
                      
                      listClone.add(listEntryCast._duplicateImpl(clonedEntities));
                    } else if (listEntry is DateTime) {
                      listClone.add(clone._cloneDateTime(listEntry as DateTime));
                    } else {
                      /*try {
                        listClone.add(listEntry.toClone());
                      } catch (error) {*/
                        listClone.add(listEntry);
                      /*}*/
                    }
                  }
                );
                
                entry.proxy.setInitialValue(listClone);
              } else if (value is Entity) {
                Entity entryCast = value as Entity;
                
                entry.proxy.setInitialValue(entryCast._duplicateImpl(clonedEntities));
              } else if (value is DateTime) {
                entry.proxy.setInitialValue(clone._cloneDateTime(value as DateTime));
              } else {
                /*try {
                  entry.proxy.setInitialValue(value.toClone());
                } catch (error) {*/
                  entry.proxy.setInitialValue(value);
                /*}*/
              }
            }
          }
      );
      
      return clone;
    }
    
    return this;
  }
  
  void _writeExternalImpl(Map<String, dynamic> data, Map<int, Map<String, dynamic>> convertedEntities, Serializer serializer) {
    data[SerializationType.ENTITY_TYPE] = _scan.refClassName;
    data[SerializationType.UID] = _uid;
    
    if (convertedEntities == null) convertedEntities = new Map<int, Map<String, dynamic>>();
    
    convertedEntities[_uid] = data;
    
    _scan._proxies.forEach(
      (_ProxyEntry entry) {
        if (entry.proxy._value is Entity) {
          Entity subEntity = entry.proxy._value;
          
          if (convertedEntities.containsKey(subEntity._uid)) {
            Map<String, dynamic> pointerMap = new Map<String, dynamic>();
            
            pointerMap[SerializationType.POINTER] = subEntity._uid;
            pointerMap[SerializationType.ENTITY_TYPE] = subEntity._scan.refClassName;
            
            subEntity._scan._proxies.forEach(
                (_ProxyEntry subEntry) {
                  if (subEntry.proxy.isId) pointerMap[subEntry.property] = subEntry.proxy._value;
                }
            );
            
            data[entry.property] = pointerMap;
          } else {
            data[entry.property] = new Map<String, dynamic>();
            
            subEntity._writeExternalImpl(data[entry.property], convertedEntities, serializer);
          }
        } else if (entry.proxy._value is List) {
          List<dynamic> subList = entry.proxy._value as List;
          List<dynamic> dataList = <dynamic>[];
          
          subList.forEach(
              (dynamic listEntry) {
                if (listEntry is Entity) {
                  Entity subEntity = listEntry as Entity;
                  Map<String, dynamic> entryData;
                  
                  if (convertedEntities.containsKey(subEntity._uid)) {
                    Map<String, dynamic> pointerMap = new Map<String, dynamic>();
                    
                    pointerMap[SerializationType.POINTER] = subEntity._uid;
                    pointerMap[SerializationType.ENTITY_TYPE] = subEntity._scan.refClassName;
                    
                    subEntity._scan._proxies.forEach(
                        (_ProxyEntry subEntry) {
                          if (subEntry.proxy.isId) pointerMap[subEntry.property] = subEntry.proxy._value;
                        }
                    );
                    
                    dataList.add(pointerMap);
                  } else {
                    entryData = new Map<String, dynamic>();
                    
                    subEntity._writeExternalImpl(entryData, convertedEntities, serializer);
                    
                    dataList.add(entryData);
                  }
                } else {
                  dataList.add(serializer.convertOut(entry.type, entry.proxy._value));
                }
              }
            );
            
            data[entry.property] = dataList;
          } else {
            data[entry.property] = serializer.convertOut(entry.type, entry.proxy._value);
          }
      }
    );
  }
  
  DateTime _cloneDateTime(DateTime value) {
    final DateTime valueClone = new DateTime.fromMillisecondsSinceEpoch(value.millisecondsSinceEpoch, isUtc: value.isUtc);
    
    return valueClone;
  }
}

class _ClonedEntityEntry {
  
  final Entity original;
  final Entity clone;
  
  _ClonedEntityEntry(this.original, this.clone);
  
}