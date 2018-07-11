part of dorm;

class SerializerJson<T> extends SerializerBase<T> {
  @override
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

  factory SerializerJson({bool asDetached: false}) =>
      new SerializerJson<T>._contruct(asDetached);

  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------

  @override
  Iterable<Map<String, dynamic>> incoming(T data) =>
      (json.decode(data as String) as List<dynamic>).map((dynamic entry) =>
          new Map<String, dynamic>.from(entry as Map<dynamic, dynamic>));

  @override
  T outgoing(dynamic data) {
    Entity._serializerWorkaround = this;

    convertedEntities = new HashMap<Entity, Map<String, dynamic>>.identity();

    //if (data is Map) _convertMap(data);
    //else if (data is Iterable) _convertList(data);

    if ((data is List) || (data is Map)) return json.encode(data) as T;

    return data.toString() as T;
  }

  @override
  dynamic convertIn(Type forType, dynamic inValue) {
    final _InternalConvertor convertor = _convertors[forType];

    return (convertor == null) ? inValue : convertor.incoming(inValue);
  }

  @override
  dynamic convertOut(Type forType, dynamic outValue) {
    final _InternalConvertor convertor = _convertors[forType];

    return (convertor == null) ? outValue : convertor.outgoing(outValue);
  }
}
