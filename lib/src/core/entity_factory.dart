part of dorm;

class EntityFactory<T> {
  
  //---------------------------------
  //
  // Protected properties
  //
  //---------------------------------
  
  EntityAssembler _assembler;
  final OnConflictFunction _onConflict;
  
  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------
  
  EntityFactory(this._onConflict) {
    _assembler = new EntityAssembler();
  }
  
  //---------------------------------
  //
  // Public methods
  //
  //---------------------------------
  
  Iterable<T> spawn(Iterable<Map<String, dynamic>> rawData) {
    List<T> results = new List<T>(rawData.length);
    Function spawner = _assembler._assemble;
    int index = 0;
    
    rawData.forEach(
        (Map<String, dynamic> rawDataEntry) => results[index++] = spawner(rawDataEntry, _onConflict) 
    );
    
    return results;
  }
  
}