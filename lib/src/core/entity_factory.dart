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
    Map<String, dynamic> rawDataEntry;
    int i = rawData.length;
    
    while (i > 0) {
      rawDataEntry = rawData[--i];
      
      results.add(
          _manager._spawn(rawDataEntry, _onConflict)
      );
    }
    
    return results;
  }
  
}