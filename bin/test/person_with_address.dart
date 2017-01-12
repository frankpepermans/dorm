import 'package:dorm/dorm.dart';

import 'address.dart';
import 'person.dart';

@dorm
abstract class PersonWithAddress extends Person {
  Address get address;
}