part of dorm;

class SerializerJson<T> implements Serializer {
  
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
  
  factory SerializerJson() => new SerializerJson<String>._contruct();
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
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