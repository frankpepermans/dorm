part of item_renderers;

class EmployeeIdItemRenderer extends LabelItemRenderer {

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

  EmployeeIdItemRenderer({String elementId: null}) : super(elementId: null);

  static EmployeeIdItemRenderer construct() {
    return new EmployeeIdItemRenderer();
  }
}