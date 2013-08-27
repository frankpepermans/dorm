part of dorm;

class Entity extends ObservableBase implements IExternalizable {
  
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
    
    result.metadataCache._getMetadataExternal();
  }
  
  void validate() {
    List<_ProxyEntry> proxies = _scan._proxies;
    int i = proxies.length;
    
    while (i > 0) {
      proxies[--i].proxy.validate();
    }
  }
  
  bool isDirty() {
    _ProxyEntry entry;
    List<_ProxyEntry> proxies = _scan._proxies;
    int i = proxies.length;
    
    while (i > 0) {
      entry = proxies[--i];
      
      if (entry.proxy._value != entry.proxy._defaultValue) {
        return true;
      }
    }
    
    return false;
  }
  
  void readExternal(Map<String, dynamic> data, Serializer serializer, OnConflictFunction onConflict) {
    EntityFactory<Entity> factory = new EntityFactory(onConflict);
    List<_ProxyEntry> proxies;
    
    _isPointer = data.containsKey(SerializationType.POINTER);
    
    proxies = _isPointer ? _scan._identityProxies : _scan._proxies;
    
    proxies.forEach(
         (_ProxyEntry entry) {
           dynamic entryValue = data[entry.property];
           
           DormProxy proxy = entry.proxy;
           
           if (entryValue is Map) {
             proxy._initialValue = factory.spawnSingle(entryValue, serializer, proxy:proxy);
           } else if (entryValue is Iterable) {
             proxy._initialValue = proxy.owner = new ObservableList.from(factory.spawn(entryValue, serializer));
           } else {
             proxy._initialValue = serializer.convertIn(entry.type, entryValue);
           }
         }
    );
  }
  
  void writeExternal(Map<String, dynamic> data, Serializer serializer) {
    _writeExternalImpl(data, null, serializer);
  }
  
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
  
  void _identityKeyListener(List<ChangeRecord> changes) {
    changes.forEach(
        (ChangeRecord change) {
          if (change is PropertyChangeRecord) {
            _ProxyEntry result = _scan._identityProxies.firstWhere(
                (_ProxyEntry entry) => (entry.proxy.propertySymbol == (change as PropertyChangeRecord).field),
                orElse: () => null
            );
            
            if (
                (result != null) &&
                result.proxy.isId
            ) _scan.buildKey();
          }
        }
    );
  }
  
  void _writeExternalImpl(Map<String, dynamic> data, Map<int, Map<String, dynamic>> convertedEntities, Serializer serializer) {
    data[SerializationType.ENTITY_TYPE] = _scan.refClassName;
    data[SerializationType.UID] = _uid;
    
    if (convertedEntities == null) {
      convertedEntities = new Map<int, Map<String, dynamic>>();
    }
    
    convertedEntities[_uid] = data;
    
    _scan._proxies.forEach(
      (_ProxyEntry entry) {
        if (
            entry.proxy.isId ||
            (entry.proxy._value != entry.proxy._defaultValue)
        ) {
          if (entry.proxy._value is Entity) {
            Entity subEntity = entry.proxy._value;
            
            if (convertedEntities.containsKey(subEntity._uid)) {
              Map<String, dynamic> pointerMap = new Map<String, dynamic>();
              
              pointerMap[SerializationType.POINTER] = subEntity._uid;
              pointerMap[SerializationType.ENTITY_TYPE] = subEntity._scan.refClassName;
              
              subEntity._scan._proxies.forEach(
                  (_ProxyEntry subEntry) {
                    if (subEntry.proxy.isId) {
                      pointerMap[subEntry.property] = subEntry.proxy._value;
                    }
                  }
              );
              
              data[entry.property] = pointerMap;
            } else {
              data[entry.property] = new Map<String, dynamic>();
              
              subEntity._writeExternalImpl(data[entry.property], convertedEntities, serializer);
            }
          } else {
            data[entry.property] = serializer.convertOut(entry.type, entry.proxy._value);
          }
        }
      }
    );
  }
  
}