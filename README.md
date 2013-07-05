
<html>

<head>
<meta http-equiv=Content-Type content="text/html; charset=windows-1252">
<meta name=Generator content="Microsoft Word 15 (filtered)">
</head>

<body lang=EN-GB link="#0563C1" vlink="#954F72">

<div class=WordSection1>

<p class=Publishwithline>Dorm, an orm client for Dart</p>

<div style='border:none;border-bottom:solid #C6C6C6 1.0pt;padding:0cm 0cm 2.0pt 0cm'>

<p class=underline>&nbsp;</p>

</div>

<p class=PadderBetweenControlandBody>&nbsp;</p>

<p class=MsoListParagraph style='text-indent:-18.0pt'><b>1.<span
style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </span></b><b>Introduction</b></p>

<p class=MsoNormal style='margin-left:18.0pt'>Dorm stands for Dart ORM,</p>

<p class=MsoNormal style='margin-left:18.0pt'><a
href="https://en.wikipedia.org/wiki/Object-relational_mapping">Object-Relational-Mapping</a>
is a popular (mostly server) based solution to abstract the database model to a
virtual entity object model. (see <a
href="http://en.wikipedia.org/wiki/Hibernate_(Java)">Hibernate</a> or <a
href="http://en.wikipedia.org/wiki/Entity_Framework">EntityFramework</a> for
example)</p>

<p class=MsoNormal style='margin-left:18.0pt'>Table values are loaded into
virtual entities that can be readily used from within the targeted programming
language.</p>

<p class=MsoNormal style='margin-left:18.0pt'>What Dorm does, is create a way
of exporting these objects to the client. On the client, entities can be loaded,
created, deleted or manipulated and in the end be sent back to the server to
finalize the changes to the database itself. To make this work, the dorm client
must ensure that each loaded entity maps 1-to-1 with its server counterpart
(i.e. there can be no duplicates of the same entity on the client, only
pointers to a single unique instance).</p>

<p class=MsoNormal style='margin-left:18.0pt'>The programmer shouldn’t need to
worry about this relationship, and rather just load up his entities through a
simple API.</p>

<p class=MsoListParagraph style='text-indent:-18.0pt'><b>2.<span
style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </span></b><b>No
client-ORM without a server counterpart!</b></p>

<p class=MsoNormal style='margin-left:18.0pt'>Dorm should in the long run be
compatible with any server-side ORM solution, to provide this, specific
adapters need to be written to ensure communication between dorm and the
server.</p>

<p class=MsoNormal style='margin-left:18.0pt'>In this early stage, Dorm talks
to a Dart (mock) server. This server has no real database, instead it presents
tables in JSON format.</p>

<p class=MsoNormal style='margin-left:18.0pt'>In the package, you’ll find a server
implementation with 2 runnable Dart files :</p>

<p class=MsoListParagraphCxSpFirst style='text-indent:-18.0pt'>-<span
style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>build_entities.dart : Will dynamically create Entities for use on the
Dorm client, based on the entity definition files from the mock server</p>

<p class=MsoListParagraphCxSpLast style='text-indent:-18.0pt'>-<span
style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>run_mock_server.dart : Launches a Dart server (default localhost) to
which Dorm can connect and transfer entities with</p>

<p class=MsoNormal style='margin-left:18.0pt'>The mock server already has a
demo table structure in JSON format, here’s what it looks like :</p>

<p class=MsoNormal style='margin-left:18.0pt'><img border=0 width=903
height=575 id="Picture 1" src="http://www.igindo.com/dart/server_tables.jpg"></p>

<p class=MsoNormal style='margin-left:18.0pt'>Also found with the server, are a
number of server-side ORM entities, these are also written in JSON format and
define the following structure :</p>

<p class=MsoNormal style='margin-left:18.0pt'><img border=0 width=903
height=575 id="Picture 2" src="http://www.igindo.com/dart/server_entities.jpg"></p>

<p class=MsoNormal style='margin-left:18.0pt'>ORM entities support inheritance,</p>

<p class=MsoNormal style='margin-left:18.0pt'>There are 2 base entities,
MutableEntity and ImmutableEntity.</p>

<p class=MsoNormal style='margin-left:18.0pt'>The first one is persistable,
while the second one is read-only.</p>

<p class=MsoNormal style='margin-left:18.0pt'>Note how Employee also extends
Person, in general, an Employee is a Person, but adds one property, namely job.</p>

<p class=MsoNormal style='margin-left:18.0pt'>Finally, run build_entities.dart
to create client-side Dorm entities based on this model.</p>

<p class=MsoListParagraph style='text-indent:-18.0pt'><b>3.<span
style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </span></b><b>Annotations</b></p>

<p class=MsoNormal style='margin-left:18.0pt'>Entities and properties can be
annotated with different tags, here’s a list of the currently supported ones :</p>

<p class=MsoListParagraphCxSpFirst style='text-indent:-18.0pt'>-<span
style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>Ref(String name) : Entity class level, holds the reference to the
server-entity counterpart (e.g. Ref(‘entities.employee’))</p>

<p class=MsoListParagraphCxSpMiddle style='text-indent:-18.0pt'>-<span
style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>Property(String name) : Declares a property within the entity. Each
property is managed via a Proxy class, this Proxy class acts behind the scenes
for Dorm.</p>

<p class=MsoListParagraphCxSpMiddle style='text-indent:-18.0pt'>-<span
style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>Immutable() : Entity class level or property level, indicates that the
class or property is read-only, trying to change a value or this class or
property, will result in a generated runtime error.</p>

<p class=MsoListParagraphCxSpMiddle style='text-indent:-18.0pt'>-<span
style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>Id() : Property level, indicates that a property is an identifier</p>

<p class=MsoListParagraphCxSpMiddle style='text-indent:-18.0pt'>-<span
style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>NotNullable() : Property level, dictates that a property cannot be NULL</p>

<p class=MsoListParagraphCxSpMiddle style='text-indent:-18.0pt'>-<span
style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>DefaultValue(dynamic value) : Property level, defines the default value
of the property, as stated in the server-side entity file</p>

<p class=MsoListParagraphCxSpLast style='text-indent:-18.0pt'>-<span
style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>Transient : Property level, indicates that this property can be ignored
by Dorm, for example, changing the property value will not cause an update on
the server</p>

<p class=MsoNormal style='margin-left:18.0pt'>Here’s an example of a Dorm
generated file on the client :</p>

<p class=MsoNormal style='margin-left:18.0pt'><img border=0 width=756
height=829 id="Picture 3" src="http://www.igindo.com/dart/entity_example.jpg"></p>

<p class=MsoListParagraph style='text-indent:-18.0pt'><b>4.<span
style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </span></b><b>Dorm
client methods</b></p>

<p class=MsoNormal style='margin-left:18.0pt'>Use the following methods in the
Dorm client to work with the entities.</p>

<p class=MsoNormal style='margin-left:18.0pt'>Obviously, import the library as
following: <b><span style='font-size:10.0pt;font-family:"Courier New";
color:#7F0055'>import</span></b><span style='font-size:10.0pt;font-family:"Courier New";
color:black'> </span><span style='font-size:10.0pt;font-family:"Courier New";
color:#2D24FB'>'package:dorm/dorm.dart'</span><span style='font-size:10.0pt;
font-family:"Courier New";color:black'>;</span></p>

<p class=MsoNormal style='margin-left:18.0pt'>And also import your generated
client domain:<b><span style='font-size:10.0pt;font-family:"Courier New";
color:#7F0055'> import</span></b><span style='font-size:10.0pt;font-family:
"Courier New";color:black'> </span><span style='font-size:10.0pt;font-family:
"Courier New";color:#2D24FB'>'orm_domain/orm_domain.dart'</span><span
style='font-size:10.0pt;font-family:"Courier New";color:black'>;</span></p>

<p class=MsoNormal style='margin-left:18.0pt'>Then, before doing anything else,
initialize Dorm by calling ormInitialize();</p>

<p class=MsoNormal style='margin-left:18.0pt'>If you want, you can also create
an instance of DormManager, whenever you need to persist changes to entities,
hand them to this manager via the queue() or queueDeleted() methods, and in the
end call the flush() method.</p>

<p class=MsoNormal style='margin-left:18.0pt'>Now the 2 main methods,
ormEntityLoad() and ormEntityLoadByPK() can be used to request entities. The
first method will always load a collection, and the second one a unique entity.</p>

<p class=MsoListParagraphCxSpFirst style='text-indent:-18.0pt'>-<span
style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>Call ormEntityLoad(‘Employee’) for example to load all employees</p>

<p class=MsoListParagraphCxSpMiddle style='text-indent:-18.0pt'>-<span
style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>Call ormEntityLoad(‘Employee’, where:Map) to filter your collection</p>

<p class=MsoListParagraphCxSpLast style='text-indent:-18.0pt'>-<span
style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>Call ormEntityLoadByPK(‘Employee’, 1) to load the Employee with identity
1</p>

<p class=MsoNormal style='margin-left:18.0pt'>Both methods will return a
Future, either Future&lt;List&lt;Entity&gt;&gt; for collections, or
Future&lt;Entity&gt; for unique requests.</p>

<p class=MsoListParagraph style='text-indent:-18.0pt'><b>5.<span
style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </span></b><b>Conflict
management</b></p>

<p class=MsoNormal style='margin-left:18.0pt'>Conflict management is needed
when client and server entities go out of sync, imagine you first load an
entity to the client, change a property, but then re-request that same entity.</p>

<p class=MsoNormal style='margin-left:18.0pt'>At this point, you must decide
which version to proceed with, either your client-side updated one, or the
server-side old one.</p>

<p class=MsoNormal style='margin-left:18.0pt'>To tackle this, you can add an
onConflict function to ormEntityLoad() or  ormEntityLoadByPK(). This method
will run every time a conflict like the above occurs. This method typically
looks like this :</p>

<p class=MsoNormal style='margin-bottom:0cm;margin-bottom:.0001pt;text-indent:
18.0pt;text-autospace:none'><span style='font-size:10.0pt;font-family:"Courier New";
color:black'>ConflictManager </span><span style='font-size:10.0pt;font-family:
"Courier New";color:#404040'>handleConflictAcceptClient</span><span
style='font-size:10.0pt;font-family:"Courier New";color:black'>(Entity
serverEntity, Entity clientEntity) {</span></p>

<p class=MsoNormal style='margin-bottom:0cm;margin-bottom:.0001pt;text-autospace:
none'><span style='font-size:10.0pt;font-family:"Courier New";color:black'>      </span><b><span
style='font-size:10.0pt;font-family:"Courier New";color:#7E0854'>return</span></b><span
style='font-size:10.0pt;font-family:"Courier New";color:black'> ConflictManager.</span><i><span
style='font-size:10.0pt;font-family:"Courier New";color:#0000C0'>ACCEPT_CLIENT</span></i><span
style='font-size:10.0pt;font-family:"Courier New";color:black'>;</span></p>

<p class=MsoNormal style='margin-left:18.0pt'><span style='font-size:10.0pt;
font-family:"Courier New";color:black'>}</span></p>

<p class=MsoNormal style='margin-left:18.0pt'>The example simply always returns
to accept the current client version of the entity. You could add complexity by
choosing to return the server version based on the entity type for example.</p>

<p class=MsoNormal style='margin-left:18.0pt'>&nbsp;</p>

<p class=MsoNormal style='margin-left:18.0pt'>You can find some examples of the
above within the web folder (dorm.dart), output is console based.</p>

<p class=MsoNormal style='margin-left:18.0pt'>Make sure to start up the Dart
server before running the client application!</p>

<p class=MsoNormal style='margin-left:18.0pt'>And finally, look for the package
<a href="https://github.com/frankpepermans/dorm">here on GitHub</a>.</p>

</div>

</body>

</html>
