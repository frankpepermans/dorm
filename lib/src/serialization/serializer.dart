part of dorm;

abstract class Serializer<T> {
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  Iterable incoming(T data);
  T outgoing(dynamic data);
  
  Map<Entity, Map<String, dynamic>> get convertedEntities;
  
  void addRule(Type forType, dynamic incoming(dynamic value), dynamic outgoing(dynamic value));
  _InternalConvertor removeRule(Type forType);
  
  dynamic convertIn(Type forType, dynamic inValue);
  dynamic convertOut(Type forType, dynamic outValue);
  
}

abstract class SerializerMixin<T> implements Serializer {
  
  //-----------------------------------
  //
  // Private properties
  //
  //-----------------------------------
  
  final Map<Type, _InternalConvertor> _convertors = <Type, _InternalConvertor>{};
  
  Map<Entity, Map<String, dynamic>> convertedEntities;
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  Iterable incoming(T data);
  T outgoing(dynamic data);
  
  void addRule(Type forType, dynamic incoming(dynamic value), dynamic outgoing(dynamic value)) {
    _convertors[forType] = new _InternalConvertor(forType, incoming, outgoing);
  } 
  
  _InternalConvertor removeRule(Type forType) => _convertors.remove(forType);
  
  dynamic convertIn(Type forType, dynamic inValue) => inValue;
  dynamic convertOut(Type forType, dynamic outValue) => outValue;
  
}

class _InternalConvertor {
  
  final Type forType;
  final Function incoming;
  final Function outgoing;
  
  const _InternalConvertor(this.forType, this.incoming, this.outgoing);
  
}