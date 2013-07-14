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
  
  ObservableList<T> spawn(Iterable<Map<String, dynamic>> rawData) {
    ObservableList<T> results = new ObservableList<T>();
    Function spawner = _assembler._assemble;
    int index = 0;
    
    rawData.forEach(
        (Map<String, dynamic> rawDataEntry) => results.add(spawner(rawDataEntry, _onConflict))
    );
    
    return results;
  }
  
}