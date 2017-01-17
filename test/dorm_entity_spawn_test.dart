library dorm_entity_spawn_test;

import 'package:test/test.dart';
import 'package:dorm/dorm.dart';
import 'package:dorm/dorm_test.dart';
import 'dart:convert';

Serializer serializer;
int nextId = 1;

main() {
  TestEntitySuperClass.DO_SCAN();
  TestEntity.DO_SCAN();
  AnotherTestEntity.DO_SCAN();

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

String generateJSONData(String name, DateTime date, String type) => '[{"id":${nextId++},"name":"$name","date":${date.millisecondsSinceEpoch},"?t":"$type"}]';

String generateJSONPointerData(String name, DateTime date, String type) => '[{"id":${nextId},"name":"$name","date":${date.millisecondsSinceEpoch},"cyclicReference":{"?p":true, "?t":"$type", "id":${nextId++}}, "?t":"$type"}, {"?p":true, "?t":"$type", "id":${nextId++}}]';

void run() {
  DateTime now = new DateTime.now().toUtc();
  
  test('Inheritance', () {
    String rawDataA = generateJSONData('Test A', now, 'i112dorm_lib_src_test_another_test_entity');
    
    EntityFactory<Entity> factory = new EntityFactory<Entity>();
    
    factory.spawn(serializer.incoming(rawDataA), serializer).first;
  });
  
  test('Simple spawn test', () {
    String rawDataA = generateJSONData('Test A', now, 'i112dorm_lib_src_test_test_entity');
    String rawDataB = generateJSONData('Test B', now, 'i112dorm_lib_src_test_test_entity');
    
    EntityFactory<Entity> factory = new EntityFactory<Entity>();
    
    TestEntity entity = factory.spawn(serializer.incoming(rawDataA), serializer).first;
    TestEntity entityShouldBePointer = factory.spawn(serializer.incoming(rawDataA), serializer).first;
    TestEntity entityShouldNotBePointer = factory.spawn(serializer.incoming(rawDataB), serializer).first;
    
    entityShouldNotBePointer.cyclicReference = entity.duplicate();
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
    expect((outgoing.length > 0), true);
    
    outgoingToComplexData.forEach(
      (Map<String, dynamic> map) {
        expect(map.containsKey('id'), true);
        expect(map.containsKey(SerializationType.UID), true);
        
        expect(map[SerializationType.ENTITY_TYPE], 'i112dorm_lib_src_test_test_entity');
      }
    );
  });
  
  test('Post processing', ()  {
    String rawDataE = generateJSONData('Test E', now, 'i112dorm_lib_src_test_test_entity');

    EntityFactory<Entity> factory = new EntityFactory<Entity>()
    ..addPostProcessor(
      new EntityPostProcessor((Entity entity) {
        if (entity is TestEntity) entity.id = 1000;
      })
    );
    TestEntity entity = factory.spawnSingle(serializer.incoming(rawDataE).first, serializer);
    
    expect(entity.id, 1000);
  });
  
  test('Cloning', ()  {
    String rawDataE = generateJSONData('Test F', now, 'i112dorm_lib_src_test_test_entity');
    EntityFactory<Entity> factory = new EntityFactory<Entity>();
    TestEntity entity = factory.spawnSingle(serializer.incoming(rawDataE).first, serializer);
    TestEntity entityClone = entity.duplicate();
  
    expect(entityClone.name, 'Test F');
    expect(entityClone.date.millisecondsSinceEpoch, entity.date.millisecondsSinceEpoch);
  });
}