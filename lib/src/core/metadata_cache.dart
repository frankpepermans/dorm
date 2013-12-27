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
  
  void registerTagForProperty(_DormProxyListEntry entry, Object reflectee) {
    final Type type = reflectee.runtimeType;
    
    if (entry.metadataCache == null) entry.metadataCache = new _PropertyMetadataCache(entry.property);
    
    if (type == Id) {
      entry.metadataCache.isId = true;
      entry.metadataCache.insertValue = (reflectee as Id).insertValue;
    } else if (type == Transient)     entry.metadataCache.isTransient = true;
      else if (type == NotNullable)   entry.metadataCache.isNullable = false;
      else if (type == DefaultValue)  entry.metadataCache.initialValue = (reflectee as DefaultValue).value;
      else if (type == LabelField)    entry.metadataCache.isLabelField = true;
      else if (type == Immutable)     entry.metadataCache.isMutable = false;
      else if (type == Lazy)          entry.metadataCache.isLazy = true;
  }
  
  //---------------------------------
  //
  // Private methods
  //
  //---------------------------------
  
  void _updateProxyWithMetadata(_DormProxyListEntry entry, EntityScan scan) {
    if (entry.metadataCache == null) entry.metadataCache = new _PropertyMetadataCache(entry.property);
    
    entry.proxy.isId = entry.metadataCache.isId;
    entry.proxy.isTransient = entry.metadataCache.isTransient;
    entry.proxy.isNullable = entry.metadataCache.isNullable;
    entry.proxy.isLabelField = entry.metadataCache.isLabelField;
    entry.proxy.isMutable = (scan.isMutableEntity && entry.metadataCache.isMutable);
    entry.proxy.isLazy = entry.metadataCache.isLazy;
    
    entry.proxy.setInsertValue(entry.metadataCache.insertValue);
    entry.proxy.setInitialValue(entry.metadataCache.initialValue);
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
  
  dynamic insertValue = null;
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