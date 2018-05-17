part of dorm;

abstract class Serializer<T, U extends Map<String, dynamic>> {
  bool asDetached;

  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------

  Iterable<U> incoming(T data);
  T outgoing(dynamic data);

  Map<T, U> get convertedEntities;

  Serializer<dynamic, Map<String, dynamic>> addRule<T, S>(
      Type forType, S incoming(T value), T outgoing(S value));
  _InternalConvertor removeRule(Type forType);

  dynamic convertIn(Type forType, dynamic inValue);
  dynamic convertOut(Type forType, dynamic outValue);
}

abstract class SerializerMixin<T>
    implements Serializer<T, Map<String, dynamic>> {
  //-----------------------------------
  //
  // Private properties
  //
  //-----------------------------------

  final Map<Type, _InternalConvertor> _convertors =
      <Type, _InternalConvertor>{};

  @override
  Map<T, Map<String, dynamic>> convertedEntities;

  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------

  @override
  Serializer<T, Map<String, dynamic>> addRule<T, S>(
      Type forType, S incoming(T value), T outgoing(S value)) {
    _convertors[forType] = new _InternalConvertor(forType, incoming, outgoing);

    return this as Serializer<T, Map<String, dynamic>>;
  }

  @override
  _InternalConvertor removeRule(Type forType) => _convertors.remove(forType);

  @override
  dynamic convertIn(Type forType, dynamic inValue) => inValue;
  @override
  dynamic convertOut(Type forType, dynamic outValue) => outValue;
}

class _InternalConvertor {
  final Type forType;
  final Function incoming;
  final Function outgoing;

  const _InternalConvertor(this.forType, this.incoming, this.outgoing);
}
