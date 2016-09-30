part of dorm_test;

@Ref('entities.AnotherTestEntity')
class AnotherTestEntity extends TestEntitySuperClass {

  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  //---------------------------------
  // refClassName
  //---------------------------------

  @override String get refClassName => 'entities.AnotherTestEntity';

  //---------------------------------
  // anotherName
  //---------------------------------

  @Property(ANOTHERNAME_SYMBOL, 'anotherName', String, 'String')
  @LabelField()
  static const String ANOTHERNAME = 'anotherName';
  static const Symbol ANOTHERNAME_SYMBOL = const Symbol('orm_domain.AnotherTestEntity.anotherName');

  String anotherName;
  
  //---------------------------------
  // date
  //---------------------------------

  @Property(DATE_SYMBOL, 'date', DateTime, 'DateTime')
  static const String DATE = 'date';
  static const Symbol DATE_SYMBOL = const Symbol('orm_domain.AnotherTestEntity.date');

  DateTime date;
  
  //---------------------------------
  // cyclicReference
  //---------------------------------

  @Property(CYCLIC_REFERENCE_SYMBOL, 'cyclicReference', TestEntity, 'TestEntity')
  static const String CYCLIC_REFERENCE = 'cyclicReference';
  static const Symbol CYCLIC_REFERENCE_SYMBOL = const Symbol('orm_domain.AnotherTestEntity.cyclicReference');

  TestEntity cyclicReference;

  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------

  AnotherTestEntity() : super();
}