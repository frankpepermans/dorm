part of dorm;

class DormProxy<T> {
  
  //-----------------------------------
  //
  // Private properties
  //
  //-----------------------------------
  
  T _insertValue, _defaultValue, _value;
  int _resultLen = -1;
  
  Function _changeHandler;
  
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
    if (_isValueUpdateRequired(_value, newValue)) {
      _value = newValue;
      
      if (_changeHandler != null) _changeHandler();
    }
  }
  
  final String _property;
  final Symbol _propertySymbol;
  
  bool hasDelta = false;
  bool isId = false;
  bool isTransient = false;
  bool isMutable = true;
  bool isNullable = true;
  bool isLabelField = false;
  bool isSilent = false;
  String transformFrom, transformTo;
  Map<String, dynamic> genericAnnotations;
  
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
    
    if (!isMutable && _value != _defaultValue) return new MetadataValidationResult(entity, _property, _propertySymbol, MetadataValidationReason.PROPERTY_NOT_MUTABLE);
    
    if (
      !isNullable &&
      (_value == null)
    ) return new MetadataValidationResult(entity, _property, _propertySymbol, MetadataValidationReason.PROPERTY_NOT_NULLABLE);
    
    return null;
  }
  
  void setInsertValue(T insertValue) {
    _insertValue = insertValue;
  }
  
  void setInitialValue(T initialValue) {
    _defaultValue = initialValue;
    
    value = initialValue;
  }
  
  void _fromRaw(T initialValue) {
    _defaultValue = _value = initialValue;
          
    if (_changeHandler != null) _changeHandler();
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
  
  void _updateWithMetadata(_DormProxyPropertyInfo<_DormPropertyInfo> entry, EntityScan scan) {
    final _PropertyMetadataCache cache = entry.info.metadataCache;
    
    isId = cache.isId;
    isTransient = cache.isTransient;
    isNullable = cache.isNullable;
    isLabelField = cache.isLabelField;
    isMutable = (scan._root.isMutableEntity && cache.isMutable);
    isSilent = cache.isSilent;
    transformFrom = cache.transformFrom;
    transformTo = cache.transformTo;
    
    genericAnnotations = cache.genericAnnotations;

    try {
      setInsertValue(cache.insertValue as T);
      setInitialValue(cache.initialValue as T);
    } catch (error) {
      print(error.message);
      print(cache.insertValue);
    }
  }
}