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

  @Property(NAME_SYMBOL, 'name', String)
  @LabelField()
  final DormProxy<String> _name = new DormProxy<String>(NAME, NAME_SYMBOL);

  static const String NAME = 'name';
  static const Symbol NAME_SYMBOL = const Symbol('orm_domain.TestEntity.name');

  String get name => _name.value;
  set name(String value) => _name.value = notifyPropertyChange(NAME_SYMBOL, _name.value, value);
  
  //---------------------------------
  // date
  //---------------------------------

  @Property(DATE_SYMBOL, 'date', DateTime)
  final DormProxy<DateTime> _date = new DormProxy<DateTime>(DATE, DATE_SYMBOL);

  static const String DATE = 'date';
  static const Symbol DATE_SYMBOL = const Symbol('orm_domain.TestEntity.date');

  DateTime get date => _date.value;
  set date(DateTime value) => _date.value = notifyPropertyChange(DATE_SYMBOL, _date.value, value);
  
  //---------------------------------
  // cyclicReference
  //---------------------------------

  @Property(CYCLIC_REFERENCE_SYMBOL, 'cyclicReference', TestEntity)
  final DormProxy<TestEntity> _cyclicReference = new DormProxy<TestEntity>(CYCLIC_REFERENCE, CYCLIC_REFERENCE_SYMBOL);

  static const String CYCLIC_REFERENCE = 'cyclicReference';
  static const Symbol CYCLIC_REFERENCE_SYMBOL = const Symbol('orm_domain.TestEntity.cyclicReference');

  TestEntity get cyclicReference => _cyclicReference.value;
  set cyclicReference(TestEntity value) => _cyclicReference.value = notifyPropertyChange(CYCLIC_REFERENCE_SYMBOL, _cyclicReference.value, value);

  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------

  TestEntity() : super();
  
  static TestEntity construct() => new TestEntity();
}