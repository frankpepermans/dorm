part of dorm;

abstract class Serializer<T> {
  
  List<Map<String, dynamic>> incoming(T data);
  
  String outgoing(dynamic data);
  
}