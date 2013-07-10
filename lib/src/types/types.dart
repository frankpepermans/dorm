part of dorm;

class Proxy<T> {

  T _defaultValue;
  T _value;
  
  set _initialValue(T value) {
    _defaultValue = value;
    _value = value;
  }
  
  T get value => _value;
  set value(T newValue) => _value = newValue;
  
  String property;
  Symbol propertySymbol;
  List<Entity> owner;
  bool isId = false;
  bool isTransient = false;
  bool isMutable = true;
  bool isNullable = true;
  bool isLabelField = false;
  
  T operator ~() => value;
  
  Proxy._construct(T v, bool m) {
    _defaultValue = v;
    value = v;
    isMutable = m;
  }
  
  void validate() {
    if (!isMutable) {
      throw new DormError('$property is immutable');
    }
    
    if (
      !isNullable &&
      (_value == null)
    ) {
      throw new DormError('$property is not nullable');
    }
  }
  
}

class LazyReference<T> {
  
  Function _handler;
  bool isImmediateAvailable = false;
  T _internalValue;
  
  LazyReference._construct(Function handler) {
    _handler = handler;
  }
  
  T get immediate {
    if (!isImmediateAvailable) {
      throw new DormError('Reference is not loaded, use future instead');
    }
    
    return _internalValue;
  }
  
  Future<T> get future {
    final Completer completer = new Completer();
    
    if (isImmediateAvailable) {
      Timer.run(
        () => completer.complete(_internalValue) 
      );
    } else {
      // obtain value and complete
      _handler().then(
          (T value) {
            _internalValue = value;
            
            isImmediateAvailable = true;
            
            completer.complete(_internalValue);
          }
      );
    }
    
    return completer.future;
  }
  
}