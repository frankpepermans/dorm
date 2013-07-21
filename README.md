Dorm
===========

Dorm is a client side library, it can he hooked up to a server side [ORM] implementation such as [Hibernate] for example.
The idea behind Dorm is that you expose your [ORM] entity model (or a subset of it) to your client application
and load and/or commit entities asynchronously via services.

Dorm supports :
- cyclic references (i.e. foo.bar.listOfFoos) via pointers
- default serializer for JSON data
- Entities use the [observe] library, an [Entity] extends ObservableBase, and an [Entity] collection is an ObservableList

Dorm will soon support :
- lazy loading
- push via web sockets, share [Entity] status between clients

[![Build Status](https://drone.io/github.com/frankpepermans/dorm/status.png)](https://drone.io/github.com/frankpepermans/dorm/latest)

Try It Now
-----------
Add the Dorm package to your pubspec.yaml file:

```yaml
dependencies:
  dorm: any
```

Setting it up
----------
The [example] in Dorm requires a Dart [server] which acts as a minimal ORM engine, running on JSON files.
Here, you can define your database in the dbo folder using JSON.

The [example] is a good starting point for implementing Dorm yourself,
it also has a few sample services and even a commit service.

When ready, run 'build_entities.dart' which will generate the client side entities needed in the dorm example.

Finally, run 'run_mock_server.dart' to launch the test server.

Now you can launch the 'dorm.dart' file in the main examples folder.

I've successfully hooked Dorm up with an existing Hibernate ORM,
if you wish to do the same, then you must provide 2 things on the server :

- a way to generate Dorm entities as in the example JSON test server, from your ORM engine
- a serializer which supports cyclic references, Dorm can then access your webserver and request the JSON data

Generating Dorm entities
----------
Dorm entities support inheritance.

Dorm entities use a proxy,
you should generate [Entity] properties in the following way:

```
	@Property(BAR_SYMBOL, 'bar', int)
	@Id()
	@NotNullable()
	@DefaultValue(0)
	@Immutable()
	DormProxy<int> _bar;

	static const String BAR = 'bar';
	static const Symbol BAR_SYMBOL = const Symbol('orm_domain.Foo.bar');

	int get bar => _bar.value;
	set bar(int value) => _bar.value = notifyPropertyChange(BAR_SYMBOL, _bar.value, value);
```

Then, in the [Entity] constructor body, you need to register this property as following:

```
	EntityAssembler assembler = new EntityAssembler();
	
	_bar = new DormProxy()
	..property = 'bar'
	..propertySymbol = BAR_SYMBOL;

	assembler.registerProxies(this, <DormProxy>[_bar]);
```

See [Person] for a full example of a Dorm entity.

Finally, you must also define a library file which contains all your generated entities,

with this file, generate the following method:

```
void ormInitialize() {
	EntityAssembler assembler = new EntityAssembler();

	assembler.scan(Foo, 'entities.foo', Foo.construct);
	//...
}
```

And in your project main(), call this method to initialize Dorm.

Serialization
----------
By default, Dorm uses a JSON serializer, but you could write your own serializer to support [AMF] for example.

Your client services must use the serializer when dealing with incoming/outgoing data,
here's an example of a service's body:

```
	final Serializer serializer = new SerializerJson<String>();
	
	Future serviceMethodNameHere(String operation, Map<String, dynamic> arguments) {
		Completer completer = new Completer();
		
		HttpRequest.request(
			'http://${host}:$port', 
			method:operation, 
			sendData:serializer.outgoing(arguments) // serialize your arguments to JSON
		).then(
			(HttpRequest request) {
			  if (request.responseText.length > 0) {
				EntityFactory<Entity> factory = new EntityFactory(onConflict);
				
				List<Map<String, dynamic>> result = serializer.incoming(request.responseText); // parses the incomin JSON data to a Map
				
				ObservableList<Entity> spawned = factory.spawn(result, serializer); // generates your entities from the above Map
				
				completer.complete(isUniqueResult ? spawned.first : spawned);
			  }
			}
		);
		
		return completer.future;
	}
```

The JSON serializer only handles the basic data types (numerics, String, basic Lists and Maps, ...)
To support other types, you can set type handlers to the serializer as following :

```
	serializer.addRule(
      DateTime,
      (int value) => (value != null) ? new DateTime.fromMillisecondsSinceEpoch(value, isUtc:true) : null,
      (DateTime value) => value.millisecondsSinceEpoch
	);
```

This rule will read the date as int value from the incoming JSON data,
and send out again the date as an int whenever the data is outgoing.

When Dorm submits changes to its entities, only properties that are dirty (changed on the client) will be serialized.

Serialization rules
----------
Dorm needs to understand the serialized JSON when it comes to cyclic references,
one way for the server to support this, is by creating [DTO]'s for your entities,
then when the serialization is needed, loop over the [DTO](s) and in doing so,
keep a reference to the entities that are already serialized.

If a cyclic reference is detected, then instead of serializing the [DTO] values, do this instead:
```
	{
		"?t":"path.to.entities.Foo", // the entity type, including the class path
		"?p":true, // indicates that this is a cyclic reference
		"foo_id":1 // primary key name and value
	}
```

[ORM]: https://en.wikipedia.org/wiki/Object-relational_mapping
[Hibernate]: http://en.wikipedia.org/wiki/Hibernate_(Java)
[server]: https://github.com/frankpepermans/dorm_mockserver
[observe]: https://github.com/dart-lang/web-ui/blob/master/lib/observe/observable.dart
[Entity]: https://github.com/frankpepermans/dorm/blob/master/lib/src/domain/entity.dart
[Person]: https://github.com/frankpepermans/dorm/blob/master/example/orm_domain/person.dart
[AMF]: http://en.wikipedia.org/wiki/Action_Message_Format
[DTO]: http://en.wikipedia.org/wiki/Data_transfer_object
[example]: https://github.com/frankpepermans/dorm/tree/master/example
