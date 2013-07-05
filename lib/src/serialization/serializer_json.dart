part of dorm;

class SerializerJson<T> implements Serializer {
  
  SerializerJson._contruct();
  
  factory SerializerJson() => new SerializerJson<String>._contruct();
  
  dynamic incoming(T data) => parse(data);
  
  T outgoing(dynamic data) => stringify(data);
  
}