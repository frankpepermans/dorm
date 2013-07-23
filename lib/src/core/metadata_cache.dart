part of dorm;

class MetadataCache {
  
  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  Map<String, _PropertyMetadataCache> propertyMetadataCache = new Map<String, _PropertyMetadataCache>();
  
  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------
  
  MetadataCache();
  
  //---------------------------------
  //
  // Public methods
  //
  //---------------------------------
  
  void registerTagForProperty(String property, Object reflectee) {
    _PropertyMetadataCache cache = propertyMetadataCache[property];
    
    if (cache == null) {
      cache = propertyMetadataCache[property] = new _PropertyMetadataCache(property);
    }
    
    switch (reflectee.runtimeType) {
      case Id:              cache.isId = true;                                            break;
      case Transient:       cache.isTransient = true;                                     break;
      case NotNullable:     cache.isNullable = false;                                     break;
      case DefaultValue:    cache.initialValue = (reflectee as DefaultValue).value;       break;
      case LabelField:      cache.isLabelField = true;                                    break;
      case Immutable:       cache.isMutable = false;                                      break;
    }
  }
  
  //---------------------------------
  //
  // Private methods
  //
  //---------------------------------
  
  void _updateProxyWithMetadata(DormProxy proxy, EntityScan scan) {
    _PropertyMetadataCache cache = propertyMetadataCache[proxy.property];
    
    if (cache == null) {
      cache = propertyMetadataCache[proxy.property] = new _PropertyMetadataCache(proxy.property);
    }
    
    proxy.isId = cache.isId;
    proxy.isTransient = cache.isTransient;
    proxy.isNullable = cache.isNullable;
    proxy.isLabelField = cache.isLabelField;
    proxy.isMutable = (scan.isMutableEntity && cache.isMutable);
    
    proxy._initialValue = cache.initialValue;
  }
}

//---------------------------------
//
// Internal objects
//
//---------------------------------

class _PropertyMetadataCache {
  
  final String property;
  
  bool isId = false;
  bool isTransient = false;
  bool isNullable = true;
  bool isLabelField = false;
  bool isMutable = true;
  
  dynamic initialValue = null;
  
  _PropertyMetadataCache(this.property);
  
}