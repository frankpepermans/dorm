part of dorm;

class SerializerJson extends SerializerBase {
  
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
  
  factory SerializerJson() => new SerializerJson._contruct();
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  List<Map<String, dynamic>> incoming(String data) => JSON.decode(data);
  
  String outgoing(dynamic data) {
    Entity._serializerWorkaround = this;
    
    if (
        (data is List) ||
        (data is Map)
    ) return JSON.encode(data);
    
    return data.toString();
  }
  
  dynamic convertIn(Type forType, dynamic inValue) {
    _InternalConvertor convertor = _convertors.firstWhere(
      (_InternalConvertor tmpConvertor) => (tmpConvertor.forType == forType),
      orElse: () => null
    );
    
    return (convertor == null) ? inValue : convertor.incoming(inValue);
  }
  
  dynamic convertOut(Type forType, dynamic outValue) {
    _InternalConvertor convertor = _convertors.firstWhere(
        (_InternalConvertor tmpConvertor) => (tmpConvertor.forType == forType),
        orElse: () => null
    );
    
    return (convertor == null) ? outValue : convertor.outgoing(outValue);
  }
}