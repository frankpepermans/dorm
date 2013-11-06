import 'dart:async';
import 'dart:html';

import 'package:dart_flex/dart_flex.dart';
import 'package:dorm/dorm.dart';
import 'package:observe/observe.dart';

import 'item_renderers/item_renderers.dart';
import 'orm_domain/orm_domain.dart';
import 'orm_infrastructure/orm_infrastructure.dart';

final String url = '127.0.0.1';
final String port = '8080';
final Serializer serializer = new SerializerJson<String>();

FetchService fetchService;
CommitService commitService;
FetchService postCommitFetchService;

ConflictManager handleConflictAcceptClient(Entity serverEntity, Entity clientEntity) {
  return ConflictManager.ACCEPT_CLIENT;
}

ConflictManager handleConflictAcceptServer(Entity serverEntity, Entity clientEntity) {
  return ConflictManager.ACCEPT_SERVER;
}

void main() {
  // !!! MAKE SURE TO START THE DART SERVER, RUN run_mock_server.dart !!!
  
  // make sure to add this call,
  // it will run reflection on the client-side entities
  ormInitialize();
  
  /*serializer.addRule(
    String,
    (String value) => 'testIn',
    (String value) => 'testOut'
  );*/
  
  init();
  //benchmark();
}

void benchmark() {
  fetchService = new FetchService(url, port, serializer, handleConflictAcceptClient);
  
  fetchService.ormEntityLoad('Employee').then(
      (ObservableList<Entity> resultList) {
        window.animationFrame.whenComplete(benchmark);
      }
  );
}

void init() {
  fetchService = new FetchService(url, port, serializer, handleConflictAcceptClient);
  commitService = new CommitService(url, port, serializer, handleConflictAcceptServer);
  postCommitFetchService = new FetchService(url, port, serializer, handleConflictAcceptServer);
  
  fetchService.ormEntityLoad('Employee').then(
      (ObservableList<Entity> resultList) {
        DartFlexRootContainer rootContainer = new DartFlexRootContainer(elementId: '#dynamic_content')
        ..layout=new VerticalLayout();
        
        HGroup header = new HGroup()
        ..percentWidth=100.0
        ..height=30;
        
        Button commitButton = new Button()
        ..width=120
        ..height=30
        ..label='COMMIT';
        
        RichText commitResultText = new RichText()
        ..percentWidth=100.0
        ..height=20;
        
        DataGrid grid = new DataGrid()
        ..percentWidth=100.0
        ..height=520
        ..headerHeight=40
        ..rowHeight=60
        ..columnSpacing=0
        ..rowSpacing=0
        ..columns = new ObservableList.from(
                  [
                     new DataGridColumn()
                     ..width = 80
                     ..headerData = const HeaderData(Person.ID_SYMBOL, 'id', 'person id')
                     ..field = Person.ID_SYMBOL
                     ..headerItemRendererFactory = new ClassFactory(constructorMethod: HeaderItemRenderer.construct)
                     ..columnItemRendererFactory = new ClassFactory(constructorMethod: LabelItemRenderer.construct),

                     new DataGridColumn()
                     ..width=280
                     ..headerData = const HeaderData(Person.NAME_SYMBOL, 'name', 'person name')
                     ..field = Person.NAME_SYMBOL
                     ..headerItemRendererFactory = new ClassFactory(constructorMethod: HeaderItemRenderer.construct)
                     ..columnItemRendererFactory = new ClassFactory(constructorMethod: EditableLabelItemRenderer.construct),

                     new DataGridColumn()
                     ..width=280
                     ..headerData = const HeaderData(Employee.JOB_SYMBOL, 'job', 'person job')
                     ..field = Employee.JOB_SYMBOL
                     ..headerItemRendererFactory = new ClassFactory(constructorMethod: HeaderItemRenderer.construct)
                     ..columnItemRendererFactory = new ClassFactory(constructorMethod: DropdownItemRenderer.construct),
                     
                     new DataGridColumn()
                     ..percentWidth=100.0
                     ..headerData = const HeaderData(Employee.JOB_SYMBOL, 'job cyclic', 'person job cyclic')
                     ..field = Employee.JOB_SYMBOL
                     ..headerItemRendererFactory = new ClassFactory(constructorMethod: HeaderItemRenderer.construct)
                     ..columnItemRendererFactory = new ClassFactory(constructorMethod: RelatedEmployeesItemRenderer.construct)
            ]
        )
        ..dataProvider = resultList;
        
        commitButton.observeEventType(
            'buttonClick', 
            (FrameworkEvent event) {
              DormManager dormManager = new DormManager();
              
              resultList.forEach(
                (Entity entity) => dormManager.queue(entity)
              );
              
              DormManagerCommitStructure structure = dormManager.getCommitStructure();
              
              commitService.flush(structure.dataToCommit, structure.dataToDelete).then(
                  (List<Entity> response) {
                    commitResultText.text = 'commit completed!';
                    
                    postCommitFetchService.ormEntityLoad('Job');
                    
                    Timer timer = new Timer(
                        const Duration(seconds: 10),
                        () => commitResultText.text = ''
                    );
                  }
              );
            }
        );
        
        header.addComponent(commitButton);
        header.addComponent(commitResultText);
        
        rootContainer.addComponent(header);
        rootContainer.addComponent(grid);
      }
  );
}
  /*
  // loading data can be done through 2 library-level methods
  
  // EXAMPLE 1: you can load an entity by primary key...
  ormEntityLoadByPK('Job', 1, onConflict:handleConflictAcceptClient).then(
    (Job job) => print('A Job is loaded! The job is called: ${job.name}')
  );
  
  // EXAMPLE 2: or load a list of entities...
  ormEntityLoad('Job', onConflict:handleConflictAcceptClient).then(
      (List<Entity> resultList) {
        print('All jobs are now loaded!');
        resultList.forEach(
            (Job job) => print('-> The job is called: ${job.name}')
        );
      }
  );
  
  // EXAMPLE 3: you can also add a 'where' clause to the list loader...
  // the where clause must be a Map...
  Map<String, dynamic> whereMap1 = new Map<String, dynamic>();
  
  // in this map, we add the fields to filter upon...
  whereMap1[Job.NAME] = 'Managing director';
  // add extra fields where needed
  
  ormEntityLoad('Job', where:whereMap1, onConflict:handleConflictAcceptClient).then(
      (List<Entity> resultList) {
        print('A filtered job list is now loaded');
        resultList.forEach(
            (Job job) => print('-> The job is called: ${job.name}')
        );
      }
  );
  
  // entities can have other entities as properties, or lists of entities
  // let's load an employee. An employee has a job property, and this job property in its turn, has an employees list, 
  // this list contains all employees that have this job
  
  Map<String, dynamic> whereMap2 = new Map<String, dynamic>();
  
  // Note that 'Employee' extends 'Person',
  // Employee adds one extra property, job
  // the other properties are in the parenting class Person
  // So for the where clause by name, we target Person.NAME
  
  whereMap2[Person.NAME] = 'Jane Austin';
  
  ormEntityLoad('Employee', where:whereMap2, onConflict:handleConflictAcceptClient).then(
      (List<Entity> resultList) {
        resultList.forEach(
            (Employee employee) {
              print('Employee ${employee.name} is now loaded');
              
              employee.job.employees.forEach(
                (Employee employeeWhoHasSameJob) => print('This employee is also a ${employee.job.name}: ${employeeWhoHasSameJob.name}')    
              );
            }
        );
      }
  );
  
  // Conflicts can occur when a client-side entity is out of sync with an incoming server-side entity
  // for example, you load a job, change the job name and then decide to reload the same job from the server
  // at this point, they are out of sync, because the client has an uncommitted update.
  // to handle such a conflict, you can set the onConflict argument,
  // the value should be a Function, which will be run in case of a detected conflict
  
  // we start by loading a specific job :
  ormEntityLoadByPK('Job', 1, onConflict:handleConflictAcceptServer).then(
    (Job job) {
      // then change the name
      job.name = 'a new job name here';
      
      // finally, reload the same job, and choose to accept the server version
      ormEntityLoadByPK('Job', 1, onConflict:handleConflictAcceptServer).then(
          (Job jobReloaded) => print(jobReloaded.name)
      );
    }
  );
  
  ormEntityLoadByPK('Job', 1, onConflict:handleConflictAcceptClient).then(
      (Job job) {
        Map<String, dynamic> whereClause = new Map<String, dynamic>();
        
        whereClause[Employee.JOB] = job;
        whereClause[Person.NAME] = 'Martin Svensson';
        
        ormEntityLoad('Employee', onConflict:handleConflictAcceptClient, where:whereClause).then(
            (List<Entity> resultList) {
              resultList.forEach(
                  (Employee employee) => print('${employee.name} ${employee.job.name}')
              );
            }
        );
        
        job.name = 'Chief Executable Officer';
        
        dormManager.queue(job);
        
        commitService.flush(dormManager).then(
            (_) => print('flushed!')
        );
      }
  );
  
  
  ormEntityLoad('Job', onConflict:handleConflictAcceptClient).then(
      (List<Entity> resultList) {
        resultList.forEach(
            (Job job) => print('${job.name} has ${(job.employees != null) ? job.employees.length : 0} registered employees')
        );
      }
  );
  
  ormEntityLoadByPK('User', 1, onConflict:handleConflictAcceptClient).then(
      (User user) => print('${user.id} ${user.name}')
  );*/
