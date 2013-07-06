library dorm_entity_spawn_test;

import 'package:unittest/unittest.dart';
import 'package:dorm/dorm.dart';
import 'dart:json';

main() {
  EntityManager manager = new EntityManager();
  Serializer serializer = new SerializerJson();
  EntityFactory<TestEntity> factory = new EntityFactory(handleConflictAcceptClient);
  String rawDataA = '[{"id":1,"name":"Test A","?t":"entities.testEntity"}]';
  String rawDataB = '[{"id":2,"name":"Test B","?t":"entities.testEntity"}]';
  
  manager.scan(TestEntity);
  
  test('Simple spawn test', () {
    TestEntity entity = factory.spawn(serializer.incoming(rawDataA)).first;
    TestEntity entityShouldBePointer = factory.spawn(serializer.incoming(rawDataA)).first;
    TestEntity entityShouldNotBePointer = factory.spawn(serializer.incoming(rawDataB)).first;
    
    entityShouldNotBePointer.cyclicReference = entity;
    entity.cyclicReference = entityShouldNotBePointer;
    
    String outgoing = serializer.outgoing(<Entity>[entity]);
    List<String> outgoingToComplexData = parse(outgoing);
    
    expect(entity.id, 1);
    expect(entity.name, 'Test A');
    expect(entityShouldBePointer.id, 1);
    expect(entityShouldBePointer.name, 'Test A');
    expect(entityShouldNotBePointer.id, 2);
    expect(entityShouldNotBePointer.name, 'Test B');
    expect((entity == entityShouldBePointer), true);
    expect((entity != entityShouldNotBePointer), true);
    expect((outgoing.length > 0), true);
    
    outgoingToComplexData.forEach(
      (String entry) {
        Map<String, dynamic> map = parse(entry);
        
        expect(map.containsKey('id'), true);
        
        if (!map.containsKey(SerializationType.POINTER)) {
          expect(map.containsKey('name'), true);
        }
        
        expect(map[SerializationType.ENTITY_TYPE], 'entities.testEntity');
      }
    );
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
  static const Symbol ID_SYMBOL = const Symbol('orm_domain.TestEntity.id');

  int get id => _id.value;
  set id(int value) => _id.value = notifyPropertyChange(ID_SYMBOL, _id.value, value);

  //---------------------------------
  // name
  //---------------------------------

  @Property(NAME_SYMBOL, 'name')
  @LabelField()
  Proxy<String> _name;

  static const String NAME = 'name';
  static const Symbol NAME_SYMBOL = const Symbol('orm_domain.TestEntity.name');

  String get name => _name.value;
  set name(String value) => _name.value = notifyPropertyChange(NAME_SYMBOL, _name.value, value);
  
  //---------------------------------
  // cyclicReference
  //---------------------------------

  @Property(CYCLIC_REFERENCE_SYMBOL, 'name')
  Proxy<TestEntity> _cyclicReference;

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

}