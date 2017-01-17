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
      else if (type == Silent)        entry.metadataCache.isSilent = true;
      else if (type == Transform)     {
        entry.metadataCache.transformFrom = (reflectee as Transform).from;
        entry.metadataCache.transformTo = (reflectee as Transform).to;
      }
      else if (type == Annotation)    entry.metadataCache.genericAnnotations = (reflectee as Annotation).params;
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
  bool isSilent = false;
  String transformFrom, transformTo;
  Map<String, dynamic> genericAnnotations;
  
  dynamic insertValue;
  dynamic initialValue;
  
  _PropertyMetadataCache(this.property);
}

class MetadataExternalized {
  
  final String expectedType;
  final bool isId;
  final bool isTransient;
  final bool isNullable;
  final bool isLabelField;
  final bool isMutable;
  final bool isSilent;
  final String transformFrom, transformTo;
  final Map<String, dynamic> genericAnnotations;
  
  const MetadataExternalized(this.expectedType, this.isId, this.isTransient, this.isNullable, this.isLabelField, this.isMutable, this.isSilent, this.transformFrom, this.transformTo, this.genericAnnotations);
  
}