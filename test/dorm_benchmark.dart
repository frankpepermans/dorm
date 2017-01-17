library dorm_entity_spawn_test;

import 'package:dorm/dorm.dart';
import 'package:dorm/dorm_test.dart';
import 'package:benchmark_harness/benchmark_harness.dart';

String jsonData;

final EntityCodec<List<TestEntity>, String> codec = new EntityCodec(new SerializerJson());

void main() {
  TestEntitySuperClass.DO_SCAN();
  TestEntity.DO_SCAN();
  AnotherTestEntity.DO_SCAN();
  
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
    
    while (i > 0) jsonRaw.add('{"id":${--i},"name":"Speed test","type":"type_${i}","?t":"i112dorm_lib_src_test_test_entity"}');
  
    jsonData = '[' + jsonRaw.join(',') + ']';
  }
}