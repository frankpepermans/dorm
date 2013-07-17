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
    if (value is Entity) {
      value.changes.listen(
        (_) => invalidateData() 
      );
    }
    
    super.data = value;
  }

  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------

  RelatedEmployeesItemRenderer({String elementId: null}) : super(elementId: null);

  static RelatedEmployeesItemRenderer construct() {
    return new RelatedEmployeesItemRenderer();
  }

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
      Job job = data[field];
      
      if (job != null) {
        job.employees.forEach(
          (Employee employee) {
            if (employee != data) {
              namesList.add(employee.name);
            }
          }
        );
        
        return namesList.join(', ');
      }
    }
    
    return '';
  }
}