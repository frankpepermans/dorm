part of dorm;

class EntityKeyChain {
  
  //---------------------------------
  //
  // Static methods
  //
  //---------------------------------
  
  static final EntityKeyChain rootKeyChain = new EntityKeyChain();
  
  static Entity getFirstSibling(EntityScan forScan, {bool allowPointers: true}) {
    if (forScan._keyChain.entityScans.length == 0) return null;
    
    EntityScan S;
    int i = forScan._keyChain.entityScans.length;
    
    while (i > 0) {
      S = forScan._keyChain.entityScans.elementAt(--i);
      
      if (siblingCheck(S, forScan, allowPointers)) return S.entity;
    }
    
    return null;
  }
  
  static bool siblingCheck(EntityScan scanA, EntityScan scanB, bool allowPointers) => (
    (scanA.entity != scanB.entity) &&
    (allowPointers || !scanA.entity._isPointer)
  );
  
  static bool areSameKeySignature(EntityScan scanA, EntityScan scanB) => (scanA._keyChain == scanB._keyChain);
  
  //---------------------------------
  //
  // Private properties
  //
  //---------------------------------
  
  final HashMap<Symbol, HashMap<dynamic, EntityKeyChain>> _map = new HashMap<Symbol, HashMap<dynamic, EntityKeyChain>>.identity();
  
  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  final HashSet<EntityScan> entityScans = new HashSet<EntityScan>.identity();
  
  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------
  
  EntityKeyChain();
  
  //---------------------------------
  //
  // Operator overloads
  //
  //---------------------------------
  
  void operator []= (Symbol key, dynamic value) => _setKeyValueNoReturn(key, value);
  
  EntityKeyChain operator [] (List otherKey) => _map[otherKey[0]][otherKey[1]];
  
  //---------------------------------
  //
  // Private methods
  //
  //---------------------------------
  
  bool evictEntity(Entity entity) => entityScans.remove(entity._scan);
  
  EntityKeyChain _setKeyValue(Symbol key, dynamic value) {
    EntityKeyChain returnValue;
    HashMap<dynamic, EntityKeyChain> mainKey = _map[key];
    
    if (mainKey == null) {
      returnValue = new EntityKeyChain();
      
      mainKey = new HashMap<dynamic, EntityKeyChain>.identity();
      
      mainKey[value] = returnValue;
      
      _map[key] = mainKey;
      
      return returnValue;
    } else if (mainKey[value] == null) {
      returnValue = new EntityKeyChain();
      
      mainKey[value] = returnValue;
      
      return returnValue;
    }
    
    return mainKey[value];
  }
  
  void _setKeyValueNoReturn(Symbol key, dynamic value) {
    HashMap<dynamic, EntityKeyChain> mainKey = _map[key];
    
    if (mainKey == null) {
      _map[key] = mainKey = new HashMap<dynamic, EntityKeyChain>.identity();
      
      mainKey[value] = new EntityKeyChain();
    } else if (mainKey[value] == null) mainKey[value] = new EntityKeyChain();
  }
}