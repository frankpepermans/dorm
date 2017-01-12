import 'package:dorm/dorm.dart';

@dorm
abstract class WithGenericClassTypes<S extends List<int>, T extends List<String>> extends Entity implements Comparable<dynamic> {
  S get a;
  T get b;
}