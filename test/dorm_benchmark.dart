library dorm_entity_spawn_test;

import 'package:dorm/dorm.dart';
import 'package:dorm/dorm_test.dart';
import 'package:benchmark_harness/benchmark_harness.dart';

String jsonData;

final EntityCodec<List<TestEntity>, String> codec = new EntityCodec((Entity serverEntity, Entity clientEntity) => ConflictManager.AcceptClient, new SerializerJson());

void main() {
  ormInitialize();
  
  TemplateBenchmark.main();
}

class TemplateBenchmark extends BenchmarkBase {
  
  const TemplateBenchmark() : super("Template");

  static void main() => new TemplateBenchmark().report();
  
  List<TestEntity> run() => codec.decode(jsonData);

  void setup() {
    final int loopCount = 10000;
    List<String> jsonRaw = <String>[];
    int i = loopCount;
    
    while (i > 0) jsonRaw.add('{"id":${--i},"name":"Speed test","type":"type_${i}","?t":"entities.TestEntity"}');
  
    jsonData = '[' + jsonRaw.join(',') + ']';
  }
}