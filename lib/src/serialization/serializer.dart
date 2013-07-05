part of dorm;

abstract class Serializer<T> {
  
  dynamic incoming(T data);
  
  T outgoing(dynamic data);
  
}