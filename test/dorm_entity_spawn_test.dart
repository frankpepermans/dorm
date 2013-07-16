library dorm_entity_spawn_test;

import 'package:unittest/unittest.dart';
import 'package:dorm/dorm.dart';
import 'dart:json';

main() {
  EntityAssembler assembler = new EntityAssembler();
  Serializer serializer = new SerializerJson();
  String rawDataA = '[{"id":1,"name":"Test A","?t":"entities.testEntity"}]';
  String rawDataB = '[{"id":2,"name":"Test B","?t":"entities.testEntity"}]';
  
  assembler.scan(TestEntity, 'entities.testEntity', TestEntity.construct);
  
  test('Simple spawn test', () {
    EntityFactory<TestEntity> factory = new EntityFactory(handleConflictAcceptClient);
    
    TestEntity entity = factory.spawn(serializer.incoming(rawDataA)).first;
    TestEntity entityShouldBePointer = factory.spawn(serializer.incoming(rawDataA)).first;
    TestEntity entityShouldNotBePointer = factory.spawn(serializer.incoming(rawDataB)).first;
    
    entityShouldNotBePointer.cyclicReference = entity;
    entity.cyclicReference = entityShouldNotBePointer;
    
    String outgoing = serializer.outgoing(<Entity>[entity, entityShouldNotBePointer]);
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
        expect(map.containsKey(SerializationType.UID), true);
        
        expect(map[SerializationType.ENTITY_TYPE], 'entities.testEntity');
      }
    );
  });
  
  test('Conflict manager, accept client test', () {
    EntityFactory<TestEntity> factory = new EntityFactory(handleConflictAcceptClient);
    TestEntity entity;
    
    // first test, after a client change, reload the entity and expect it not to be overwritten
    entity = factory.spawn(serializer.incoming(rawDataA)).first;
    
    entity.name = 'Test C';
    
    expect(entity.isDirty(), true);
    
    TestEntity spawnedEntity = factory.spawn(serializer.incoming(rawDataA)).first; // reload and accept client
    
    expect(entity.name, 'Test C');
    expect((entity == spawnedEntity), true);
    expect(entity.isDirty(), true);
  });
  
  test('Conflict manager, accept server test', () {
    EntityFactory<TestEntity> factory = new EntityFactory(handleConflictAcceptServer);
    TestEntity entity;
    
    // first test, after a client change, reload the entity and expect it not to be overwritten
    entity = factory.spawn(serializer.incoming(rawDataA)).first;
    
    entity.name = 'Test C';
    
    expect(entity.isDirty(), true);
    
    TestEntity spawnedEntity = factory.spawn(serializer.incoming(rawDataA)).first; // reload and accept server
    
    expect(entity.name, 'Test A');
    expect((entity == spawnedEntity), true);
    expect(entity.isDirty(), false);
  });
  
  test('Speed test', () {
    List<List<Map<String, dynamic>>> jsonList = <List<Map<String, dynamic>>>[];
    EntityFactory<TestEntity> factory = new EntityFactory(handleConflictAcceptServer);
    int loopCount = 1000;
    int i = loopCount;
    DateTime time;
    
    while (i > 0) {
      List<Map<String, dynamic>> json = serializer.incoming('[{"id":${--i},"name":"Speed test","?t":"entities.testEntity"}]');
      
      jsonList.add(json);
    }
    
    i = loopCount;
    
    time = new DateTime.now();
    
    while (i > 0) {
      factory.spawn(jsonList[--i]).first;
    }
    
    int duration = time.millisecondsSinceEpoch - new DateTime.now().millisecondsSinceEpoch;
    
    print('completed in $duration ms');
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
  // refClassName
  //---------------------------------

  String get refClassName => 'entities.testEntity';

  //---------------------------------
  // id
  //---------------------------------

  @Property(ID_SYMBOL, 'id')
  @Id()
  @NotNullable()
  @DefaultValue(0)
  @Immutable()
  DormProxy<int> _id;

  static const String ID = 'id';
  static const Symbol ID_SYMBOL = const Symbol('orm_domain.TestEntity.id');

  int get id => _id.value;
  set id(int value) => _id.value = notifyPropertyChange(ID_SYMBOL, _id.value, value);

  //---------------------------------
  // name
  //---------------------------------

  @Property(NAME_SYMBOL, 'name')
  @LabelField()
  DormProxy<String> _name;

  static const String NAME = 'name';
  static const Symbol NAME_SYMBOL = const Symbol('orm_domain.TestEntity.name');

  String get name => _name.value;
  set name(String value) => _name.value = notifyPropertyChange(NAME_SYMBOL, _name.value, value);
  
  //---------------------------------
  // cyclicReference
  //---------------------------------

  @Property(CYCLIC_REFERENCE_SYMBOL, 'cyclicReference')
  DormProxy<TestEntity> _cyclicReference;

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
    EntityAssembler assembler = new EntityAssembler();
    
    _id = new DormProxy()
    ..property = 'id'
    ..propertySymbol = ID_SYMBOL;
    
    _name = new DormProxy()
    ..property = 'name'
    ..propertySymbol = NAME_SYMBOL;
    
    _cyclicReference = new DormProxy()
    ..property = 'cyclicReference'
    ..propertySymbol = CYCLIC_REFERENCE_SYMBOL;
    
    assembler.registerProxies(
      this,
      <DormProxy>[_id, _name, _cyclicReference]    
    );
  }
  
  static TestEntity construct() {
    return new TestEntity();
  }

}