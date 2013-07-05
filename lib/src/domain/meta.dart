part of dorm;

class Ref {
  
  final String path;
  
  const Ref(this.path);
  
  String toString() => path;
  
}

class Property {
  
  final Symbol propertySymbol;
  final String property;
  
  const Property(this.propertySymbol, this.property);
  
  String toString() => 'property $property';
  
}

class NotNullable {
  
  const NotNullable();
  
  String toString() => 'not nullable';
  
}

class DefaultValue {
  
  final dynamic value;
  
  const DefaultValue(this.value);
  
  String toString() => 'default $value';
  
}

class Transient {
  
  const Transient();
  
  String toString() => 'transient';
  
}

class Id {
  
  const Id();
  
  String toString() => 'id';
  
}

class Immutable {
  
  const Immutable();
  
  String toString() => 'immutable';
  
}

class Lazy {
  
  const Lazy();
  
  String toString() => 'lazy';
  
}

class LabelField {
  
  const LabelField();
  
  String toString() => 'label field';
}

class Annotation {
  
  final int maxStringLength = -1;
  
  const Annotation({int maxStringLength});
  
  String toString() => 'annotation';
}