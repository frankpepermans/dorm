// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: CodeGenerator
// Target: abstract class TestEntitySuperClass
// **************************************************************************

import 'package:dorm/dorm.dart';

import 'test_entity_super.dart' as sup;

class TestEntitySuperClass extends Entity with sup.TestEntitySuperClass {
  /// refClassName
  @override
  String get refClassName => 'i112dorm_lib_src_test_test_entity_super';

  /// Public properties
  /// id
  static const String ID = 'id';
  static const Symbol ID_SYMBOL = #i112dorm_lib_src_test_test_entity_super_id;

  final DormProxy<int> _id = new DormProxy<int>(ID, ID_SYMBOL);
  @override
  int get id => _id.value;
  set id(int value) {
    _id.value = value;
  }

  /// DO_SCAN
  static void DO_SCAN /**/ ([String _R, Entity _C()]) {
    _R ??= 'i112dorm_lib_src_test_test_entity_super';
    _C ??= () => new TestEntitySuperClass();
    Entity.DO_SCAN(_R, _C);
    Entity.ASSEMBLER.scan(_R, _C, const <PropertyData>[
      const PropertyData(
          symbol: TestEntitySuperClass.ID_SYMBOL,
          name: 'id',
          type: int,
          metatags: const <dynamic>[
            const Id(0),
            const NotNullable(),
            const DefaultValue(0),
            const Immutable(),
          ]),
    ]);
  }

  /// Ctr
  TestEntitySuperClass() : super() {
    Entity.ASSEMBLER.registerProxies(this, <DormProxy<dynamic>>[_id]);
  }
  static TestEntitySuperClass /**/ construct /**/ () =>
      new TestEntitySuperClass();
}
