part of dorm;

class MetadataCache {
  
  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  List<_PropertyMetadataCache> propertyMetadataCacheList = <_PropertyMetadataCache>[];
  
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
    _PropertyMetadataCache propertyMetadataCache = _obtainTagForProperty(property);
    
    switch (reflectee.runtimeType) {
      case Id:              propertyMetadataCache.isId = true;                                            break;
      case Transient:       propertyMetadataCache.isTransient = true;                                     break;
      case NotNullable:     propertyMetadataCache.isNullable = false;                                     break;
      case DefaultValue:    propertyMetadataCache.initialValue = (reflectee as DefaultValue).value;       break;
      case LabelField:      propertyMetadataCache.isLabelField = true;                                    break;
      case Immutable:       propertyMetadataCache.isMutable = false;                                      break;
    }
  }
  
  //---------------------------------
  //
  // Private methods
  //
  //---------------------------------
  
  void _updateProxyWithMetadata(DormProxy proxy, EntityScan scan) {
    _PropertyMetadataCache propertyMetadataCache = _obtainTagForProperty(proxy.property);
    
    proxy.isId = propertyMetadataCache.isId;
    proxy.isTransient = propertyMetadataCache.isTransient;
    proxy.isNullable = propertyMetadataCache.isNullable;
    proxy.isLabelField = propertyMetadataCache.isLabelField;
    proxy.isMutable = (scan.isMutableEntity && propertyMetadataCache.isMutable);
    
    proxy._initialValue = propertyMetadataCache.initialValue;
  }
  
  _PropertyMetadataCache _obtainTagForProperty(String property) {
    return propertyMetadataCacheList.firstWhere(
      (_PropertyMetadataCache entry) => (entry.property == property),
      orElse: () {
        _PropertyMetadataCache entry = new _PropertyMetadataCache(property);
        
        propertyMetadataCacheList.add(entry);
        
        return entry;
      }
    );
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