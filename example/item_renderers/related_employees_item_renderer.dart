part of item_renderers;

class RelatedEmployeesItemRenderer extends LabelItemRenderer {

  //---------------------------------
  //
  // Protected properties
  //
  //---------------------------------

  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  //---------------------------------
  // data
  //---------------------------------

  set data(dynamic value) {
    super.data = value;
    
    if (
        (value != null) &&
        (value[field] is Job)
    ) {
      Job job = value[field];
      
      job.changes.listen((List<ChangeRecord> changes) => invalidateData());
    }
  }

  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------

  RelatedEmployeesItemRenderer({String elementId: null}) : super(elementId: null);

  static RelatedEmployeesItemRenderer construct() => new RelatedEmployeesItemRenderer();

  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  String itemToLabel() {
    if (
        (data != null) &&
        (field != null)
    ) {
      List<String> namesList = <String>[];
      final Job job = data[field];
      
      if (job != null) {
        job.employees.forEach(
          (Employee employee) {
            if (employee != data) namesList.add(employee.name);
          }
        );
        
        return namesList.join(', ');
      }
    }
    
    return '';
  }
}