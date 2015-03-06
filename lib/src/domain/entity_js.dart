part of dorm;

abstract class EntityJs extends Entity {
  
  static void DO_SCAN([String R, Function C]) {}
  static HashMap<String, JsObject> _CACHED_CONTEXTS = new HashMap<String, JsObject>.identity();
  
  JsObject writeExternalJs(JsObject data, Serializer serializer) => _writeExternalJsImpl(data, serializer);
  
  JsObject toJsObject() {
    final JsObject cachedContext = _CACHED_CONTEXTS[refClassName];
    JsObject currentContext;
    
    if (cachedContext != null) currentContext = cachedContext;
    else {
      currentContext = context;
      
      refClassName.split('.').forEach(
        (String segment) => currentContext = currentContext[segment]   
      );
      
      _CACHED_CONTEXTS[refClassName] = currentContext;
    }
    
    return writeExternalJs(new JsObject(currentContext), Entity._serializerWorkaround);
  }
  
  JsObject _writeExternalJsImpl(JsObject data, Serializer serializer) {
    data[SerializationType.INTEROP_UID] = _uid;
    
    serializer.convertedEntities[this] = data;
    
    final int len = _scan._proxies.length;
    
    for (int i=0; i<len; _writeExternalJsProxy(_scan._proxies[i++], data, serializer));
    
    return data;
  }
  
  void _writeExternalJsProxy(_DormProxyPropertyInfo entry, JsObject data, Serializer serializer) {
    JsObject pointerObj, dataList;
    List<dynamic> subList;
    List<JsObject> tempList;
    EntityJs S;
    
    if (entry.proxy._value is EntityJs) {
      S = entry.proxy._value;
      
      pointerObj = serializer.convertedEntities[S];
      
      if (pointerObj != null) data[entry.info.property] = pointerObj;
      else data[entry.info.property] = S.toJsObject();
    } else if (entry.proxy._value is List) {
      subList = serializer.convertOut(entry.info.type, entry.proxy._value);
      tempList = <JsObject>[];
      
      subList.forEach(
          (dynamic listEntry) {
            if (listEntry is EntityJs) {
              pointerObj = serializer.convertedEntities[listEntry];
              
              if (pointerObj != null) tempList.add(pointerObj);
              else tempList.add(listEntry.toJsObject());
            } else tempList.add(serializer.convertOut(entry.info.type, entry.proxy._value));
          }
        );
        
        data[entry.info.property] = new JsObject(context['Array'], tempList);
      } else data[entry.info.property] = serializer.convertOut(entry.info.type, entry.proxy._value);
   }
  
}