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
  
  Iterable<Map<String, dynamic>> incoming(U data) {
    final List<U> list = data['payload'];
    final Map<U, Map<String, dynamic>> convertedList = <U, Map<String, dynamic>>{};
    final List<Map<String, dynamic>> resultList = <Map<String, dynamic>>[];
    
    list.forEach(
      (U P) => resultList.add(_toMap(P, convertedList))
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
  
  dynamic convertIn(Type forType, U inValue) {
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
  
  //-----------------------------------
  //
  // Private methods
  //
  //-----------------------------------
  
  Map<String, dynamic> _toMap(U entityJs, Map<U, Map<String, dynamic>> convertedList) {
    final String refClassName = entityJs['refClassName'];
    final EntityRootScan scan = Entity.ASSEMBLER._entityScans[refClassName];
    Map<String, dynamic> convertedEntry = convertedList[entityJs];
    dynamic entryJs;
    
    if (convertedEntry != null) return convertedEntry;
    
    convertedEntry = <String, dynamic>{};
    
    scan._rootProxies.forEach(
      (_DormPropertyInfo I) {
        entryJs = entityJs[I.property];
        
        if (entryJs is U) convertedEntry[I.property] = _toMap(entryJs, convertedList);
        else if (entryJs is Iterable) {
          List<Map<String, dynamic>> list = <Map<String, dynamic>>[];
          
          entryJs.forEach(
            (U listEntryJs) => list.add(_toMap(listEntryJs, convertedList))  
          );
          
          convertedEntry[I.property] = list;
        }
        else convertedEntry[I.property] = entityJs[I.property];
      }
    );
    
    return convertedEntry;
  }
}