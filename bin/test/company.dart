import 'package:dorm/dorm.dart';

import 'address.dart';
import 'employee.dart';

@dorm
abstract class Company extends Entity {
  String get name;
  DateTime get founded;
  Address get address;
  Iterable<Employee> get employees;
}