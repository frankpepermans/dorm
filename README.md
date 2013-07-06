Dorm, an orm client for Dart
 
 

1.       Introduction

Dorm stands for Dart ORM,

Object-Relational-Mapping is a popular (mostly server) based solution to abstract the database model to a virtual entity object model. (see Hibernate or EntityFramework for example)

Table values are loaded into virtual entities that can be readily used from within the targeted programming language.

What Dorm does, is create a way of exporting these objects to the client. On the client, entities can be loaded, created, deleted or manipulated and in the end be sent back to the server to finalize the changes to the database itself. To make this work, the dorm client must ensure that each loaded entity maps 1-to-1 with its server counterpart (i.e. there can be no duplicates of the same entity on the client, only pointers to a single unique instance).

The programmer shouldn’t need to worry about this relationship, and rather just load up his entities through a simple API.

2.       No client-ORM without a server counterpart!

Dorm should in the long run be compatible with any server-side ORM solution, to provide this, specific adapters need to be written to ensure communication between dorm and the server.

In this early stage, Dorm talks to a Dart (mock) server. This server has no real database, instead it presents tables in JSON format.

In the package, you’ll find a server implementation with 2 runnable Dart files :

-          build_entities.dart : Will dynamically create Entities for use on the Dorm client, based on the entity definition files from the mock server
-          run_mock_server.dart : Launches a Dart server (default localhost) to which Dorm can connect and transfer entities with

The mock server already has a demo table structure in JSON format, here’s what it looks like :



Also found with the server, are a number of server-side ORM entities, these are also written in JSON format and define the following structure :



ORM entities support inheritance,

There are 2 base entities, MutableEntity and ImmutableEntity.

The first one is persistable, while the second one is read-only.

Note how Employee also extends Person, in general, an Employee is a Person, but adds one property, namely job.

Finally, run build_entities.dart to create client-side Dorm entities based on this model.

3.       Annotations

Entities and properties can be annotated with different tags, here’s a list of the currently supported ones :

-          Ref(String name) : Entity class level, holds the reference to the server-entity counterpart (e.g. Ref(‘entities.employee’))
-          Property(String name) : Declares a property within the entity. Each property is managed via a Proxy class, this Proxy class acts behind the scenes for Dorm.
-          Immutable() : Entity class level or property level, indicates that the class or property is read-only, trying to change a value or this class or property, will result in a generated runtime error.
-          Id() : Property level, indicates that a property is an identifier
-          NotNullable() : Property level, dictates that a property cannot be NULL
-          DefaultValue(dynamic value) : Property level, defines the default value of the property, as stated in the server-side entity file
-          Transient : Property level, indicates that this property can be ignored by Dorm, for example, changing the property value will not cause an update on the server

Here’s an example of a Dorm generated file on the client :



4.       Dorm client methods

Use the following methods in the Dorm client to work with the entities.

Obviously, import the library as following: import 'package:dorm/dorm.dart';

And also import your generated client domain: import 'orm_domain/orm_domain.dart';

Then, before doing anything else, initialize Dorm by calling ormInitialize();

If you want, you can also create an instance of DormManager, whenever you need to persist changes to entities, hand them to this manager via the queue() or queueDeleted() methods, and in the end call the flush() method.

Now the 2 main methods, ormEntityLoad() and ormEntityLoadByPK() can be used to request entities. The first method will always load a collection, and the second one a unique entity.

-          Call ormEntityLoad(‘Employee’) for example to load all employees
-          Call ormEntityLoad(‘Employee’, where:Map) to filter your collection
-          Call ormEntityLoadByPK(‘Employee’, 1) to load the Employee with identity 1

Both methods will return a Future, either Future<List<Entity>> for collections, or Future<Entity> for unique requests.

5.       Conflict management

Conflict management is needed when client and server entities go out of sync, imagine you first load an entity to the client, change a property, but then re-request that same entity.

At this point, you must decide which version to proceed with, either your client-side updated one, or the server-side old one.

To tackle this, you can add an onConflict function to ormEntityLoad() or  ormEntityLoadByPK(). This method will run every time a conflict like the above occurs. This method typically looks like this :

ConflictManager handleConflictAcceptClient(Entity serverEntity, Entity clientEntity) {
      return ConflictManager.ACCEPT_CLIENT;
}

The example simply always returns to accept the current client version of the entity. You could add complexity by choosing to return the server version based on the entity type for example.

 

You can find some examples of the above within the web folder (dorm.dart), output is console based.

Make sure to start up the Dart server before running the client application!

And finally, look for the package here on GitHub.