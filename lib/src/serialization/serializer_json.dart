part of dorm;

class SerializerJson<T extends Entity, U extends Map<String, dynamic>> extends SerializerBase {

  bool asDetached = false;
  
  //-----------------------------------
  //
  // Constructor
  //
  //-----------------------------------
  
  SerializerJson._contruct(bool asDetached) {
    this.asDetached = asDetached;
  }
  
  //-----------------------------------
  //
  // Factories
  //
  //-----------------------------------
  
  factory SerializerJson({bool asDetached: false}) => new SerializerJson._contruct(asDetached);
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  Iterable<Map<String, dynamic>> incoming(String data) => JSON.decode(data) as Iterable<Map<String, dynamic>>;
  
  String outgoing(dynamic data) {
    Entity._serializerWorkaround = this;
    
    convertedEntities = new HashMap<T, U>.identity();
    
    //if (data is Map) _convertMap(data);
    //else if (data is Iterable) _convertList(data);
    
    if (
        (data is List) ||
        (data is Map)
    ) return JSON.encode(data);
    
    return data.toString();
  }
  
  dynamic convertIn(Type forType, dynamic inValue) {
    final _InternalConvertor convertor = _convertors[forType];
    
    return (convertor == null) ? inValue : convertor.incoming(inValue);
  }
  
  dynamic convertOut(Type forType, dynamic outValue) {
    final _InternalConvertor convertor = _convertors[forType];
    
    return (convertor == null) ? outValue : convertor.outgoing(outValue);
  }
}