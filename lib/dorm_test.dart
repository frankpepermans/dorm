library dorm_test;

import 'dorm.dart';

part 'src/test/test_entity_super.dart';
part 'src/test/test_entity.dart';
part 'src/test/another_test_entity.dart';

void ormInitialize() {
  TestEntitySuperClass.__SCAN__();
  TestEntity.__SCAN__();
  AnotherTestEntity.__SCAN__();
}