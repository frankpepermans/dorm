part of dorm;

class DormProxy<T> {
  
  //-----------------------------------
  //
  // Private properties
  //
  //-----------------------------------

  int _resultLen = -1;
  
  //-----------------------------------
  //
  // Public properties
  //
  //-----------------------------------
  
  T value;
  
  final String _property;
  final Symbol _propertySymbol;
  
  bool hasDelta = false;

  bool get isId => _cache.isId;
  bool get isTransient => _cache.isTransient;
  bool get isNullable => _cache.isNullable;
  bool get isLabelField => _cache.isLabelField;
  bool get isSilent => _cache.isSilent;
  String transformFrom, transformTo;

  _PropertyMetadataCache _cache;
  
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
  
  void setInitialValue(dynamic initialValue) {
    if (value is List && initialValue is List) {
      List valueCast = value as List;

      valueCast.clear();
      valueCast.addAll(initialValue);
    } else {
      value = initialValue as T;
    }
  }
  
  //-----------------------------------
  //
  // Private methods
  //
  //-----------------------------------
  
  void _updateWithMetadata(_PropertyMetadataCache cache) {
    _cache = cache;

    try {
      setInitialValue(cache.initialValue as T);
    } catch (error) {
      print(error.message);
      print(cache.insertValue);
    }
  }
}