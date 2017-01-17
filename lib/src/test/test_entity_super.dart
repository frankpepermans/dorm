import 'package:dorm/dorm.dart';

@dorm
abstract class TestEntitySuperClass implements Entity {
  @Id(0)
  @NotNullable()
  @DefaultValue(0)
  @Immutable()
  int get id;
}