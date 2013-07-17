part of dorm;

class EntityKey {
  
  Map<int, Map<dynamic, EntityKey>> _map = new Map<int, Map<dynamic, EntityKey>>();
  
  List<EntityScan> entityScans = <EntityScan>[];
  
  EntityKey();
  
  void operator []= (int key, dynamic value) {
    if (_map[key] == null) {
      _map[key] = new Map<dynamic, EntityKey>();
    }
    
    if (_map[key][value] == null) {
      _map[key][value] = new EntityKey();
    }
  }
  
  EntityKey operator [] (List otherKey) => _map[otherKey[0]][otherKey[1]];
  
  Entity getExistingEntity(Entity forEntity) {
    Iterable<EntityScan> result = getExistingEntityScans(forEntity).where(
      (EntityScan scan) => (scan.entity != forEntity)    
    );
    
    return (result.length > 0) ? result.first.entity : null;
  }
  
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