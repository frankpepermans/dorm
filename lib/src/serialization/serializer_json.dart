part of dorm;

class SerializerJson<T extends Entity, U extends Map<String, dynamic>> extends SerializerBase {
  
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
  
  Iterable<Map<String, dynamic>> incoming(String data) => JSON.decode(data);
  
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
}