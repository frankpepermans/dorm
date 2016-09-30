part of dorm;

class EntityFactory<T extends Entity> {
  
  //---------------------------------
  //
  // Protected properties
  //
  //---------------------------------
  
  final EntityAssembler _assembler = new EntityAssembler();
  final List<EntityPostProcessor> _postProcessors = <EntityPostProcessor>[];
  final List<EntityLazyHandler> _lazyHandlers = <EntityLazyHandler>[];
  
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
  
  static final EntityFactory<Entity> _factory = new EntityFactory<Entity>._internal();

  factory EntityFactory() => _factory as EntityFactory<T>;
  
  //---------------------------------
  //
  // Public methods
  //
  //---------------------------------
  
  void addPostProcessor(EntityPostProcessor postProcessor) => _postProcessors.add(postProcessor);
  
  void removePostProcessor(EntityPostProcessor postProcessor) => _postProcessors.removeWhere(
    (EntityPostProcessor tmpPostProcessor) => (tmpPostProcessor == postProcessor)
  );
  
  void addLazyHandler(EntityLazyHandler lazyHandler) => _lazyHandlers.add(lazyHandler);
  
  void removeLazyHandler(EntityLazyHandler lazyHandler) => _lazyHandlers.removeWhere(
    (EntityLazyHandler tmpLazyHandler) => (tmpLazyHandler == lazyHandler)
  );

  List<dynamic> spawn(Iterable<Map<String, dynamic>> rawData, Serializer<dynamic, Map<String, dynamic>> serializer, OnConflictFunction onConflict, {DormProxy<dynamic> proxy, String forType}) {
    final List<dynamic> results = <dynamic>[];
    final int len = rawData.length;
    
    if (proxy != null) proxy._resultLen = len;
    
    for (int i=0; i<len; i++) results.add(spawnSingle(rawData.elementAt(i), serializer, onConflict, proxy: proxy, forType: forType));
    
    return results;
  }
  
  T spawnSingle(Map<String, dynamic> rawData, Serializer<dynamic, Map<String, dynamic>> serializer, OnConflictFunction onConflict, {DormProxy<dynamic> proxy, String forType}) {
    final T entity = _assembler._assemble(rawData, proxy, serializer, onConflict, forType) as T;
    final int len = _postProcessors.length;
    
    if (entity != null && !entity._isPointer) for (int i=0; i<len; _postProcessors.elementAt(i++).handler(entity)) {}
    
    return entity;
  }
}

class EntityPostProcessor {
  
  final PostProcessorMethod handler;
  
  const EntityPostProcessor(this.handler);
  
}

class EntityLazyHandler {
  
  final Symbol propertySymbol;
  final LazyLoaderMethod handler;
  
  const EntityLazyHandler(this.propertySymbol, this.handler);
  
}