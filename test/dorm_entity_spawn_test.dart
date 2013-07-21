library dorm_entity_spawn_test;

import 'package:unittest/unittest.dart';
import 'package:dorm/dorm.dart';
import 'dart:async';
import 'dart:json';

Serializer serializer = new SerializerJson();

main() {
  EntityAssembler assembler = new EntityAssembler();
  
  assembler.scan(TestEntity, 'entities.testEntity', TestEntity.construct);
  
  new Timer(new Duration(seconds:1), _afterWarmup);
}

_afterWarmup() {
  // serializer needs this rule in order to extract dates from/to json
  serializer.addRule(
      DateTime,
      (int value) => (value != null) ? new DateTime.fromMillisecondsSinceEpoch(value, isUtc:true) : null,
      (DateTime value) => value.millisecondsSinceEpoch
  );
  
  String rawDataA = '[{"id":1,"name":"Test A","date":1234567890,"?t":"entities.testEntity"}]';
  String rawDataB = '[{"id":2,"name":"Test B","date":1234567890,"?t":"entities.testEntity"}]';
  
  test('Simple spawn test', () {
    EntityFactory<TestEntity> factory = new EntityFactory(handleConflictAcceptClient);
    
    TestEntity entity = factory.spawn(serializer.incoming(rawDataA), serializer).first;
    TestEntity entityShouldBePointer = factory.spawn(serializer.incoming(rawDataA), serializer).first;
    TestEntity entityShouldNotBePointer = factory.spawn(serializer.incoming(rawDataB), serializer).first;
    
    entityShouldNotBePointer.cyclicReference = entity;
    entity.cyclicReference = entityShouldNotBePointer;
    
    String outgoing = serializer.outgoing(<Entity>[entity, entityShouldNotBePointer]);
    List<String> outgoingToComplexData = parse(outgoing);
    
    expect(entity.id, 1);
    expect(entity.name, 'Test A');
    expect(entity.date.millisecondsSinceEpoch, 1234567890);
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
    entity = factory.spawn(serializer.incoming(rawDataA), serializer).first;
    
    entity.name = 'Test C';
    
    expect(entity.isDirty(), true);
    
    TestEntity spawnedEntity = factory.spawn(serializer.incoming(rawDataA), serializer).first; // reload and accept client
    
    expect(entity.name, 'Test C');
    expect((entity == spawnedEntity), true);
    expect(entity.isDirty(), true);
  });
  
  test('Conflict manager, accept server test', () {
    EntityFactory<TestEntity> factory = new EntityFactory(handleConflictAcceptServer);
    TestEntity entity;
    
    // first test, after a client change, reload the entity and expect it not to be overwritten
    entity = factory.spawn(serializer.incoming(rawDataA), serializer).first;
    
    entity.name = 'Test C';
    
    expect(entity.isDirty(), true);
    
    TestEntity spawnedEntity = factory.spawn(serializer.incoming(rawDataA), serializer).first; // reload and accept server
    
    expect(entity.name, 'Test A');
    expect((entity == spawnedEntity), true);
    expect(entity.isDirty(), false);
  });
  
  test('Speed test', _runBenchmark);
}

void _runBenchmark() {
  EntityFactory<TestEntity> factory = new EntityFactory(handleConflictAcceptClient);
  List<String> jsonRaw = <String>[];
  int loopCount = 1000;
  int i = loopCount;
  DateTime time;
  
  while (i > 0) {
    jsonRaw.add('{"id":${--i},"name":"Speed test","?t":"entities.testEntity"}');
  }
  
  Stopwatch stopwatch = new Stopwatch()..start();
  
  factory.spawn(serializer.incoming('[' + jsonRaw.join(',') + ']'), serializer);
  
  stopwatch.stop();
  
  print('completed in ${stopwatch.elapsedMilliseconds} ms');
}

ConflictManager handleConflictAcceptClient(Entity serverEntity, Entity clientEntity) {
  return ConflictManager.ACCEPT_CLIENT;
}

ConflictManager handleConflictAcceptServer(Entity serverEntity, Entity clientEntity) {
  return ConflictManager.ACCEPT_SERVER;
}

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
  @Id()
  @NotNullable()
  @DefaultValue(0)
  @Immutable()
  DormProxy<int> _id;

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
    EntityAssembler assembler = new EntityAssembler();
    
    _id = new DormProxy()
    ..property = 'id'
    ..propertySymbol = ID_SYMBOL;
    
    assembler.registerProxies(
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
  DormProxy<String> _name;

  static const String NAME = 'name';
  static const Symbol NAME_SYMBOL = const Symbol('orm_domain.TestEntity.name');

  String get name => _name.value;
  set name(String value) => _name.value = notifyPropertyChange(NAME_SYMBOL, _name.value, value);
  
  //---------------------------------
  // date
  //---------------------------------

  @Property(DATE_SYMBOL, 'date', DateTime)
  DormProxy<DateTime> _date;

  static const String DATE = 'date';
  static const Symbol DATE_SYMBOL = const Symbol('orm_domain.TestEntity.date');

  DateTime get date => _date.value;
  set date(DateTime value) => _date.value = notifyPropertyChange(DATE_SYMBOL, _date.value, value);
  
  //---------------------------------
  // cyclicReference
  //---------------------------------

  @Property(CYCLIC_REFERENCE_SYMBOL, 'cyclicReference', TestEntity)
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
    
    _name = new DormProxy()
    ..property = 'name'
    ..propertySymbol = NAME_SYMBOL;
    
    _date = new DormProxy()
    ..property = 'date'
    ..propertySymbol = DATE_SYMBOL;
    
    _cyclicReference = new DormProxy()
    ..property = 'cyclicReference'
    ..propertySymbol = CYCLIC_REFERENCE_SYMBOL;
    
    assembler.registerProxies(
      this,
      <DormProxy>[_name, _date, _cyclicReference]
    );
  }
  
  static TestEntity construct() {
    return new TestEntity();
  }

}