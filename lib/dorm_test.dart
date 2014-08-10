library dorm_test;

import 'dorm.dart';

part 'src/test/test_entity_super.dart';
part 'src/test/test_entity.dart';
part 'src/test/another_test_entity.dart';

void ormInitialize() {
  TestEntitySuperClass.DO_SCAN();
  TestEntity.DO_SCAN();
  AnotherTestEntity.DO_SCAN();
}