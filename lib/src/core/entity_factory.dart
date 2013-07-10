part of dorm;

class EntityFactory<T> {
  
  //---------------------------------
  //
  // Protected properties
  //
  //---------------------------------
  
  EntityManager _manager;
  final OnConflictFunction _onConflict;
  
  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------
  
  EntityFactory(this._onConflict) {
    _manager = new EntityManager();
  }
  
  //---------------------------------
  //
  // Public methods
  //
  //---------------------------------
  
  List<T> spawn(List<Map<String, dynamic>> rawData) {
    List<T> results = <T>[];
    Function spawner = _manager._spawn;
    int i = rawData.length;
    
    while (i > 0) {
      results.add(
          spawner(rawData[--i], _onConflict)
      );
    }
    
    return results;
  }
  
}