part of orm_domain;@Ref('entities.employee')class Employee extends Person {	//---------------------------------	//	// Public properties	//	//---------------------------------	//---------------------------------	// refClassName	//---------------------------------	String get refClassName => 'entities.employee';	//---------------------------------	// job	//---------------------------------	@Property(JOB_SYMBOL, 'job', Job, 'Job')	static const String JOB = 'job';	static const Symbol JOB_SYMBOL = const Symbol('orm_domain.Employee.job');	Job job;	//---------------------------------	//	// Constructor	//	//---------------------------------	Employee() : super();	static Employee construct() => new Employee();}