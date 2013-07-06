part of dorm;

class SerializerJson<T> implements Serializer {
  
  SerializerJson._contruct();
  
  factory SerializerJson() => new SerializerJson<String>._contruct();
  
  List<Map<String, dynamic>> incoming(T data) => parse(data);
  
  String outgoing(dynamic data) {
    if (
        (data is List) ||
        (data is Map)
    ) {
      return stringify(data);
    }
    
    return data.toString();
  }
  
}