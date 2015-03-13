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
    final List<T> resultList = <T>[];
    
    list.forEach(
      (U P) => resultList.add(_toEntityJs(P))
    );
    
    return resultList;
  }
  
  U outgoing(dynamic data) {
    final List<U> L = <U>[];
    
    Entity._serializerWorkaround = this;
    
    convertedEntities = new HashMap<T, U>.identity();
    
    if (data is List) data.forEach(
      (T entity) => L.add(entity.toJsObject())
    );
    else if (data is T) L.add(data.toJsObject());
    else if (data is U) L.add(data);
    
    return new JsObject(context['Array'], L);
  }
  
  dynamic convertIn(Type forType, dynamic inValue) {
    final _InternalConvertor convertor = _convertors[forType];
    
    return (convertor == null) ? inValue : convertor.incoming(inValue);
  }
  
  U convertOut(Type forType, dynamic outValue) {
    final _InternalConvertor convertor = _convertors[forType];
    
    return (convertor == null) ? outValue : convertor.outgoing(outValue);
  }
  
  EntityJs fetchEntity(U entityJs) {
    final String refClassName = entityJs['refClassName'];
    final EntityRootScan scan = Entity.ASSEMBLER._entityScans[refClassName];
    
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
  
  EntityJs _internalFetch(EntityRootScan entityScan, U entityJs) {
      final int len = entityScan._rootProxies.length;
      EntityKeyChain nextKey = entityScan._rootKeyChain;
      _DormPropertyInfo entry;
      
      for (int i=0; i<len; i++) {
        entry = entityScan._rootProxies[i++];
        
        if (entry.metadataCache.isId) nextKey = nextKey._setKeyValue(entry.propertySymbol, entityJs[entry.property]);
      }
      
      return (nextKey.entityScans.isNotEmpty) ? nextKey.entityScans.first.entity : null;
    }
  
  T _toEntityJs(U entityJs) {
    if (entityJs == null) return null;
    
    EntityRootScan entityScan = Entity.ASSEMBLER._entityScans[entityJs['refClassName']];
    
    T entity = _internalFetch(entityScan, entityJs);
    
    if (entity != null) return entity;
    
    entity = fetchEntity(entityJs);
    
    entity._scan._proxies.forEach(
      (_DormProxyPropertyInfo I) {
      dynamic entryJs = entityJs[I.info.property];
        
        if (entryJs is JsArray) {
          List<T> list = <T>[];
          
          entryJs.forEach(
            (U listEntryJs) => list.add(_toEntityJs(listEntryJs))  
          );
          
          entity[I.info.propertySymbol] = convertIn(I.info.type, list);
        }
        else if (entryJs is JsObject) entity[I.info.propertySymbol] = _toEntityJs(entryJs);
        else {
          final dynamic value = entityJs[I.info.property];
          
          if (value != null && value.runtimeType != I.info.type && !I.info.metadataCache.isLazy)
            throw new ArgumentError('Error setting property "${I.info.property}" to value "${entityJs[I.info.property]}", expecting type ${I.info.type} instead.'); 
          
          entity[I.info.propertySymbol] = convertIn(I.info.type, entityJs[I.info.property]);
        }
      }
    );
    
    return entity;
  }
}