part of dorm;

class DormProxy<T> {
  
  //-----------------------------------
  //
  // Private properties
  //
  //-----------------------------------
  
  T _insertValue;
  T _defaultValue;
  T _value;
  Future<T> _lazyFuture;
  
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
  
  Future<T> get lazyFuture => _lazyFuture;
  set lazyFuture(Future<T> newValue) => _lazyFuture = newValue;
  
  final String property;
  
  Symbol propertySymbol;
  ObservableList<dynamic> owner;
  bool hasDelta = false;
  bool isId = false;
  bool isTransient = false;
  bool isMutable = true;
  bool isNullable = true;
  bool isLabelField = false;
  bool isLazy = false;
  
  int dataType = 0;
  
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
  
  DormProxy(this.property);
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  MetadataValidationResult validate(Entity entity) {
    if (!entity.isMutable) return new MetadataValidationResult(entity, property, propertySymbol, MetadataValidationReason.ENTITY_NOT_MUTABLE);
    
    if (!isMutable) return new MetadataValidationResult(entity, property, propertySymbol, MetadataValidationReason.PROPERTY_NOT_MUTABLE);
    
    if (
      !isNullable &&
      (_value == null)
    ) return new MetadataValidationResult(entity, property, propertySymbol, MetadataValidationReason.PROPERTY_NOT_NULLABLE);
    
    return null;
  }
  
  void setInsertValue(T value) {
    _insertValue = value;
  }
  
  void setInitialValue(T value) {
    _defaultValue = value;
    _value = value;
  }
}