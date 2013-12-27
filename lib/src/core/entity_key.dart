part of dorm;

class EntityKeyChain {
  
  //---------------------------------
  //
  // Static methods
  //
  //---------------------------------
  
  static final EntityKeyChain rootKeyChain = new EntityKeyChain();
  
  static Entity getFirstSibling(EntityScan forScan, {bool allowPointers: true}) {
    EntityScan result = forScan._keyChain.entityScans.firstWhere(
      (EntityScan scan) => (
          (scan.entity != forScan.entity) && 
          (allowPointers || !scan.entity._isPointer)
      ),
      orElse: () => null
    );
    
    return (result != null) ? result.entity : null;
  }
  
  static bool areSameKeySignature(EntityScan scanA, EntityScan scanB) => scanA._keyChain.entityScans.contains(scanB);
  
  //---------------------------------
  //
  // Private properties
  //
  //---------------------------------
  
  final Map<Symbol, Map<dynamic, EntityKeyChain>> _map = new Map<Symbol, Map<dynamic, EntityKeyChain>>();
  
  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  final List<EntityScan> entityScans = <EntityScan>[];
  
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
  
  EntityKeyChain _setKeyValue(Symbol key, dynamic value) {
    EntityKeyChain returnValue;
    Map<dynamic, EntityKeyChain> mainKey = _map[key];
    
    if (mainKey == null) {
      returnValue = new EntityKeyChain();
      
      mainKey = <dynamic, EntityKeyChain>{value: returnValue};
      
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
    Map<dynamic, EntityKeyChain> mainKey = _map[key];
    
    if (mainKey == null) _map[key] = mainKey = <dynamic, EntityKeyChain>{value: new EntityKeyChain()};
    else if (mainKey[value] == null) mainKey[value] = new EntityKeyChain();
  }
}