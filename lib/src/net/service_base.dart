part of dorm;

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
    print(serializer.outgoing(arguments));
    HttpRequest.request(
        'http://${host}:$port', 
        method:operation, 
        sendData:serializer.outgoing(arguments)
    ).then(
        (HttpRequest request) {
          if (request.responseText.length > 0) {
            EntityFactory<Entity> factory = new EntityFactory(onConflict);
            Stopwatch stopwatch;
            print(request.responseText);
            stopwatch = new Stopwatch()..start();
            
            List<Map<String, dynamic>> result = serializer.incoming(request.responseText);
            
            stopwatch.stop();
            
            print('json parse completed in ${stopwatch.elapsedMilliseconds} ms');
            
            stopwatch = new Stopwatch()..start();
            
            ObservableList<Entity> spawned = factory.spawn(result);
            
            stopwatch.stop();
            
            print('assembly completed in ${stopwatch.elapsedMilliseconds} ms');
            
            completer.complete(isUniqueResult ? spawned.first : spawned);
          }
        }, onError: (_) {
          print('Oops, something went wrong, are you sure that the server has started up correctly?');
        }
    );
    
    return completer.future;
  }
  
}