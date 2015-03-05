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

  @Property(ID_SYMBOL, 'id', int, 'int')
  @Id(0)
  @NotNullable()
  @DefaultValue(0)
  @Immutable()
  static const String ID = 'id';
  static const Symbol ID_SYMBOL = const Symbol('orm_domain.TestEntitySuperClass.id');

  int id;

  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------

  TestEntitySuperClass() : super();

}