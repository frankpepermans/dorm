// Generated by build_entities.dart,// rerun this script if you have made changes// to the corresponding server-side Hibernate filepart of orm_domain;@Ref('entities.job')class Job extends MutableEntity {	//---------------------------------	//	// Public properties	//	//---------------------------------	//---------------------------------	// refClassName	//---------------------------------	String get refClassName => 'entities.job';	//---------------------------------	// id	//---------------------------------	@Property(ID_SYMBOL, 'id', int)	@Id(0)	@NotNullable()	@DefaultValue(0)	@Immutable()	static const String ID = 'id';	static const Symbol ID_SYMBOL = const Symbol('orm_domain.Job.id');	int id;	//---------------------------------	// name	//---------------------------------	@Property(NAME_SYMBOL, 'name', String)	@LabelField()	static const String NAME = 'name';	static const Symbol NAME_SYMBOL = const Symbol('orm_domain.Job.name');	String name;	//---------------------------------	// employees	//---------------------------------	@Property(EMPLOYEES_SYMBOL, 'employees', ObservableList)	@Lazy()	static const String EMPLOYEES = 'employees';	static const Symbol EMPLOYEES_SYMBOL = const Symbol('orm_domain.Job.employees');	ObservableList<Employee> employees;	//---------------------------------	//	// Constructor	//	//---------------------------------	Job() : super();	static Job construct() => new Job();}