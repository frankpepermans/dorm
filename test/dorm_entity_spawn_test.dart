library dorm_entity_spawn_test;

import 'package:unittest/unittest.dart';
import 'package:dorm/dorm.dart';

main() {
  EntityManager manager = new EntityManager();
  Serializer serializer = new SerializerJson();
  EntityFactory<TestEntity> factory = new EntityFactory(handleConflictAcceptClient);
  String rawData = '[{"id":1,"name":"Test","?t":"entities.testEntity"}]';
  
  manager.scan(TestEntity);
  
  test('Simple spawn test', () {
    TestEntity entity = factory.spawn(serializer.incoming(rawData)).first;
    TestEntity entityShouldBePointer = factory.spawn(serializer.incoming(rawData)).first;
    
    expect(entity.id, 1);
    expect(entity.name, 'Test');
    // both entities should be one and the same, not 2 seperate instances
    expect((entity == entityShouldBePointer), true);
  });
}

ConflictManager handleConflictAcceptClient(Entity serverEntity, Entity clientEntity) {
  return ConflictManager.ACCEPT_CLIENT;
}

ConflictManager handleConflictAcceptServer(Entity serverEntity, Entity clientEntity) {
  return ConflictManager.ACCEPT_SERVER;
}

@Ref('entities.testEntity')
class TestEntity extends Entity {

  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------

  //---------------------------------
  // id
  //---------------------------------

  @Property(ID_SYMBOL, 'id')
  @Id()
  @NotNullable()
  @DefaultValue(0)
  @Immutable()
  Proxy<int> _id;

  static const String ID = 'id';
  static const Symbol ID_SYMBOL = const Symbol('orm_domain.Person.id');

  int get id => _id.value;
  set id(int value) => _id.value = notifyPropertyChange(ID_SYMBOL, _id.value, value);

  //---------------------------------
  // name
  //---------------------------------

  @Property(NAME_SYMBOL, 'name')
  @LabelField()
  Proxy<String> _name;

  static const String NAME = 'name';
  static const Symbol NAME_SYMBOL = const Symbol('orm_domain.Person.name');

  String get name => _name.value;
  set name(String value) => _name.value = notifyPropertyChange(NAME_SYMBOL, _name.value, value);

  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------

  TestEntity() : super();

}