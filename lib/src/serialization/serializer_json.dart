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
  
  List<Map<String, dynamic>> incoming(T data) => JSON.decode(data);
  
  String outgoing(dynamic data) {
    Entity.serializerWorkaround = this;
    
    if (
        (data is List) ||
        (data is Map)
    ) {
      return JSON.encode(data);
    }
    
    return data.toString();
  }
  
  dynamic convertIn(Type forType, dynamic inValue) {
    _InternalConvertor convertor = _convertors[forType];
    
    return (convertor == null) ? inValue : convertor.incoming(inValue);
  }
  
  dynamic convertOut(Type forType, dynamic outValue) {
    _InternalConvertor convertor = _convertors[forType];
    
    return (convertor == null) ? outValue : convertor.outgoing(outValue);
  }
  
}