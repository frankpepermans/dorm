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
  
  Iterable<T> spawn(Iterable<Map<String, dynamic>> rawData) {
    List<T> results = new List<T>(rawData.length);
    Function spawner = _manager._spawn;
    int index = 0;
    
    rawData.forEach(
        (Map<String, dynamic> rawDataEntry) => results[index++] = spawner(rawDataEntry, _onConflict) 
    );
    
    return results;
  }
  
}