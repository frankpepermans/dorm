part of dorm;

class SerializerJs<T extends EntityJs, U extends JsObject> extends SerializerBase {
  
  //-----------------------------------
  //
  // Constructor
  //
  //-----------------------------------
  
  SerializerJs._contruct();
  
  //-----------------------------------
  //
  // Factories
  //
  //-----------------------------------
  
  factory SerializerJs() => new SerializerJs._contruct();
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  Iterable<T> incoming(U data) {
    final List<U> list = data['payload'];
    final Map<U, T> convertedList = <U, T>{};
    final List<T> resultList = <T>[];
    
    list.forEach(
      (U P) => resultList.add(_toEntityJs(P, convertedList))
    );
    
    return resultList;
  }
  
  U outgoing(dynamic data) {
    final JsObject list = new JsObject(context['Array']);
    
    Entity._serializerWorkaround = this;
    
    convertedEntities = new HashMap<T, U>.identity();
    
    if (data is List) data.forEach(
      (T entity) => list.callMethod('push', <U>[entity.toJsObject()])
    );
    else if (data is T) list.callMethod('push', <U>[data.toJsObject()]);
    else if (data is U) list.callMethod('push', <U>[data]);
    
    return list;
  }
  
  dynamic convertIn(Type forType, dynamic inValue) {
    final _InternalConvertor convertor = _convertors[forType];
    
    return (convertor == null) ? inValue : convertor.incoming(inValue);
  }
  
  U convertOut(Type forType, dynamic outValue) {
    final _InternalConvertor convertor = _convertors[forType];
    
    return (convertor == null) ? outValue : convertor.outgoing(outValue);
  }
  
  void _convertMap(Map data, {Map<String, U> convertedEntities: null}) {
    if (convertedEntities == null) convertedEntities = <String, U>{};
    
    data.forEach(
      (K, V) {
        if (V is Map) _convertMap(V, convertedEntities: convertedEntities);
        else if (V is T) data[K] = V.toJson(convertedEntities: convertedEntities);
      }
    );
  }
  
  void _convertList(List data, {Map<String, U> convertedEntities: null}) {
    if (convertedEntities == null) convertedEntities = <String, U>{};
    
    final int len = data.length;
    dynamic entry;
    int i;
    
    for (i=0; i<len; i++) {
      entry = data[i];
      
      if (entry is T) data[i] = entry.toJson(convertedEntities: convertedEntities);
    }
  }
  
  EntityJs fetchEntity(U entityJs) {
    final String refClassName = entityJs['refClassName'];
    final EntityRootScan scan = Entity.ASSEMBLER._entityScans[refClassName];
    dynamic entryJs;
    
    final List<_DormPropertyInfo> identityProxies = scan._rootProxies.where(
      (_DormPropertyInfo I) => I.metadataCache.isId    
    ).toList();
    final int len = identityProxies.length;
    EntityKeyChain nextKey = scan._rootKeyChain;
    _DormPropertyInfo entry;
    dynamic entryValue;
    
    for (int i=0; i<len; i++) {
      entry = identityProxies[i];
      entryValue = entityJs[entry.property];
      
      nextKey = nextKey._setKeyValue(entry.propertySymbol, entryValue);
    }
    
    return (nextKey.entityScans.isNotEmpty) ? nextKey.entityScans.first.entity : newEntity(entityJs);
  }
  
  EntityJs newEntity(U entityJs) {
    final String refClassName = entityJs['refClassName'];
    final EntityRootScan scan = Entity.ASSEMBLER._entityScans[refClassName];
    
    return scan._entityCtor();
  }
  
  //-----------------------------------
  //
  // Private methods
  //
  //-----------------------------------
  
  T _toEntityJs(U entityJs, Map<U, T> convertedList) {
    if (entityJs == null) return null;
    
    T entity = convertedList[entityJs];
    
    if (entity != null) return entity;
    
    entity = fetchEntity(entityJs);
    
    entity._scan._proxies.forEach(
      (_DormProxyPropertyInfo I) {
      dynamic entryJs = entityJs[I.info.property];
        
        if (entryJs is JsArray) {
          List<T> list = <T>[];
          
          entryJs.forEach(
            (U listEntryJs) => list.add(_toEntityJs(listEntryJs, convertedList))  
          );
          
          entity[I.info.propertySymbol] = convertIn(I.info.type, list);
        }
        else if (entryJs is JsObject) entity[I.info.propertySymbol] = _toEntityJs(entryJs, convertedList);
        else {
          try {
            entity[I.info.propertySymbol] = convertIn(I.info.type, entityJs[I.info.property]);
          } catch (error) {
            throw new ArgumentError('Error setting property "${I.info.property}" to value "${entityJs[I.info.property]}", expecting type ${I.info.type} instead.'); 
          }
        }
      }
    );
    
    convertedList[entityJs] = entity;
    
    return entity;
  }
}