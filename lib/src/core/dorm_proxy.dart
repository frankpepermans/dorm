part of dorm;

class DormProxy<T> {

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
  
  T operator ~() => _value;
  
  DormProxy();
  
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