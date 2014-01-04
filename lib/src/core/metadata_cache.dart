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
  
  void registerTagForProperty(_DormPropertyInfo entry, Object reflectee) {
    final Type type = reflectee.runtimeType;
    
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