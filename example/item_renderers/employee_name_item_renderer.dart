part of item_renderers;

class EmployeeNameItemRenderer extends EditableLabelItemRenderer {

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

  EmployeeNameItemRenderer({String elementId: null}) : super(elementId: null);

  static EmployeeNameItemRenderer construct() {
    return new EmployeeNameItemRenderer();
  }
}