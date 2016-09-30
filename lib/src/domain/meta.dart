part of dorm;

//-----------------------------------
// Ref annotation
//-----------------------------------

class Ref {
  
  final String path;
  
  const Ref(this.path);

  @override String toString() => path;
  
}

//-----------------------------------
// Property annotation
//-----------------------------------

class Property {
  
  final Symbol propertySymbol;
  final String property;
  final Type type;
  final String expectedTypeAsString;
  
  const Property(this.propertySymbol, this.property, this.type, this.expectedTypeAsString);
  
  @override String toString() => 'property $property';
  
}

//-----------------------------------
// NotNullable annotation
//-----------------------------------

class NotNullable {
  
  const NotNullable();

  @override String toString() => 'not nullable';
  
}

//-----------------------------------
// DefaultValue annotation
//-----------------------------------

class DefaultValue {
  
  final dynamic value;
  
  const DefaultValue(this.value);

  @override String toString() => 'default $value';
  
}

//-----------------------------------
// Transient annotation
//-----------------------------------

class Transient {
  
  const Transient();

  @override String toString() => 'transient';
  
}

//-----------------------------------
// Id annotation
//-----------------------------------

class Id {
  
  final dynamic insertValue;
  
  const Id(this.insertValue);

  @override String toString() => 'id $insertValue';
  
}

//-----------------------------------
// Immutable annotation
//-----------------------------------

class Immutable {
  
  const Immutable();

  @override String toString() => 'immutable';
  
}

//-----------------------------------
// Lazy annotation
//-----------------------------------

class Lazy {
  
  const Lazy();

  @override String toString() => 'lazy';
  
}

//-----------------------------------
// LabelField annotation
//-----------------------------------

class LabelField {
  
  const LabelField();

  @override String toString() => 'label field';
}

//-----------------------------------
// Silent annotation
//-----------------------------------

class Silent {
  
  const Silent();

  @override String toString() => 'silent';
}

//-----------------------------------
// Transform annotation
//-----------------------------------

class Transform {
  
  final String from, to;
  
  const Transform(this.from, this.to);

  @override String toString() => 'transform $from to $to';

}

//-----------------------------------
// Generic annotation
//-----------------------------------

class Annotation {
  
  final Map<String, dynamic> params;
  
  const Annotation(this.params);

  @override String toString() => 'generic annotation';
}