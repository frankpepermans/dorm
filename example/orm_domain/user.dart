part of orm_domain;@Ref('entities.user')class User extends ImmutableEntity {	//---------------------------------	//	// Public properties	//	//---------------------------------	//---------------------------------	// refClassName	//---------------------------------	String get refClassName => 'entities.user';	//---------------------------------	// id	//---------------------------------	@Property(ID_SYMBOL, 'id', int, 'int')	@Id(0)	@NotNullable()	@Immutable()	static const String ID = 'id';	static const Symbol ID_SYMBOL = const Symbol('orm_domain.User.id');	int id;	//---------------------------------	// name	//---------------------------------	@Property(NAME_SYMBOL, 'name', String, 'String')	@LabelField()	static const String NAME = 'name';	static const Symbol NAME_SYMBOL = const Symbol('orm_domain.User.name');	String name;	//---------------------------------	//	// Constructor	//	//---------------------------------	User() : super();	static User construct() => new User();}