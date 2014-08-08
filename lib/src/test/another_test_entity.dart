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

  String get refClassName => 'entities.AnotherTestEntity';

  //---------------------------------
  // anotherName
  //---------------------------------

  @Property(ANOTHERNAME_SYMBOL, 'anotherName', String)
  @LabelField()
  final DormProxy<String> _anotherName = new DormProxy<String>(ANOTHERNAME, ANOTHERNAME_SYMBOL);

  static const String ANOTHERNAME = 'anotherName';
  static const Symbol ANOTHERNAME_SYMBOL = const Symbol('orm_domain.AnotherTestEntity.anotherName');

  String get anotherName => _anotherName.value;
  set anotherName(String value) => _anotherName.value = notifyPropertyChange(ANOTHERNAME_SYMBOL, _anotherName.value, value);
  
  //---------------------------------
  // date
  //---------------------------------

  @Property(DATE_SYMBOL, 'date', DateTime)
  final DormProxy<DateTime> _date = new DormProxy<DateTime>(DATE, DATE_SYMBOL);

  static const String DATE = 'date';
  static const Symbol DATE_SYMBOL = const Symbol('orm_domain.AnotherTestEntity.date');

  DateTime get date => _date.value;
  set date(DateTime value) => _date.value = notifyPropertyChange(DATE_SYMBOL, _date.value, value);
  
  //---------------------------------
  // cyclicReference
  //---------------------------------

  @Property(CYCLIC_REFERENCE_SYMBOL, 'cyclicReference', TestEntity)
  final DormProxy<TestEntity> _cyclicReference = new DormProxy<TestEntity>(CYCLIC_REFERENCE, CYCLIC_REFERENCE_SYMBOL);

  static const String CYCLIC_REFERENCE = 'cyclicReference';
  static const Symbol CYCLIC_REFERENCE_SYMBOL = const Symbol('orm_domain.AnotherTestEntity.cyclicReference');

  TestEntity get cyclicReference => _cyclicReference.value;
  set cyclicReference(TestEntity value) => _cyclicReference.value = notifyPropertyChange(CYCLIC_REFERENCE_SYMBOL, _cyclicReference.value, value);

  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------

  AnotherTestEntity() : super();
  
  static AnotherTestEntity construct() => new AnotherTestEntity();
}