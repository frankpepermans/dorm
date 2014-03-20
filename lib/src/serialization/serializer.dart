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
  
  List<_InternalConvertor> _convertors = <_InternalConvertor>[];
  Map<Entity, Map<String, dynamic>> convertedEntities;
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  Iterable incoming(T data);
  T outgoing(dynamic data);
  
  void addRule(Type forType, dynamic incoming(dynamic value), dynamic outgoing(dynamic value)) =>
    _convertors.add(new _InternalConvertor(forType, incoming, outgoing));
  
  void removeRule(Type forType) => _convertors.removeWhere(
      (_InternalConvertor convertor) => (convertor.forType == forType)
  );
  
  dynamic convertIn(Type forType, dynamic inValue) => inValue;
  dynamic convertOut(Type forType, dynamic outValue) => outValue;
  
}

class _InternalConvertor {
  
  final Type forType;
  final Function incoming;
  final Function outgoing;
  
  const _InternalConvertor(this.forType, this.incoming, this.outgoing);
  
}