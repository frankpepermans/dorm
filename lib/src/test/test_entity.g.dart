// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: CodeGenerator
// Target: abstract class TestEntity
// **************************************************************************

import 'package:dorm/dorm.dart';
import 'package:dorm/src/test/test_entity_super.g.dart';

import 'test_entity.dart' as sup;

class TestEntity extends TestEntitySuperClass
    with sup.TestEntity
    implements sup.TestEntity {
  /// refClassName
  @override
  String get refClassName => 'i112dorm_lib_src_test_test_entity';

  /// Public properties
  /// cyclicReference
  static const String CYCLICREFERENCE = 'cyclicReference';
  static const Symbol CYCLICREFERENCE_SYMBOL =
      #i112dorm_lib_src_test_test_entity_cyclicReference;

  final DormProxy<TestEntity> _cyclicReference =
      new DormProxy<TestEntity>(CYCLICREFERENCE, CYCLICREFERENCE_SYMBOL);
  @override
  TestEntity get cyclicReference => _cyclicReference.value;
  set cyclicReference(TestEntity value) {
    _cyclicReference.value = value;
  }

  /// date
  static const String DATE = 'date';
  static const Symbol DATE_SYMBOL = #i112dorm_lib_src_test_test_entity_date;

  final DormProxy<DateTime> _date = new DormProxy<DateTime>(DATE, DATE_SYMBOL);
  @override
  DateTime get date => _date.value;
  set date(DateTime value) {
    _date.value = value;
  }

  /// name
  static const String NAME = 'name';
  static const Symbol NAME_SYMBOL = #i112dorm_lib_src_test_test_entity_name;

  final DormProxy<String> _name = new DormProxy<String>(NAME, NAME_SYMBOL);
  @override
  String get name => _name.value;
  set name(String value) {
    _name.value = value;
  }

  /// DO_SCAN
  static void DO_SCAN /**/ ([String _R, Entity _C()]) {
    _R ??= 'i112dorm_lib_src_test_test_entity';
    _C ??= () => new TestEntity();
    TestEntitySuperClass.DO_SCAN(_R, _C);
    Entity.ASSEMBLER.scan(_R, _C, const <PropertyData>[
      const PropertyData(
          symbol: TestEntity.CYCLICREFERENCE_SYMBOL,
          name: 'cyclicReference',
          type: TestEntity,
          metatags: const <dynamic>[]),
      const PropertyData(
          symbol: TestEntity.DATE_SYMBOL,
          name: 'date',
          type: DateTime,
          metatags: const <dynamic>[]),
      const PropertyData(
          symbol: TestEntity.NAME_SYMBOL,
          name: 'name',
          type: String,
          metatags: const <dynamic>[
            const LabelField(),
          ]),
    ]);
  }

  /// Ctr
  TestEntity() : super() {
    Entity.ASSEMBLER.registerProxies(
        this, <DormProxy<dynamic>>[_cyclicReference, _date, _name]);
  }
  static TestEntity /**/ construct /**/ () => new TestEntity();
}
