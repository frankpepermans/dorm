part of dorm;

class MetadataCache {
  
  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------
  
  const MetadataCache();
  
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
      case Lazy:            entry.metadataCache.isLazy = true;                                          break;
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
    entry.proxy.isLazy = entry.metadataCache.isLazy;
    
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
  bool isLazy = false;
  
  dynamic initialValue = null;
  
  _PropertyMetadataCache(this.property);
  
  MetadataExternalized _getMetadataExternal() {
    return new MetadataExternalized(
        isId, 
        isTransient, 
        isNullable, 
        isLabelField, 
        isMutable,
        isLazy
    );
  }
}

class MetadataExternalized {
  
  final bool isId;
  final bool isTransient;
  final bool isNullable;
  final bool isLabelField;
  final bool isMutable;
  final bool isLazy;
  
  const MetadataExternalized(this.isId, this.isTransient, this.isNullable, this.isLabelField, this.isMutable, this.isLazy);
  
}