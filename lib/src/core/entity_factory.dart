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
    List<T> results = <T>[];
    
    rawData.forEach(
        (Map<String, dynamic> rawDataEntry) => results.add(
            _manager._spawn(rawDataEntry, _onConflict)
        )  
    );
    
    return results;
  }
  
}