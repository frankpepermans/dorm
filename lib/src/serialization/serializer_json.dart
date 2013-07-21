part of dorm;

class SerializerJson<T> extends SerializerBase {
  
  //-----------------------------------
  //
  // Constructor
  //
  //-----------------------------------
  
  SerializerJson._contruct();
  
  //-----------------------------------
  //
  // Factories
  //
  //-----------------------------------
  
  factory SerializerJson() => new SerializerJson<String>._contruct();
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  List<Map<String, dynamic>> incoming(T data) => parse(data);
  
  String outgoing(dynamic data) {
    Entity.serializerWorkaround = this;
    
    if (
        (data is List) ||
        (data is Map)
    ) {
      return stringify(data);
    }
    
    return data.toString();
  }
  
  dynamic convertIn(Type forType, dynamic inValue) {
    _InternalConvertor convertor = _convertors[forType];
    
    if (convertor == null) return inValue;
    
    return _convertors[forType].incoming(inValue);
  }
  
  dynamic convertOut(Type forType, dynamic outValue) {
    _InternalConvertor convertor = _convertors[forType];
    
    if (convertor == null) return outValue;
    
    return _convertors[forType].outgoing(outValue);
  }
  
}