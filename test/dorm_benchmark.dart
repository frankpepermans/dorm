library dorm_entity_spawn_test;

import 'package:dorm/dorm.dart';
import 'dart:async';
import 'dart:html';
import 'dart:json';

Serializer serializer = new SerializerJson();
List<Map<String, dynamic>> rawData;

main() {
  EntityAssembler assembler = new EntityAssembler();
  
  assembler.scan(TestEntity, 'entities.testEntity', TestEntity.construct);
  
  _buildRawData();
  _runBenchmark(0);
}

void _buildRawData() {
  List<String> jsonRaw = <String>[];
  int loopCount = 1000;
  int i = loopCount;
  DateTime time;
  
  while (i > 0) {
    jsonRaw.add('{"id":${--i},"name":"Speed test","?t":"entities.testEntity"}');
  }
  
  rawData = serializer.incoming('[' + jsonRaw.join(',') + ']');
}

void _runBenchmark(_) {
  EntityFactory<TestEntity> factory = new EntityFactory(handleConflictAcceptClient);
  
  Stopwatch stopwatch = new Stopwatch()..start();
  
  factory.spawn(rawData);
  
  stopwatch.stop();
  
  print('completed in ${stopwatch.elapsedMilliseconds} ms');
  
  window.animationFrame.then(_runBenchmark);
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

  @Property(ID_SYMBOL, 'id')
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
    
    _name = new DormProxy()
    ..property = 'name'
    ..propertySymbol = NAME_SYMBOL;
    
    _cyclicReference = new DormProxy()
    ..property = 'cyclicReference'
    ..propertySymbol = CYCLIC_REFERENCE_SYMBOL;
    
    assembler.registerProxies(
      this,
      <DormProxy>[_name, _cyclicReference]    
    );
  }
  
  static TestEntity construct() {
    return new TestEntity();
  }

}