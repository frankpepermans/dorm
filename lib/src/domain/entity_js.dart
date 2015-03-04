part of dorm;

abstract class EntityJs extends Entity {
  
  static void DO_SCAN([String R, Function C]) {}
  
  void writeExternalJs(JsObject data, Serializer serializer) => _writeExternalJsImpl(data, serializer);
  
  JsObject toJsObject() {
    final List<String> path = refClassName.split('.');
    JsObject currentContext = context;
    
    path.forEach(
      (String segment) => currentContext = currentContext[segment]   
    );
    
    final JsObject jsObj = new JsObject(currentContext);
    
    writeExternalJs(jsObj, Entity._serializerWorkaround);
    
    return jsObj;
  }
  
  void _writeExternalJsImpl(JsObject data, Serializer serializer) {
    data[SerializationType.ENTITY_TYPE] = _scan._root.refClassName;
    data[SerializationType.UID] = _uid;
    
    serializer.convertedEntities[this] = data;
    
    final int len = _scan._proxies.length;
    
    for (int i=0; i<len; _writeExternalJsProxy(_scan._proxies[i++], data, serializer));
  }
  
  void _writeExternalJsProxy(_DormProxyPropertyInfo entry, JsObject data, Serializer serializer) {
    JsObject pointerObj, dataList;
    List<dynamic> subList;
    EntityJs S;
    
    if (entry.proxy._value is EntityJs) {
      S = entry.proxy._value;
      
      pointerObj = serializer.convertedEntities[S];
      
      if (pointerObj != null) data[entry.info.property] = pointerObj;
      else data[entry.info.property] = S.toJsObject();
    } else if (entry.proxy._value is List) {
      subList = serializer.convertOut(entry.info.type, entry.proxy._value);
      dataList = new JsObject(context['Array']);
      
      subList.forEach(
          (dynamic listEntry) {
            if (listEntry is EntityJs) {
              pointerObj = serializer.convertedEntities[listEntry];
              
              if (pointerObj != null) dataList.callMethod('push', <JsObject>[pointerObj]);
              else dataList.callMethod('push', <JsObject>[listEntry.toJsObject()]);
            } else dataList.callMethod('push', <JsObject>[serializer.convertOut(entry.info.type, entry.proxy._value)]);
          }
        );
        
        data[entry.info.property] = dataList;
      } else data[entry.info.property] = serializer.convertOut(entry.info.type, entry.proxy._value);
   }
  
}