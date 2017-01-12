import 'package:dorm/dorm.dart';

@dorm
abstract class Address extends Entity {
  String get street;
  String get number;
  String get town;
  String get country;
}