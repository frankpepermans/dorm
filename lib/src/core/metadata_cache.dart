part of dorm;

class MetadataCache {
  
  List<PropertyMetadataCache> propertyMetadataCacheList = <PropertyMetadataCache>[];
  
  PropertyMetadataCache obtainTagForProperty(String property) {
    PropertyMetadataCache propertyMetadataCache;
    
    Iterable<PropertyMetadataCache> result = propertyMetadataCacheList.where(
      (PropertyMetadataCache entry) => (entry.property == property)    
    );
    
    if (result.length == 1) {
      propertyMetadataCache = result.first;
    } else {
      propertyMetadataCache = new PropertyMetadataCache(property);
      
      propertyMetadataCacheList.add(propertyMetadataCache);
    }
    
    return propertyMetadataCache;
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