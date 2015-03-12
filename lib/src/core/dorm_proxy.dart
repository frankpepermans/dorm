part of dorm;

class DormProxy<T> {
  
  //-----------------------------------
  //
  // Private properties
  //
  //-----------------------------------
  
  T _insertValue, _defaultValue, _value;
  int _resultLen = -1;
  bool _isLazyLoadingRequired = false, _isLazyLoadingCompleted = false;
  Future<T> _lazyFuture;
  
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
  
  Future<T> get lazyValue {
    if (_isLazyLoadingRequired) {
      _isLazyLoadingRequired = false;
      
      final EntityLazyHandler LH = Entity.FACTORY._lazyHandlers.firstWhere(
        (EntityLazyHandler lazyHandler) => (lazyHandler.propertySymbol == _propertySymbol),
        orElse: () => null
      );
      
      _lazyFuture = LH.handler(_propertySymbol).then(
        (T V) {
          _value = V;
          
          _isLazyLoadingCompleted = true;
        },
        onError: () => throw new DormError('could not fetch lazy value for $_propertySymbol')
      );
      
      return _lazyFuture;
    }
    
    if (!_isLazyLoadingCompleted) return _lazyFuture;
    
    return new Future<T>.value(_value);
  }
  
  set value(T newValue) {
    if (_isValueUpdateRequired(_value, newValue)) {
      _value = newValue;
      
      if (newValue != null) _isLazyLoadingRequired = false;
      
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
  bool isLazy = false;
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
  
  void _updateWithMetadata(_DormProxyPropertyInfo entry, EntityScan scan) {
    final _PropertyMetadataCache cache = entry.info.metadataCache;
    
    isId = cache.isId;
    isTransient = cache.isTransient;
    isNullable = cache.isNullable;
    isLabelField = cache.isLabelField;
    isMutable = (scan._root.isMutableEntity && cache.isMutable);
    isLazy = cache.isLazy;
    isSilent = cache.isSilent;
    transformFrom = cache.transformFrom;
    transformTo = cache.transformTo;
    
    genericAnnotations = cache.genericAnnotations;
    
    setInsertValue(cache.insertValue);
    setInitialValue(cache.initialValue);
  }
}