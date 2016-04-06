part of dorm;

abstract class Serializer<T extends Entity, U> {

  bool asDetached;
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  Iterable<Map<String, dynamic>> incoming(T data);
  T outgoing(dynamic data);
  
  Map<T, U> get convertedEntities;
  
  Serializer addRule(Type forType, dynamic incoming(dynamic value), dynamic outgoing(dynamic value));
  _InternalConvertor removeRule(Type forType);
  
  dynamic convertIn(Type forType, dynamic inValue);
  dynamic convertOut(Type forType, dynamic outValue);
  
}

abstract class SerializerMixin<T extends Entity, U> implements Serializer {
  
  //-----------------------------------
  //
  // Private properties
  //
  //-----------------------------------
  
  final Map<Type, _InternalConvertor> _convertors = <Type, _InternalConvertor>{};
  
  Map<T, U> convertedEntities;
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  Iterable<Map<String, dynamic>> incoming(T data);
  T outgoing(dynamic data);
  
  Serializer addRule(Type forType, dynamic incoming(dynamic value), dynamic outgoing(dynamic value)) {
    _convertors[forType] = new _InternalConvertor(forType, incoming, outgoing);
    
    return this;
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