part of dorm_test;

@Ref('entities.testEntitySuperClass')
class TestEntitySuperClass extends Entity {

  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  //---------------------------------
  // refClassName
  //---------------------------------

  String get refClassName => 'entities.testEntitySuperClass';

  //---------------------------------
  // id
  //---------------------------------

  @Property(ID_SYMBOL, 'id', int)
  @Id(0)
  @NotNullable()
  @DefaultValue(0)
  @Immutable()
  final DormProxy<int> _id = new DormProxy<int>('id');

  static const String ID = 'id';
  static const Symbol ID_SYMBOL = const Symbol('orm_domain.TestEntitySuperClass.id');

  int get id => _id.value;
  set id(int value) => _id.value = notifyPropertyChange(ID_SYMBOL, _id.value, value);

  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------

  TestEntitySuperClass() : super() {
    Entity.ASSEMBLER.registerProxies(
        this,
        <DormProxy>[_id]    
    );
  }
  
  static TestEntitySuperClass construct() {
    return new TestEntitySuperClass();
  }

}

@Ref('entities.testEntity')
class TestEntity extends TestEntitySuperClass {

  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  //---------------------------------
  // refClassName
  //---------------------------------

  String get refClassName => 'entities.testEntity';

  //---------------------------------
  // name
  //---------------------------------

  @Property(NAME_SYMBOL, 'name', String)
  @LabelField()
  final DormProxy<String> _name = new DormProxy<String>('name');

  static const String NAME = 'name';
  static const Symbol NAME_SYMBOL = const Symbol('orm_domain.TestEntity.name');

  String get name => _name.value;
  set name(String value) => _name.value = notifyPropertyChange(NAME_SYMBOL, _name.value, value);
  
  //---------------------------------
  // date
  //---------------------------------

  @Property(DATE_SYMBOL, 'date', DateTime)
  final DormProxy<DateTime> _date = new DormProxy<DateTime>('date');

  static const String DATE = 'date';
  static const Symbol DATE_SYMBOL = const Symbol('orm_domain.TestEntity.date');

  DateTime get date => _date.value;
  set date(DateTime value) => _date.value = notifyPropertyChange(DATE_SYMBOL, _date.value, value);
  
  //---------------------------------
  // cyclicReference
  //---------------------------------

  @Property(CYCLIC_REFERENCE_SYMBOL, 'cyclicReference', TestEntity)
  final DormProxy<TestEntity> _cyclicReference = new DormProxy<TestEntity>('cyclicReference');

  static const String CYCLIC_REFERENCE = 'cyclicReference';
  static const Symbol CYCLIC_REFERENCE_SYMBOL = const Symbol('orm_domain.TestEntity.cyclicReference');

  TestEntity get cyclicReference => _cyclicReference.value;
  set cyclicReference(TestEntity value) => _cyclicReference.value = notifyPropertyChange(CYCLIC_REFERENCE_SYMBOL, _cyclicReference.value, value);

  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------

  TestEntity() : super() {
    Entity.ASSEMBLER.registerProxies(
      this,
      <DormProxy>[_name, _date, _cyclicReference]
    );
  }
  
  static TestEntity construct() => new TestEntity();
}