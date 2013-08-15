part of dorm;

class EntityFactory<T> {
  
  //---------------------------------
  //
  // Protected properties
  //
  //---------------------------------
  
  final EntityAssembler _assembler = new EntityAssembler();
  final OnConflictFunction _onConflict;
  
  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------
  
  EntityFactory(this._onConflict);
  
  //---------------------------------
  //
  // Public methods
  //
  //---------------------------------
  
  ObservableList<T> spawn(Iterable<Map<String, dynamic>> rawData, Serializer serializer, {DormProxy proxy}) {
    ObservableList<T> results = new ObservableList<T>();
    final Function spawner = _assembler._assemble;
    
    rawData.forEach(
        (Map<String, dynamic> rawDataEntry) => results.add(spawner(rawDataEntry, proxy, serializer, _onConflict))
    );
    
    return results;
  }
  
  T spawnSingle(Map<String, dynamic> rawData, Serializer serializer, {DormProxy proxy}) =>
    _assembler._assemble(rawData, proxy, serializer, _onConflict);
}