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
  
  final HashMap<Symbol, HashMap<dynamic, EntityKeyChain>> _map = new HashMap<Symbol, HashMap<dynamic, EntityKeyChain>>.identity();
  
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