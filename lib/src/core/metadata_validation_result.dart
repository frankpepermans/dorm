part of dorm;

class MetadataValidationReason {
  
  static const String ENTITY_NOT_MUTABLE = 'entityNotMutable';
  static const String PROPERTY_NOT_MUTABLE = 'propertyNotMutable';
  static const String PROPERTY_NOT_NULLABLE = 'propertyNotNullable';
  
}

class MetadataValidationResult {
  
  final Entity entity;
  final String reasonFailed;
  final String property;
  final Symbol propertyField;
  
  const MetadataValidationResult(this.entity, this.property, this.propertyField, this.reasonFailed);
  
}