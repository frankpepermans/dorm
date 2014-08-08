part of dorm_test;

@Ref('entities.TestEntitySuperClass')
class TestEntitySuperClass extends Entity {

  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  //---------------------------------
  // refClassName
  //---------------------------------

  String get refClassName => 'entities.TestEntitySuperClass';

  //---------------------------------
  // id
  //---------------------------------

  @Property(ID_SYMBOL, 'id', int)
  @Id(0)
  @NotNullable()
  @DefaultValue(0)
  @Immutable()
  final DormProxy<int> _id = new DormProxy<int>(ID, ID_SYMBOL);

  static const String ID = 'id';
  static const Symbol ID_SYMBOL = const Symbol('orm_domain.TestEntitySuperClass.id');

  int get id => _id.value;
  set id(int value) => _id.value = notifyPropertyChange(ID_SYMBOL, _id.value, value);

  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------

  TestEntitySuperClass() : super();
  
  static TestEntitySuperClass construct() => new TestEntitySuperClass();

}