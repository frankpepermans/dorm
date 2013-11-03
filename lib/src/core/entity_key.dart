part of dorm;

class EntityKey {
  
  //---------------------------------
  //
  // Private properties
  //
  //---------------------------------
  
  final Map<Symbol, Map<dynamic, EntityKey>> _map = new Map<Symbol, Map<dynamic, EntityKey>>();
  
  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  final List<EntityScan> entityScans = new List<EntityScan>();
  
  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------
  
  EntityKey();
  
  //---------------------------------
  //
  // Operator overloads
  //
  //---------------------------------
  
  void operator []= (Symbol key, dynamic value) => _setKeyValueNoReturn(key, value);
  
  EntityKey operator [] (List otherKey) => _map[otherKey[0]][otherKey[1]];
  
  //---------------------------------
  //
  // Public methods
  //
  //---------------------------------
  
  Entity getFirstSibling(Entity forEntity, {bool allowPointers: true}) {
    EntityScan result = forEntity._scan._keyCollection.firstWhere(
      (EntityScan scan) => (
          (scan.entity != forEntity) && 
          (allowPointers || !scan.entity._isPointer)
      ),
      orElse: () => null
    );
    
    return (result != null) ? result.entity : null;
  }
  
  bool areSameKeySignature(Entity entity, Entity compareEntity) => entity._scan._keyCollection.contains(compareEntity._scan);
  
  bool remove(Entity entity) => entity._scan._keyCollection.remove(entity._scan);
  
  Iterable<EntityScan> getSiblings(Entity forEntity) => forEntity._scan._keyCollection.where(
      (EntityScan scan) => (scan.entity != forEntity)    
  );
  
  List<EntityScan> getExistingEntityScans(Entity forEntity) => forEntity._scan._keyCollection;
  
  //---------------------------------
  //
  // Private methods
  //
  //---------------------------------
  
  EntityKey _setKeyValue(Symbol key, dynamic value) {
    EntityKey returnValue;
    Map<dynamic, EntityKey> mainKey = _map[key];
    
    if (mainKey == null) {
      mainKey = new Map<dynamic, EntityKey>();
      
      returnValue = new EntityKey();
      
      mainKey[value] = returnValue;
      
      _map[key] = mainKey;
      
      return returnValue;
    } else if (mainKey[value] == null) {
      returnValue = new EntityKey();
      
      mainKey[value] = returnValue;
      
      return returnValue;
    }
    
    return mainKey[value];
  }
  
  void _setKeyValueNoReturn(Symbol key, dynamic value) {
    Map<dynamic, EntityKey> mainKey = _map[key];
    
    if (mainKey == null) {
      mainKey = <dynamic, EntityKey>{value: new EntityKey()};
      
      _map[key] = mainKey;
    } else if (mainKey[value] == null) {
      mainKey[value] = new EntityKey();
    }
  }
}