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
  
  Iterable<T> spawn(Iterable<Map<String, dynamic>> rawData, Serializer serializer, OnConflictFunction onConflict, {DormProxy proxy}) {
    EntityList<T> results = new EntityList<T>(
        rawData,
        (Map<String, dynamic> rawDataEntry) {
          Entity entity = _assembler._assemble(rawDataEntry, proxy, serializer, onConflict);
          
          _postProcessors.forEach(
            (EntityPostProcessor postProcessor) => postProcessor.handler(entity)
          );
          
          return entity;
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

typedef Entity _ElementPredicate<T extends Entity>(Map<String, dynamic> element);

class EntityList<T extends Entity> extends ObservableList<T> {
  final Iterable<T> _iterable;
  final _ElementPredicate _f;

  EntityList(this._iterable, _ElementPredicate this._f) {
    addAll(_iterable);
  }
  
  @reflectable T operator [](int index) {
    dynamic listEntry = super[index];
    
    if (listEntry is Map) this[index] = listEntry = _f(super[index]);
    
    return listEntry;
  }
}