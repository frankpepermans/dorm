part of dorm;

class EntityFactory<T extends Entity> {
  
  //---------------------------------
  //
  // Protected properties
  //
  //---------------------------------
  
  final EntityAssembler _assembler = new EntityAssembler();
  final List<EntityPostProcessor> _postProcessors = <EntityPostProcessor>[];
  
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
  
  void addPostProcessor(EntityPostProcessor postProcessor) {
    
  }
  
  void removePostProcessor(EntityPostProcessor postProcessor) {
    
  }
  
  ObservableList<T> spawn(Iterable<Map<String, dynamic>> rawData, Serializer serializer, OnConflictFunction onConflict, {DormProxy proxy}) {
    ObservableList<T> results = new ObservableList<T>();
    
    rawData.forEach(
        (Map<String, dynamic> rawDataEntry) {
          Entity entity = _assembler._assemble(rawDataEntry, proxy, serializer, onConflict);
          
          _postProcessors.forEach(
            (EntityPostProcessor postProcessor) => postProcessor.handler(entity)
          );
          
          results.add(entity);
        }
    );
    
    return results;
  }
  
  T spawnSingle(Map<String, dynamic> rawData, Serializer serializer, OnConflictFunction onConflict, {DormProxy proxy}) {
      Entity entity = _assembler._assemble(rawData, proxy, serializer, onConflict);
      
      _postProcessors.forEach(
          (EntityPostProcessor postProcessor) => postProcessor.handler(entity)
      );
      
      return entity;
  }
}

class EntityPostProcessor {
  
  final PostProcessorMethod handler;
  
  const EntityPostProcessor(this.handler);
  
}