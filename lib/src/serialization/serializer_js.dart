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
  
  EntityJs newEntity(String refClassName) {
    final EntityRootScan scan = Entity.ASSEMBLER._entityScans[refClassName];
    final EntityJs spawnee = scan._entityCtor();
    
    spawnee.setUnsaved(recursively: true);
    
    spawnee._scan.buildKey();
    
    return spawnee;
  }
  
  EntityJs fetchEntity(U entityJs) {
    final String refClassName = entityJs['refClassName'];
    
    if (refClassName == null) throw new ArgumentError('no refClassName name found where it was expected');
    
    final EntityRootScan entityScan = Entity.ASSEMBLER._entityScans[refClassName];
    final int len = entityScan._rootProxies.length;
    EntityKeyChain nextKey = entityScan._rootKeyChain;
    _DormPropertyInfo entry;
    
    for (int i=0; i<len; i++) {
      entry = entityScan._rootProxies[i++];
      
      if (entry.metadataCache.isId) nextKey = nextKey._setKeyValue(entry.propertySymbol, entityJs[entry.property]);
    }
    
    if (nextKey.entityScans.isNotEmpty) {
      final int jsUid = entityJs['__uuid__'];
      final EntityScan scan = nextKey.entityScans.firstWhere(
        (EntityScan ES) => ES.entity.uid == jsUid,
        orElse: () => null
      );
      
      if (scan != null) return scan.entity;
    }
    
    return newEntity(refClassName);
  }
  
  //-----------------------------------
  //
  // Private methods
  //
  //-----------------------------------
  
  T _toEntityJs(U entityJs) {
    if (entityJs == null) return null;
    
    final T entity = fetchEntity(entityJs);
    
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