part of orm_infrastructure;

class ServiceBase {
  
  //-----------------------------------
  //
  // Public properties
  //
  //-----------------------------------
  
  final String host;
  final String port;
  final Serializer serializer;
  final OnConflictFunction onConflict;
  
  //-----------------------------------
  //
  // Constructor
  //
  //-----------------------------------
  
  ServiceBase(this.host, this.port, this.serializer, this.onConflict);
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  Future apply(String operation, Map<String, dynamic> arguments, bool isUniqueResult) {
    Completer completer = new Completer();
    
    HttpRequest.request(
        'http://${host}:$port', 
        method:operation, 
        sendData:serializer.outgoing(arguments)
    ).then(
        (HttpRequest request) {
          if (request.responseText.length > 0) {
            EntityFactory<Entity> factory = new EntityFactory();
            Stopwatch stopwatch;
            
            stopwatch = new Stopwatch()..start();
            
            List<Map<String, dynamic>> result = serializer.incoming(request.responseText);
            
            ObservableList<Entity> spawned = factory.spawn(result, serializer, onConflict);
            
            stopwatch.stop();
            
            print('deserializing & assembly completed in ${stopwatch.elapsedMicroseconds} micro seconds');
            
            completer.complete(isUniqueResult ? spawned.first : spawned);
          }
        }, onError: (_) {
          print('Oops, something went wrong, are you sure that the server has started up correctly?');
        }
    );
    
    return completer.future;
  }
  
}