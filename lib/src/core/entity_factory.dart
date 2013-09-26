part of dorm;

class EntityFactory<T extends Entity> {
  
  //---------------------------------
  //
  // Protected properties
  //
  //---------------------------------
  
  final EntityAssembler _assembler = new EntityAssembler();
  
  //---------------------------------
  //
  // Singleton Constructor
  //
  //---------------------------------
  
  const EntityFactory._construct();
  
  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------
  
  static EntityFactory _instance;

  factory EntityFactory() {
    if (_instance == null) _instance = new EntityFactory._construct();

    return _instance;
  }
  
  //---------------------------------
  //
  // Public methods
  //
  //---------------------------------
  
  ObservableList<T> spawn(Iterable<Map<String, dynamic>> rawData, Serializer serializer, OnConflictFunction onConflict, {DormProxy proxy}) {
    ObservableList<T> results = new ObservableList<T>();
    final Function spawner = _assembler._assemble;
    final Function include = results.add;
    
    rawData.forEach(
        (Map<String, dynamic> rawDataEntry) => include(spawner(rawDataEntry, proxy, serializer, onConflict))
    );
    
    return results;
  }
  
  T spawnSingle(Map<String, dynamic> rawData, Serializer serializer, OnConflictFunction onConflict, {DormProxy proxy}) =>
    _assembler._assemble(rawData, proxy, serializer, onConflict);
}