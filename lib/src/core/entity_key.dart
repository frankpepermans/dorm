part of dorm;

class EntityKey {
  
  //---------------------------------
  //
  // Private properties
  //
  //---------------------------------
  
  Map<int, Map<dynamic, EntityKey>> _map = new Map<int, Map<dynamic, EntityKey>>();
  
  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  List<EntityScan> entityScans = <EntityScan>[];
  
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
  
  void operator []= (int key, dynamic value) {
    if (_map[key] == null) _map[key] = new Map<dynamic, EntityKey>();
    
    if (_map[key][value] == null) _map[key][value] = new EntityKey();
  }
  
  EntityKey operator [] (List otherKey) => _map[otherKey[0]][otherKey[1]];
  
  //---------------------------------
  //
  // Public methods
  //
  //---------------------------------
  
  Entity getExistingEntity(Entity forEntity) {
    EntityScan result = getExistingEntityScans(forEntity).firstWhere(
      (EntityScan scan) => (scan.entity != forEntity),
      orElse: () => null
    );
    
    return (result != null) ? result.entity : null; 
  }
  
  bool areSameKeySignature(Entity entity, Entity compareEntity) => getExistingEntityScans(entity).contains(compareEntity._scan);
  
  bool remove(Entity entity) => getExistingEntityScans(entity).remove(entity._scan);
  
  Iterable<EntityScan> getSiblings(Entity forEntity) => getExistingEntityScans(forEntity).where(
      (EntityScan scan) => (scan.entity != forEntity)    
  );
  
  List<EntityScan> getExistingEntityScans(Entity forEntity) {
    EntityKey nextKey;
    List<_ProxyEntry> identityProxies = forEntity._scan._identityProxies;
    int len = identityProxies.length;
    _ProxyEntry entry;
    int i, code;
    dynamic value;
    
    nextKey = EntityAssembler._instance._keyChain;
    
    for (i=0; i<len; i++) {
      entry = identityProxies[i];
      
      code = entry.proxy.propertySymbol.hashCode;
      value = entry.proxy._value;
      
      nextKey[code] = value;
      
      nextKey = nextKey[[code, value]];
    }
    
    return nextKey.entityScans;
  }
}