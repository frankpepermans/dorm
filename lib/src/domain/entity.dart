part of dorm;

abstract class Entity extends ObservableBase {
  
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
      
      if (entry.proxy.isDirty) {
        return true;
      }
    }
    
    return false;
  }
  
  String toJson({Map<String, Map<String, dynamic>> convertedEntities}) {
    Map<String, dynamic> jsonMap = new Map<String, dynamic>();
    
    jsonMap[SerializationType.ENTITY_TYPE] = _scan.qualifiedLocalName;
    
    if (convertedEntities == null) {
      convertedEntities = new Map<String, Map<String, dynamic>>();
    }
    
    convertedEntities[_scan.key] = jsonMap;
    
    _scan._proxies.forEach(
      (_ProxyEntry entry) {
        if (entry.proxy.value is Entity) {
          Entity subEntity = entry.proxy.value;
          
          if (convertedEntities.containsKey(_scan.key)) {
            Map<String, dynamic> pointerMap = new Map<String, dynamic>();
            
            pointerMap[SerializationType.POINTER] = true;
            
            subEntity._scan._proxies.forEach(
              (_ProxyEntry subEntry) {
                if (subEntry.proxy.isId) {
                  pointerMap[entry.property] = subEntry.proxy.value;
                }
              }
            );
            
            jsonMap[entry.property] = pointerMap;
          } else {
            jsonMap[entry.property] = subEntity.toJson(convertedEntities: convertedEntities);
          }
        } else if (entry.proxy.value is List) {
          List<String> convertedList = <String>[]; 
          
          entry.proxy.value.forEach(
            (dynamic listEntry) {
              if (listEntry is Entity) {
                convertedList.add(listEntry.toJson(convertedEntities: convertedEntities));
              } else {
                convertedList.add(stringify(listEntry));
              }
            }
          );
          
          jsonMap[entry.property] = stringify(convertedList);
        } else {
          jsonMap[entry.property] = entry.proxy.value;
        }
      }
    );
    
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
  
}