library dorm_entity_spawn_test;

import 'package:dorm/dorm.dart';
import 'package:dorm/dorm_test.dart';
import 'package:benchmark_harness/benchmark_harness.dart';

EntityFactory entityFactory;
Serializer serializer;
String jsonData;

main() {
  TemplateBenchmark.main();
}

class TemplateBenchmark extends BenchmarkBase {
  
  const TemplateBenchmark() : super("Template");

  static void main() {
    new TemplateBenchmark().report();
  }
  
  void run() => _runBenchmark();

  void setup() {
    final int loopCount = 10000;
    List<String> jsonRaw = <String>[];
    int i = loopCount;
    
    entityFactory = new EntityFactory();
    serializer = new SerializerJson();
    
    Entity.ASSEMBLER.scan(TestEntity, 'entities.testEntity', TestEntity.construct);
    
    while (i > 0) jsonRaw.add('{"id":${--i},"name":"Speed test","type":"type_${i}","?t":"entities.testEntity"}');
  
    jsonData = '[' + jsonRaw.join(',') + ']';
  }
}

void _runBenchmark() {
  entityFactory.spawn(serializer.incoming(jsonData), serializer, handleConflictAcceptClient);
  
  //out.innerHtml += 'json to Map $t1 ms, dorm to entity class model $t2 ms<br>';
}

ConflictManager handleConflictAcceptClient(Entity serverEntity, Entity clientEntity) => ConflictManager.ACCEPT_CLIENT;

ConflictManager handleConflictAcceptServer(Entity serverEntity, Entity clientEntity) => ConflictManager.ACCEPT_SERVER;