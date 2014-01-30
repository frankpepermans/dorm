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
  
  void addPostProcessor(EntityPostProcessor postProcessor) => _postProcessors.add(postProcessor);
  
  void removePostProcessor(EntityPostProcessor postProcessor) => _postProcessors.removeWhere(
      (EntityPostProcessor tmpPostProcessor) => (tmpPostProcessor == postProcessor)
  );
  
  ObservableList<T> spawn(Iterable<Map<String, dynamic>> rawData, Serializer serializer, OnConflictFunction onConflict, {DormProxy proxy}) {
    final ObservableList<T> results = new ObservableList<T>();
    
    rawData.forEach(
        (Map<String, dynamic> rawData) => results.add(spawnSingle(rawData, serializer, onConflict, proxy: proxy))
    );
    
    return results;
  }
  
  T spawnSingle(Map<String, dynamic> rawData, Serializer serializer, OnConflictFunction onConflict, {DormProxy proxy}) {
      final T entity = _assembler._assemble(rawData, proxy, serializer, onConflict);
      
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