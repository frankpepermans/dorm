// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: CodeGenerator
// Target: abstract class AnotherTestEntity
// **************************************************************************

import 'package:dorm/dorm.dart';
import 'package:dorm/src/test/test_entity.g.dart';
import 'package:dorm/src/test/test_entity_super.g.dart';

import 'another_test_entity.dart' as sup;

class AnotherTestEntity extends TestEntitySuperClass
    with sup.AnotherTestEntity {
  /// refClassName
  @override
  String get refClassName => 'i112dorm_lib_src_test_another_test_entity';

  /// Public properties
  /// anotherName
  static const String ANOTHERNAME = 'anotherName';
  static const Symbol ANOTHERNAME_SYMBOL =
      #i112dorm_lib_src_test_another_test_entity_anotherName;

  final DormProxy<String> _anotherName =
      new DormProxy<String>(ANOTHERNAME, ANOTHERNAME_SYMBOL);
  @override
  String get anotherName => _anotherName.value;
  set anotherName(String value) {
    _anotherName.value = value;
  }

  /// cyclicReference
  static const String CYCLICREFERENCE = 'cyclicReference';
  static const Symbol CYCLICREFERENCE_SYMBOL =
      #i112dorm_lib_src_test_another_test_entity_cyclicReference;

  final DormProxy<TestEntity> _cyclicReference =
      new DormProxy<TestEntity>(CYCLICREFERENCE, CYCLICREFERENCE_SYMBOL);
  @override
  TestEntity get cyclicReference => _cyclicReference.value;
  set cyclicReference(TestEntity value) {
    _cyclicReference.value = value;
  }

  /// date
  static const String DATE = 'date';
  static const Symbol DATE_SYMBOL =
      #i112dorm_lib_src_test_another_test_entity_date;

  final DormProxy<DateTime> _date = new DormProxy<DateTime>(DATE, DATE_SYMBOL);
  @override
  DateTime get date => _date.value;
  set date(DateTime value) {
    _date.value = value;
  }

  /// DO_SCAN
  static void DO_SCAN /**/ ([String _R, Entity _C()]) {
    _R ??= 'i112dorm_lib_src_test_another_test_entity';
    _C ??= () => new AnotherTestEntity();
    TestEntitySuperClass.DO_SCAN(_R, _C);
    Entity.ASSEMBLER.scan(_R, _C, const <PropertyData>[
      const PropertyData(
          symbol: AnotherTestEntity.ANOTHERNAME_SYMBOL,
          name: 'anotherName',
          type: String,
          metatags: const <dynamic>[
            const LabelField(),
          ]),
      const PropertyData(
          symbol: AnotherTestEntity.CYCLICREFERENCE_SYMBOL,
          name: 'cyclicReference',
          type: TestEntity,
          metatags: const <dynamic>[]),
      const PropertyData(
          symbol: AnotherTestEntity.DATE_SYMBOL,
          name: 'date',
          type: DateTime,
          metatags: const <dynamic>[]),
    ]);
  }

  /// Ctr
  AnotherTestEntity() : super() {
    Entity.ASSEMBLER.registerProxies(
        this, <DormProxy<dynamic>>[_anotherName, _cyclicReference, _date]);
  }
  static AnotherTestEntity /**/ construct /**/ () => new AnotherTestEntity();
}
