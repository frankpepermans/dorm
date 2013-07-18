part of dorm;

abstract class Serializer<T> {
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  List<Map<String, dynamic>> incoming(T data);
  String outgoing(dynamic data);
  
}