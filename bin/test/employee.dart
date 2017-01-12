import 'package:dorm/dorm.dart';

import 'person_with_address.dart';

@dorm
abstract class Employee extends PersonWithAddress {
  @Id('')
  @DefaultValue('test_obj')
  int get id;
  Employee get reportsTo;
}