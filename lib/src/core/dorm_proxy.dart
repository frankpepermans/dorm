part of dorm;

class DormProxy<T> {
  
  //-----------------------------------
  //
  // Private properties
  //
  //-----------------------------------

  T _defaultValue;
  T _value;
  
  set _initialValue(T value) {
    _defaultValue = value;
    _value = value;
  }
  
  //-----------------------------------
  //
  // Public properties
  //
  //-----------------------------------
  
  //-----------------------------------
  // value
  //-----------------------------------
  
  T get value => _value;
  set value(T newValue) => _value = newValue;
  
  String property;
  Symbol propertySymbol;
  List<dynamic> owner;
  bool isId = false;
  bool isTransient = false;
  bool isMutable = true;
  bool isNullable = true;
  bool isLabelField = false;
  
  //-----------------------------------
  //
  // Operator overloads
  //
  //-----------------------------------
  
  T operator ~() => _value;
  
  //-----------------------------------
  //
  // Constructor
  //
  //-----------------------------------
  
  DormProxy();
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
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