import 'package:dorm/dorm.dart';

import 'package:dorm/src/test/test_entity_super.dart';

@dorm
abstract class TestEntity implements TestEntitySuperClass {
  @LabelField()
  String get name;
  DateTime get date;
  TestEntity get cyclicReference;
}