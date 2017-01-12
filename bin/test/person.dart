import 'package:dorm/dorm.dart';

@dorm
abstract class Person extends Entity {
  String get firstName;
  String get lastName;
}