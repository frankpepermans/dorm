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
  
  _PropertyMetadataCache obtainTagForProperty(String property) {
    return propertyMetadataCacheList.firstWhere(
      (_PropertyMetadataCache entry) => (entry.property == property),
      orElse: () {
        _PropertyMetadataCache entry = new _PropertyMetadataCache(property);
        
        propertyMetadataCacheList.add(entry);
        
        return entry;
      }
    );
  }
  
  void registerTagForProperty(String property, Object reflectee) {
    _PropertyMetadataCache propertyMetadataCache = obtainTagForProperty(property);
    
    switch (reflectee.runtimeType) {
      case Id:              propertyMetadataCache.isId = true;                                            break;
      case Transient:       propertyMetadataCache.isTransient = true;                                     break;
      case NotNullable:     propertyMetadataCache.isNullable = false;                                     break;
      case DefaultValue:    propertyMetadataCache.initialValue = (reflectee as DefaultValue).value;       break;
      case LabelField:      propertyMetadataCache.isLabelField = true;                                    break;
      case Immutable:       propertyMetadataCache.isMutable = false;                                      break;
    }
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