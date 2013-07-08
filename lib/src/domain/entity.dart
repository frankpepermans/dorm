part of dorm;

abstract class Entity extends ObservableBase implements IExternalizable {
  
  EntityManager _manager;
  Map _source;
  EntityScan _scan;
  bool _isPointer;
  
  //-----------------------------------
  //
  // Operator overloads
  //
  //-----------------------------------
  
  dynamic operator [](String propertyName) {
    _ProxyEntry entry;
    int i = _scan._proxies.length;
    
    while (i > 0) {
      entry = _scan._proxies[--i];
      
      if (entry.property == propertyName) {
        return entry.proxy.value;
      }
    }
    
    return null;
  }
  
  void operator []=(String propertyName, dynamic propertyValue) {
    _ProxyEntry entry;
    int i = _scan._proxies.length;
    
    while (i > 0) {
      entry = _scan._proxies[--i];
      
      if (entry.property == propertyName) {
        entry.proxy.value = notifyPropertyChange(
            entry.proxy.propertySymbol, 
            entry.proxy.value,
            propertyValue
        );
      }
    }
    
    return null;
  }
  
  //-----------------------------------
  //
  // Constructor
  //
  //-----------------------------------
  
  Entity() {
    _manager = new EntityManager().._initialize(this);
  }
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  bool isDirty() {
    _ProxyEntry entry;
    int i = _scan._proxies.length;
    
    while (i > 0) {
      entry = _scan._proxies[--i];
      
      if (entry.proxy._value != entry.proxy._defaultValue) {
        return true;
      }
    }
    
    return false;
  }
  
  void readExternal(Map<String, dynamic> data, OnConflictFunction onConflict) {
    EntityFactory<Entity> factory = new EntityFactory(onConflict);
    _ProxyEntry entry;
    int i = _scan._proxies.length;
    dynamic entryValue;
    
    _isPointer = (data.containsKey(SerializationType.POINTER));
    
    while (i > 0) {
      entry = _scan._proxies[--i];
      
      entryValue = data[entry.property];
      
      if (entryValue is Map) {
        entry.proxy._initialValue = factory.spawn(
            <Map<String, dynamic>>[entryValue]
        ).first;
      } else if (entryValue is Iterable) {
        entry.proxy._initialValue = entry.proxy.owner = factory.spawn(entryValue);
      } else {
        entry.proxy._initialValue = entryValue;
      }
    }
  }
  
  void writeExternal(Map<String, dynamic> data) {
    _writeExternalImpl(data, null);
  }
  
  String toJson({Map<String, Map<String, dynamic>> convertedEntities}) {
    Map<String, dynamic> jsonMap = new Map<String, dynamic>();
    
    writeExternal(jsonMap);
    
    return stringify(jsonMap);
  }
  
  String toString() {
    List<String> result = <String>[];
    
    _scan._proxies.forEach(
      (_ProxyEntry entry) {
        if (entry.proxy.isLabelField) {
          result.add(entry.proxy.value.toString());
        }
      }
    );
    
    return result.join(', ');
  }
  
  //---------------------------------
  //
  // Library protected methods
  //
  //---------------------------------
  
  void _writeExternalImpl(Map<String, dynamic> data, Map<String, Map<String, dynamic>> convertedEntities) {
    data[SerializationType.ENTITY_TYPE] = _scan.qualifiedLocalName;
    
    if (convertedEntities == null) {
      convertedEntities = new Map<String, Map<String, dynamic>>();
    }
    
    convertedEntities[_scan.key] = data;
    
    _scan._proxies.forEach(
      (_ProxyEntry entry) {
        if (entry.proxy.value is Entity) {
          Entity subEntity = entry.proxy.value;
          
          if (convertedEntities.containsKey(subEntity._scan.key)) {
            Map<String, dynamic> pointerMap = new Map<String, dynamic>();
            
            pointerMap[SerializationType.POINTER] = true;
            
            subEntity._scan._proxies.forEach(
              (_ProxyEntry subEntry) {
                if (subEntry.proxy.isId) {
                  pointerMap[entry.property] = subEntry.proxy.value;
                }
              }
            );
            
            data[entry.property] = pointerMap;
          } else {
            data[entry.property] = new Map<String, dynamic>();
            
            subEntity._writeExternalImpl(data[entry.property], convertedEntities);
          }
        } else if (entry.proxy.value is List) {
          Iterable<dynamic> convertedList = <dynamic>[]; 
          
          entry.proxy.value.forEach(
            (dynamic listEntry) {
              if (listEntry is Entity) {
                Map<String, dynamic> listEntryMap = new Map<String, dynamic>();
                
                listEntry._writeExternalImpl(listEntryMap, convertedEntities);
                
                convertedList.add(listEntryMap);
              } else {
                convertedList.add(listEntry);
              }
            }
          );
          
          data[entry.property] = convertedList;
        } else {
          data[entry.property] = entry.proxy.value;
        }
      }
    );
  }
  
}