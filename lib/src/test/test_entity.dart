part of dorm_test;

@Ref('entities.TestEntity')
class TestEntity extends TestEntitySuperClass {

  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  //---------------------------------
  // refClassName
  //---------------------------------

  String get refClassName => 'entities.TestEntity';

  //---------------------------------
  // name
  //---------------------------------

  @Property(NAME_SYMBOL, 'name', String, 'String')
  @LabelField()
  static const String NAME = 'name';
  static const Symbol NAME_SYMBOL = const Symbol('orm_domain.TestEntity.name');

  String name;
  
  //---------------------------------
  // date
  //---------------------------------

  @Property(DATE_SYMBOL, 'date', DateTime, 'DateTime')
  static const String DATE = 'date';
  static const Symbol DATE_SYMBOL = const Symbol('orm_domain.TestEntity.date');

  DateTime date;
  
  //---------------------------------
  // cyclicReference
  //---------------------------------

  @Property(CYCLIC_REFERENCE_SYMBOL, 'cyclicReference', TestEntity, 'TestEntity')
  static const String CYCLIC_REFERENCE = 'cyclicReference';
  static const Symbol CYCLIC_REFERENCE_SYMBOL = const Symbol('orm_domain.TestEntity.cyclicReference');

  TestEntity cyclicReference;

  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------

  TestEntity() : super();
}