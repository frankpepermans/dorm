part of dorm;

abstract class Serializer<T> {
  
  List<Map<String, dynamic>> incoming(T data);
  
  T outgoing(dynamic data);
  
}