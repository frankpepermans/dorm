part of dorm;

class MetadataCache {
  
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
  
  void registerTagForProperty(_ProxyEntry entry, Object reflectee) {
    if (entry.metadataCache == null) entry.metadataCache = new _PropertyMetadataCache(entry.property);
    
    switch (reflectee.runtimeType) {
      case Id:              entry.metadataCache.isId = true;                                            break;
      case Transient:       entry.metadataCache.isTransient = true;                                     break;
      case NotNullable:     entry.metadataCache.isNullable = false;                                     break;
      case DefaultValue:    entry.metadataCache.initialValue = (reflectee as DefaultValue).value;       break;
      case LabelField:      entry.metadataCache.isLabelField = true;                                    break;
      case Immutable:       entry.metadataCache.isMutable = false;                                      break;
    }
  }
  
  //---------------------------------
  //
  // Private methods
  //
  //---------------------------------
  
  void _updateProxyWithMetadata(_ProxyEntry entry, EntityScan scan) {
    if (entry.metadataCache == null) entry.metadataCache = new _PropertyMetadataCache(entry.property);
    
    entry.proxy.isId = entry.metadataCache.isId;
    entry.proxy.isTransient = entry.metadataCache.isTransient;
    entry.proxy.isNullable = entry.metadataCache.isNullable;
    entry.proxy.isLabelField = entry.metadataCache.isLabelField;
    entry.proxy.isMutable = (scan.isMutableEntity && entry.metadataCache.isMutable);
    
    entry.proxy._initialValue = entry.metadataCache.initialValue;
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