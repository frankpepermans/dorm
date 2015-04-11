part of item_renderers;

class DropdownItemRenderer extends ItemRenderer {

  //---------------------------------
  //
  // Protected properties
  //
  //---------------------------------

  ComboBox _comboBox;
  
  static FetchService fetchService;
  static ObservableList jobs;
  static Future<List<Entity>> jobsAsync;
  
  final String url = '127.0.0.1', port = '8080';
  final Serializer serializer = new SerializerJson();

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

  static DropdownItemRenderer construct() => new DropdownItemRenderer();

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
    bool loadAsync = false;
    
    if (jobs != null) {
      _comboBox.dataProvider = jobs;
      
      invalidateData();
    } else if (jobsAsync != null) {
      loadAsync = true;
    } else {
      fetchService = new FetchService(url, port, serializer, handleConflictAcceptClient);
      
      jobsAsync = fetchService.ormEntityLoad('Job');
      
      loadAsync = true;
    }
    
    if (loadAsync) {
      jobsAsync.then(
          (List<Entity> entities) {
            jobs = entities;
            
            _comboBox.dataProvider = jobs;
            
            jobs.changes.listen(
              (List<ChangeRecord> changes) => invalidateData()  
            );
            
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
  
  void comboBox_onSelectedItemChangedHandler(FrameworkEvent<Job> event) {
    if (
        (data != null) &&
        (field != null)
    ) data[field] = event.relatedObject;
  }
  
  String comboBox_labelHandler(Job job) => job.name;
  
  ConflictManager handleConflictAcceptClient(Entity serverEntity, Entity clientEntity) => ConflictManager.AcceptClient;
}