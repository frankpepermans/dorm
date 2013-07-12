library dorm;

import 'dart:async';
import 'dart:mirrors';
import 'dart:core';
import 'dart:html';
import 'dart:json';

import 'package:observe/observe.dart';

part 'src/core/conflict_manager.dart';
part 'src/core/dorm_error.dart';
part 'src/core/entity_manager.dart';
part 'src/core/entity_factory.dart';
part 'src/core/dorm_manager.dart';
part 'src/core/entity_scan.dart';

part 'src/domain/entity.dart';
part 'src/domain/meta.dart';

part 'src/net/service_base.dart';

part 'src/serialization/externalizable.dart';
part 'src/serialization/serialization_type.dart';
part 'src/serialization/serializer.dart';
part 'src/serialization/serializer_json.dart';

part 'src/types/types.dart';

typedef ConflictManager OnConflictFunction(Entity serverEntity, Entity clientEntity);