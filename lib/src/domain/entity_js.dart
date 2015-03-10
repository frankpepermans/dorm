part of dorm;

abstract class EntityJs extends Entity {
  
  static void DO_SCAN([String R, Function C]) {}
  static HashMap<String, JsObject> _CACHED_CONTEXTS = new HashMap<String, JsObject>.identity();
  
  JsObject interopObj;
  
  JsObject writeExternalJs(JsObject data) => _writeExternalJsImpl(data);
  
  JsObject toJsObject() {
    if (interopObj != null) {
      if (Entity._serializerWorkaround.convertedEntities[this] != null) return interopObj;
      
      return writeExternalJs(interopObj);
    }
    
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
    
    interopObj = Entity._serializerWorkaround.convertedEntities[this] = new JsObject(currentContext);
    
    return writeExternalJs(interopObj);
  }
  
  JsObject _writeExternalJsImpl(JsObject data) {
    final List<dynamic> L = <dynamic>[_uid];
    final int len = _scan._proxies.length;
    
    for (int i=0; i<len; i++) L.add(_writeExternalJsProxy(_scan._proxies[i], data));
    
    data.callMethod('_readExternal', L);
    
    return data;
  }
  
  dynamic _writeExternalJsProxy(_DormProxyPropertyInfo entry, JsObject data) {
    JsObject pointerObj;
    List<dynamic> subList;
    List<JsObject> tempList;
    EntityJs S;
    
    if (entry.proxy._value is EntityJs) {
      S = entry.proxy._value;
      
      pointerObj = S.interopObj;
      
      if (pointerObj != null) return pointerObj;
      else return S.toJsObject();
    } else if (entry.proxy._value is List) {
      subList = Entity._serializerWorkaround.convertOut(entry.info.type, entry.proxy._value);
      tempList = <JsObject>[];
      
      final int len = subList.length;
      dynamic listEntry;
      
      for (int i=0; i<len; i++) {
        listEntry = subList[i];
        
        if (listEntry is EntityJs) {
          pointerObj = listEntry.interopObj;
          
          if (pointerObj != null) tempList.add(pointerObj);
          else tempList.add(listEntry.toJsObject());
        } else tempList.add(Entity._serializerWorkaround.convertOut(entry.info.type, entry.proxy._value));
      }
        
      return new JsObject(context['Array'], tempList);
    } else return Entity._serializerWorkaround.convertOut(entry.info.type, entry.proxy._value);
  }
  
}