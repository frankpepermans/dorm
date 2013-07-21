// Copyright (c) 2013, Frank Pepermans, Igindo BVBA

/**
 * *Warning*: this library is experimental, and APIs are subject to change.
 *
 * This library is to be used in conjunction with a server-side ORM implementation.
 * 
 * You can however acquire a small Dart test server,
 * which mimics a Hibernate server to fetch and commit to a JSON based database.
 * 
 * This test server can be found here: https://github.com/frankpepermans/dorm_mockserver
 *
 * For example:
 *      
 *     // Define a fetch service, this can hook up to an existing server-side webservice
 *     FetchService fetchService = new FetchService(url, port, serializer, handleConflictAcceptClient);
 *     
 *     // Define an entity in Dart, this will need to match with a server-side entity via a DTO
 *     // Classes like these can be easily generated on the server for the Dart client
 *     @Ref('entities.person')
 *     class Person extends MutableEntity {
 *      
 *      //---------------------------------
 *      //
 *      // Public properties
 *      //
 *      //---------------------------------
 *      
 *      //---------------------------------
 *      // refClassName
 *      //---------------------------------
 *     
 *      String get refClassName => 'entities.person';
 *     
 *      //---------------------------------
 *      // id
 *      //---------------------------------
 *     
 *      @Property(ID_SYMBOL, 'id')
 *      @Id()
 *      @NotNullable()
 *      @DefaultValue(0)
 *      @Immutable()
 *      DormProxy<int> _id;
 *      
 *      static const String ID = 'id';
 *      static const Symbol ID_SYMBOL = const Symbol('orm_domain.Person.id');
 *      
 *      int get id => _id.value;
 *      set id(int value) => _id.value = notifyPropertyChange(ID_SYMBOL, _id.value, value)
 *      
 *      //---------------------------------
 *      // name
 *      //---------------------------------
 *      
 *      @Property(NAME_SYMBOL, 'name')
 *      @LabelField()
 *      
 *      DormProxy<String> _name;
 *      
 *      static const String NAME = 'name';
 *      static const Symbol NAME_SYMBOL = const Symbol('orm_domain.Person.name');
 *      
 *      String get name => _name.value;
 *      set name(String value) => _name.value = notifyPropertyChange(NAME_SYMBOL, _name.value, value);
 *      
 *      //---------------------------------
 *      //
 *      // Constructor
 *      //
 *      //---------------------------------
 *      
 *      Person() : super() {
 *        EntityAssembler assembler = new EntityAssembler();
 *        
 *        _id = new DormProxy()
 *        ..property = 'id'
 *        ..propertySymbol = ID_SYMBOL;
 *        
 *        _name = new DormProxy()
 *        ..property = 'name'
 *        ..propertySymbol = NAME_SYMBOL;
 *        
 *        assembler.registerProxies(this, <DormProxy>[_id, _name]);
 *      }
 *      
 *      static Person construct() {
 *        return new Person();
 *      }
 *      
 *     }
 *
 *     main() {
 *      fetchService.ormEntityLoad('Person').then(
 *        (ObservableList resultList) {
 *          resultList.forEach(
 *            (Person person) => print(person.name);
 *          );
 *        }
 *      );
 *     }
 */
library dorm;

import 'dart:async';
import 'dart:core';
import 'dart:json';
import 'dart:html';
import 'dart:mirrors';

import 'package:observe/observe.dart';

part 'src/core/conflict_manager.dart';
part 'src/core/dorm_error.dart';
part 'src/core/entity_assembler.dart';
part 'src/core/entity_factory.dart';
part 'src/core/dorm_manager.dart';
part 'src/core/dorm_proxy.dart';
part 'src/core/entity_key.dart';
part 'src/core/entity_scan.dart';
part 'src/core/metadata_cache.dart';

part 'src/domain/entity.dart';
part 'src/domain/meta.dart';

part 'src/net/service_base.dart';

part 'src/serialization/externalizable.dart';
part 'src/serialization/serialization_type.dart';
part 'src/serialization/serializer.dart';
part 'src/serialization/serializer_json.dart';

typedef SerializerBase = Object with SerializerMixin;

typedef ConflictManager OnConflictFunction(Entity serverEntity, Entity clientEntity);