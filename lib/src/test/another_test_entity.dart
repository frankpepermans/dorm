import 'package:dorm/dorm.dart';

import 'package:dorm/src/test/test_entity_super.dart';
import 'package:dorm/src/test/test_entity.dart';

@dorm
abstract class AnotherTestEntity implements TestEntitySuperClass {
  @LabelField()
  String get anotherName;
  DateTime get date;
  TestEntity get cyclicReference;
}