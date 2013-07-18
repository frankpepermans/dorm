part of dorm;

//-----------------------------------
// Ref annotation
//-----------------------------------

class Ref {
  
  final String path;
  
  const Ref(this.path);
  
  String toString() => path;
  
}

//-----------------------------------
// Property annotation
//-----------------------------------

class Property {
  
  final Symbol propertySymbol;
  final String property;
  
  const Property(this.propertySymbol, this.property);
  
  String toString() => 'property $property';
  
}

//-----------------------------------
// NotNullable annotation
//-----------------------------------

class NotNullable {
  
  const NotNullable();
  
  String toString() => 'not nullable';
  
}

//-----------------------------------
// DefaultValue annotation
//-----------------------------------

class DefaultValue {
  
  final dynamic value;
  
  const DefaultValue(this.value);
  
  String toString() => 'default $value';
  
}

//-----------------------------------
// Transient annotation
//-----------------------------------

class Transient {
  
  const Transient();
  
  String toString() => 'transient';
  
}

//-----------------------------------
// Id annotation
//-----------------------------------

class Id {
  
  const Id();
  
  String toString() => 'id';
  
}

//-----------------------------------
// Immutable annotation
//-----------------------------------

class Immutable {
  
  const Immutable();
  
  String toString() => 'immutable';
  
}

//-----------------------------------
// Lazy annotation
//-----------------------------------

class Lazy {
  
  const Lazy();
  
  String toString() => 'lazy';
  
}

//-----------------------------------
// LabelField annotation
//-----------------------------------

class LabelField {
  
  const LabelField();
  
  String toString() => 'label field';
}

//-----------------------------------
// Annotation annotation
//-----------------------------------

class Annotation {
  
  final int maxStringLength = -1;
  
  const Annotation({int maxStringLength});
  
  String toString() => 'annotation';
}