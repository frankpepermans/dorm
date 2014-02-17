part of dorm;

class DormProxy<T> {
  
  //-----------------------------------
  //
  // Private properties
  //
  //-----------------------------------
  
  T _insertValue, _defaultValue, _value;
  
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
  set value(T newValue) {
    if (_isValueUpdateRequired(_value, newValue)) _value = newValue;
  }
  
  Future<T> get lazyFuture => _lazyFuture;
  set lazyFuture(Future<T> newValue) => _lazyFuture = newValue;
  
  final String _property;
  final Symbol _propertySymbol;
  
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
  // Constructor
  //
  //-----------------------------------
  
  DormProxy(this._property, this._propertySymbol);
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  MetadataValidationResult validate(Entity entity) {
    if (!entity.isMutable) return new MetadataValidationResult(entity, _property, _propertySymbol, MetadataValidationReason.ENTITY_NOT_MUTABLE);
    
    if (!isMutable) return new MetadataValidationResult(entity, _property, _propertySymbol, MetadataValidationReason.PROPERTY_NOT_MUTABLE);
    
    if (
      !isNullable &&
      (_value == null)
    ) return new MetadataValidationResult(entity, _property, _propertySymbol, MetadataValidationReason.PROPERTY_NOT_NULLABLE);
    
    return null;
  }
  
  void setInsertValue(T value) {
    _insertValue = value;
  }
  
  void setInitialValue(T value) {
    _defaultValue = value;
    _value = value;
  }
  
  //-----------------------------------
  //
  // Private methods
  //
  //-----------------------------------
  
  bool _isValueUpdateRequired(dynamic valueA, dynamic valueB) {
    if (
      (valueA is Comparable) &&
      (valueB is Comparable)
    ) return (valueA.compareTo(valueB) != 0);
    
    return (valueA != valueB);
  }
  
  void _updateWithMetadata(_DormProxyPropertyInfo entry, EntityScan scan) {
    final _PropertyMetadataCache cache = entry.info.metadataCache;
    
    isId = cache.isId;
    isTransient = cache.isTransient;
    isNullable = cache.isNullable;
    isLabelField = cache.isLabelField;
    isMutable = (scan._root.isMutableEntity && cache.isMutable);
    isLazy = cache.isLazy;
    
    setInsertValue(cache.insertValue);
    setInitialValue(cache.initialValue);
  }
}