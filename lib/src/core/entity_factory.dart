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
  
  ObservableList<T> spawn(Iterable<Map<String, dynamic>> rawData, {DormProxy proxy}) {
    ObservableList<T> results = new ObservableList<T>();
    Function spawner = _assembler._assemble;
    
    rawData.forEach(
        (Map<String, dynamic> rawDataEntry) => results.add(spawner(rawDataEntry, proxy, _onConflict))
    );
    
    return results;
  }
  
}