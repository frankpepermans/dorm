part of dorm;

abstract class Serializer<T> {
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  List<Map<String, dynamic>> incoming(T data);
  String outgoing(dynamic data);
  
  void addRule(Type forType, dynamic incoming(dynamic value), dynamic outgoing(dynamic value));
  void removeRule(Type forType);
  
  dynamic convertIn(Type forType, dynamic inValue);
  dynamic convertOut(Type forType, dynamic outValue);
  
}

abstract class SerializerMixin<T> implements Serializer {
  
  //-----------------------------------
  //
  // Private properties
  //
  //-----------------------------------
  
  Map<Type, _InternalConvertor> _convertors = new Map<Type, _InternalConvertor>();
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  List<Map<String, dynamic>> incoming(T data) => data;
  String outgoing(dynamic data) => data;
  
  void addRule(Type forType, dynamic incoming(dynamic value), dynamic outgoing(dynamic value)) {
    _convertors[forType] = new _InternalConvertor(incoming, outgoing);
  }
  
  void removeRule(Type forType) {
    _convertors.remove(forType);
  }
  
  dynamic convertIn(Type forType, dynamic inValue) => inValue;
  dynamic convertOut(Type forType, dynamic outValue) => outValue;
  
}

class _InternalConvertor {
  
  final Function incoming;
  final Function outgoing;
  
  _InternalConvertor(this.incoming, this.outgoing);
  
}