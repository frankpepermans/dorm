library dorm_entity_spawn_test;

import 'package:unittest/unittest.dart';
import 'package:dorm/dorm.dart';
import 'package:dorm/dorm_test.dart';
import 'dart:json';

Serializer serializer;
int nextId = 1;

main() {
  EntityAssembler assembler = new EntityAssembler();
  
  assembler.scan(TestEntity, 'entities.testEntity', TestEntity.construct);
  
  setup();
  run();
}

void setup() {
  serializer = new SerializerJson()
  ..addRule(
      DateTime,
      (int value) => (value != null) ? new DateTime.fromMillisecondsSinceEpoch(value, isUtc:true) : null,
      (DateTime value) => value.millisecondsSinceEpoch
  );
}

String generateJSONData(String name, DateTime date) => '[{"id":${nextId++},"name":"$name","date":${date.millisecondsSinceEpoch},"?t":"entities.testEntity"}]';

void run() {
  DateTime now = new DateTime.now().toUtc();
  
  test('Simple spawn test', () {
    String rawDataA = generateJSONData('Test A', now);
    String rawDataB = generateJSONData('Test B', now);
    
    EntityFactory<TestEntity> factory = new EntityFactory();
    
    TestEntity entity = factory.spawn(serializer.incoming(rawDataA), serializer, handleConflictAcceptClient).first;
    TestEntity entityShouldBePointer = factory.spawn(serializer.incoming(rawDataA), serializer, handleConflictAcceptClient).first;
    TestEntity entityShouldNotBePointer = factory.spawn(serializer.incoming(rawDataB), serializer, handleConflictAcceptClient).first;
    
    entityShouldNotBePointer.cyclicReference = entity;
    entity.cyclicReference = entityShouldNotBePointer;
    
    String outgoing = serializer.outgoing(<Entity>[entity, entityShouldNotBePointer]);
    List<String> outgoingToComplexData = parse(outgoing);
    
    expect(entity.id, 1);
    expect(entity.name, 'Test A');
    expect(entity.date.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
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
    String rawDataC = generateJSONData('Test C', now);
    EntityFactory<TestEntity> factory = new EntityFactory();
    TestEntity entity;
    
    // first test, after a client change, reload the entity and expect it not to be overwritten
    entity = factory.spawn(serializer.incoming(rawDataC), serializer, handleConflictAcceptClient).first;
    
    entity.name = 'Test C edited';
    
    expect(entity.isDirty(), true);
    
    TestEntity spawnedEntity = factory.spawn(serializer.incoming(rawDataC), serializer, handleConflictAcceptClient).first; // reload and accept client
    
    expect(entity.name, 'Test C edited');
    expect((entity == spawnedEntity), true);
    expect(entity.isDirty(), true);
  });
  
  test('Conflict manager, accept server test', () {
    String rawDataD = generateJSONData('Test D', now);
    EntityFactory<TestEntity> factory = new EntityFactory();
    TestEntity entity;
    
    // first test, after a client change, reload the entity and expect it not to be overwritten
    entity = factory.spawn(serializer.incoming(rawDataD), serializer, handleConflictAcceptServer).first;
    
    entity.name = 'Test D edited';
    
    expect(entity.isDirty(), true);
    
    TestEntity spawnedEntity = factory.spawn(serializer.incoming(rawDataD), serializer, handleConflictAcceptServer).first; // reload and accept server
    
    expect(entity.name, 'Test D');
    expect((entity == spawnedEntity), true);
    expect(entity.isDirty(), false);
  });
  
  test('Post processing', ()  {
    String rawDataE = generateJSONData('Test E', now);
    EntityFactory<TestEntity> factory = new EntityFactory()
    ..addPostProcessor(
      new EntityPostProcessor(
        (TestEntity entity) => entity.id = 1000 
      )    
    );
    TestEntity entity = factory.spawnSingle(serializer.incoming(rawDataE).first, serializer, handleConflictAcceptServer);
  
    expect(entity.id, 1000);
  });
}

ConflictManager handleConflictAcceptClient(Entity serverEntity, Entity clientEntity) => ConflictManager.ACCEPT_CLIENT;
ConflictManager handleConflictAcceptServer(Entity serverEntity, Entity clientEntity) => ConflictManager.ACCEPT_SERVER;