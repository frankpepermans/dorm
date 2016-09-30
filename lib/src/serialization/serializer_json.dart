part of dorm;

class SerializerJson<T, U extends Map<String, dynamic>> extends SerializerBase {

  @override bool asDetached = false;
  
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
  
  factory SerializerJson({bool asDetached: false}) => new SerializerJson<T, U>._contruct(asDetached);
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  @override Iterable<U> incoming(T data) => JSON.decode(data as String) as Iterable<U>;

  @override T outgoing(dynamic data) {
    Entity._serializerWorkaround = this;
    
    convertedEntities = new HashMap<Entity, U>.identity();
    
    //if (data is Map) _convertMap(data);
    //else if (data is Iterable) _convertList(data);
    
    if (
        (data is List) ||
        (data is Map)
    ) return JSON.encode(data) as T;
    
    return data.toString() as T;
  }

  @override dynamic convertIn(Type forType, dynamic inValue) {
    final _InternalConvertor convertor = _convertors[forType];
    
    return (convertor == null) ? inValue : convertor.incoming(inValue);
  }

  @override dynamic convertOut(Type forType, dynamic outValue) {
    final _InternalConvertor convertor = _convertors[forType];
    
    return (convertor == null) ? outValue : convertor.outgoing(outValue);
  }
}