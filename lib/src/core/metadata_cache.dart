part of dorm;

class MetadataCache {
  
  List<PropertyMetadataCache> propertyMetadataCacheList = <PropertyMetadataCache>[];
  
  PropertyMetadataCache obtainTagForProperty(String property) {
    return propertyMetadataCacheList.firstWhere(
      (PropertyMetadataCache entry) => (entry.property == property),
      orElse: () {
        PropertyMetadataCache entry = new PropertyMetadataCache(property);
        
        propertyMetadataCacheList.add(entry);
        
        return entry;
      }
    );
  }
  
  void registerTagForProperty(String property, dynamic reflectee) {
    PropertyMetadataCache propertyMetadataCache = obtainTagForProperty(property);
    
    if (reflectee is Id) {
      propertyMetadataCache.isId = true;
    } else if (reflectee is Transient) {
      propertyMetadataCache.isTransient = true;
    } else if (reflectee is NotNullable) {
      propertyMetadataCache.isNullable = false;
    } else if (reflectee is DefaultValue) {
      propertyMetadataCache.initialValue = (reflectee as DefaultValue).value;
    } else if (reflectee is LabelField) {
      propertyMetadataCache.isLabelField = true;
    } else if (reflectee is Immutable) {
      propertyMetadataCache.isMutable = false;
    }
  }
}

class PropertyMetadataCache {
  
  final String property;
  
  bool isId = false;
  bool isTransient = false;
  bool isNullable = true;
  bool isLabelField = false;
  bool isMutable = true;
  
  dynamic initialValue = null;
  
  PropertyMetadataCache(this.property);
  
}