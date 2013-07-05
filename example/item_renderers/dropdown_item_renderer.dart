part of item_renderers;

class DropdownItemRenderer extends ItemRenderer {

  //---------------------------------
  //
  // Protected properties
  //
  //---------------------------------

  ComboBox _comboBox;
  
  static FetchService fetchService;
  static ListCollection jobs;
  static Future<List<Entity>> jobsAsync;
  
  final String url = '127.0.0.1';
  final String port = '8080';
  final Serializer serializer = new SerializerJson<String>();

  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------

  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------

  DropdownItemRenderer({String elementId: null}) : super(elementId: null, autoDrawBackground: false) {
    layout = new HorizontalLayout();
  }

  static DropdownItemRenderer construct() {
    return new DropdownItemRenderer();
  }

  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------

  void createChildren() {
    _comboBox = new ComboBox()
    ..width = 220
    ..height = 30
    ..labelFunction = comboBox_labelHandler
    ..paddingLeft = 5;
    
    _comboBox.onSelectedItemChanged.listen(comboBox_onSelectedItemChangedHandler);

    loadJobs();
    
    addComponent(_comboBox);
  }
  
  void loadJobs() {
    if (jobs != null) {
      _comboBox.dataProvider = jobs;
      
      invalidateData();
    } else if (jobsAsync != null) {
      jobsAsync.then(
          (List<Entity> entities) {
            jobs = new ListCollection(source: entities);
            
            _comboBox.dataProvider = jobs;
            
            invalidateData();
          }  
      );
    } else {
      fetchService = new FetchService(url, port, serializer, handleConflictAcceptClient);
      
      jobsAsync = fetchService.ormEntityLoad('Job');
      
      jobsAsync.then(
          (List<Entity> entities) {
            jobs = new ListCollection(source: entities);
            
            _comboBox.dataProvider = jobs;
            
            invalidateData();
          }
      );
    }
  }

  void invalidateData() {
    if (
        (_comboBox != null) &&
        (data != null) &&
        (field != null) &&
        (_comboBox.dataProvider != null)
    ) {
      _comboBox.selectedItem = data[field];
    }
  }
  
  void comboBox_onSelectedItemChangedHandler(FrameworkEvent Event) {
    if (
        (data != null) &&
        (field != null) &&
        (_comboBox.selectedItem is Job)
    ) {
      data[field] = _comboBox.selectedItem;
    }
  }
  
  String comboBox_labelHandler(Job job) => job.name;
  
  ConflictManager handleConflictAcceptClient(Entity serverEntity, Entity clientEntity) {
    return ConflictManager.ACCEPT_CLIENT;
  }
}