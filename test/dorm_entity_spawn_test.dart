library dorm_entity_spawn_test;

import 'package:unittest/unittest.dart';
import 'package:dorm/dorm.dart';
import 'package:dorm/dorm_test.dart';
import 'dart:convert';

Serializer serializer;
int nextId = 1;

main() {
  ormInitialize();
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

String generateJSONData(String name, DateTime date, String type) => '[{"id":${nextId++},"name":"$name","date":${date.millisecondsSinceEpoch},"?t":"entities.$type"}]';

String generateJSONPointerData(String name, DateTime date, String type) => '[{"id":${nextId},"name":"$name","date":${date.millisecondsSinceEpoch},"cyclicReference":{"?p":true, "?t":"entities.$type", "id":${nextId++}}, "?t":"entities.$type"}, {"?p":true, "?t":"entities.$type", "id":${nextId++}}]';

void run() {
  DateTime now = new DateTime.now().toUtc();
  
  test('Inheritance', () {
    String rawDataA = generateJSONData('Test A', now, 'AnotherTestEntity');
    
    EntityFactory<AnotherTestEntity> factory = new EntityFactory();
    
    factory.spawn(serializer.incoming(rawDataA), serializer, handleConflictAcceptClient).first;
  });
  
  test('Simple spawn test', () {
    String rawDataA = generateJSONData('Test A', now, 'TestEntity');
    String rawDataB = generateJSONData('Test B', now, 'TestEntity');
    
    EntityFactory<TestEntity> factory = new EntityFactory();
    
    TestEntity entity = factory.spawn(serializer.incoming(rawDataA), serializer, handleConflictAcceptClient).first;
    TestEntity entityShouldBePointer = factory.spawn(serializer.incoming(rawDataA), serializer, handleConflictAcceptClient).first;
    TestEntity entityShouldNotBePointer = factory.spawn(serializer.incoming(rawDataB), serializer, handleConflictAcceptClient).first;
    
    entityShouldNotBePointer.cyclicReference = entity;
    entity.cyclicReference = entityShouldNotBePointer;
    
    String outgoing = serializer.outgoing(<Entity>[entity, entityShouldNotBePointer]);
    List<Map<String, dynamic>> outgoingToComplexData = JSON.decode(outgoing) as List<Map<String, dynamic>>;
    
    expect(entity.id, 2);
    expect(entity.name, 'Test A');
    expect(entity.date.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    expect(entityShouldBePointer.id, 2);
    expect(entityShouldBePointer.name, 'Test A');
    expect(entityShouldNotBePointer.id, 3);
    expect(entityShouldNotBePointer.name, 'Test B');
    expect((entity == entityShouldBePointer), true);
    expect((entity != entityShouldNotBePointer), true);
    expect((outgoing.length > 0), true);
    
    outgoingToComplexData.forEach(
      (Map<String, dynamic> map) {
        expect(map.containsKey('id'), true);
        expect(map.containsKey(SerializationType.UID), true);
        
        expect(map[SerializationType.ENTITY_TYPE], 'entities.TestEntity');
      }
    );
  });
  
  test('Conflict manager, accept client test', () {
    String rawDataC = generateJSONData('Test C', now, 'TestEntity');
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
    String rawDataD = generateJSONData('Test D', now, 'TestEntity');
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
    String rawDataE = generateJSONData('Test E', now, 'TestEntity');
    EntityFactory<TestEntity> factory = new EntityFactory()
    ..addPostProcessor(
      new EntityPostProcessor(
        (TestEntity entity) => entity.id = 1000 
      )    
    );
    TestEntity entity = factory.spawnSingle(serializer.incoming(rawDataE).first, serializer, handleConflictAcceptServer);
    
    expect(entity.id, 1000);
  });
  
  test('Cloning', ()  {
    String rawDataE = generateJSONData('Test F', now, 'TestEntity');
    EntityFactory<TestEntity> factory = new EntityFactory();
    TestEntity entity = factory.spawnSingle(serializer.incoming(rawDataE).first, serializer, handleConflictAcceptServer);
    TestEntity entityClone = entity.duplicate();
  
    expect(entityClone.name, 'Test F');
    expect(entityClone.date.millisecondsSinceEpoch, entity.date.millisecondsSinceEpoch);
  });
  
  test('json pointers', ()  {
    String rawDataE = generateJSONPointerData('Test G', now, 'TestEntity');
    EntityFactory<TestEntity> factory = new EntityFactory();
    TestEntity entity = factory.spawnSingle(serializer.incoming(rawDataE).first, serializer, handleConflictAcceptServer);
    // list entry 0 is the encoded entity, entry 1 is a pointer to 0
    // upon decoding, it should produce the same exact entity instance in the list
    expect(entity == entity.cyclicReference, true);
  });
}

ConflictManager handleConflictAcceptClient(Entity serverEntity, Entity clientEntity) => ConflictManager.AcceptClient;
ConflictManager handleConflictAcceptServer(Entity serverEntity, Entity clientEntity) => ConflictManager.AcceptServer;