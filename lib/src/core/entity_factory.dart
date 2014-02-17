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
  
  EntityFactory._internal();
  
  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------
  
  static final EntityFactory _factory = new EntityFactory._internal();

  factory EntityFactory() => _factory;
  
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
    
    if (proxy == null) _assembler._flushProxies();
    
    rawData.forEach(
        (Map<String, dynamic> rawData) => results.add(spawnSingle(rawData, serializer, onConflict, proxy: proxy))
    );
    
    return results;
  }
  
  T spawnSingle(Map<String, dynamic> rawData, Serializer serializer, OnConflictFunction onConflict, {DormProxy proxy}) {
      final T entity = _assembler._assemble(rawData, proxy, serializer, onConflict);
      
      if (proxy == null) _assembler._flushProxies();
      
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