library dorm_entity_spawn_test;

import 'package:dorm/dorm.dart';
import 'dart:async';
import 'dart:html';
import 'dart:json';

Serializer serializer = new SerializerJson();

DivElement out = query("#out");

main() {
  EntityAssembler assembler = new EntityAssembler();
  
  assembler.scan(TestEntity, 'entities.testEntity', TestEntity.construct);
  
  _runBenchmark();
}

void _runBenchmark() {
  EntityFactory<TestEntity> factory = new EntityFactory(handleConflictAcceptClient);
  List<String> jsonRaw = <String>[];
  int loopCount = 1000;
  int i = loopCount;
  int t1, t2;
  Stopwatch stopwatch;
  DateTime time;
  
  while (i > 0) {
    jsonRaw.add('{"id":${--i},"name":"Speed test","type":"type_${i}","?t":"entities.testEntity"}');
  }
  
  stopwatch = new Stopwatch()..start();
  
  List<Map<String, dynamic>> parsed = serializer.incoming('[' + jsonRaw.join(',') + ']');
  
  stopwatch.stop();
  
  t1 = stopwatch.elapsedMilliseconds;
  
  stopwatch = new Stopwatch()..start();
  
  factory.spawn(parsed);
  
  stopwatch.stop();
  
  t2 = stopwatch.elapsedMilliseconds;
  
  out.innerHtml += 'json to Map $t1 ms, dorm to entity class model $t2 ms<br>';
  
  new Timer(new Duration(seconds:1), _runBenchmark);
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
  // type
  //---------------------------------

  @Property(TYPE_SYMBOL, 'type')
  DormProxy<String> _type;

  static const String TYPE = 'type';
  static const Symbol TYPE_SYMBOL = const Symbol('orm_domain.TestEntity.type');

  String get type => _type.value;
  set type(String value) => _type.value = notifyPropertyChange(TYPE_SYMBOL, _type.value, value);
  
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
    
    _type = new DormProxy()
    ..property = 'type'
    ..propertySymbol = TYPE_SYMBOL;
    
    _cyclicReference = new DormProxy()
    ..property = 'cyclicReference'
    ..propertySymbol = CYCLIC_REFERENCE_SYMBOL;
    
    assembler.registerProxies(
      this,
      <DormProxy>[_name, _type, _cyclicReference]    
    );
  }
  
  static TestEntity construct() {
    return new TestEntity();
  }

}