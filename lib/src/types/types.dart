part of dorm;

class Proxy<T> {

  T _defaultValue;
  T _value;
  
  set _initialValue(T value) {
    _defaultValue = value;
    _value = value;
  }
  
  T get value => _value;
  set value(T newValue) {
    if (!isMutable) {
      throw new DormError('$property is immutable');
    }
    
    if (
      !isNullable &&
      (newValue == null)
    ) {
      throw new DormError('$property is not nullable');
    }
    
    if (newValue != _value) {
      _value = newValue;
      
      isDirty = (newValue != _defaultValue);
    }
  }
  
  String property;
  Symbol propertySymbol;
  List<Entity> owner;
  bool isId = false;
  bool isTransient = false;
  bool isMutable = true;
  bool isDirty = false;
  bool isNullable = true;
  bool isLabelField = false;
  
  T operator ~() => value;
  
  Proxy._construct(T v, bool m) {
    _defaultValue = v;
    
    value = v;
    
    isMutable = m;
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