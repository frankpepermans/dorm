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
  
  Entity getFirstSibling(Entity forEntity) {
    EntityScan result = forEntity._scan._keyCollection.firstWhere(
      (EntityScan scan) => (scan.entity != forEntity),
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
}