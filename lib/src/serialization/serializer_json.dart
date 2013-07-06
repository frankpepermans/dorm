part of dorm;

class SerializerJson<T> implements Serializer {
  
  SerializerJson._contruct();
  
  factory SerializerJson() => new SerializerJson<String>._contruct();
  
  dynamic incoming(T data) => parse(data);
  
  T outgoing(dynamic data) {
    if (
        (data is List) ||
        (data is Map)
    ) {
      return stringify(data);
    }
    
    return data.toString();
  }
  
}