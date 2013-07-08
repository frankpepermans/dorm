part of dorm;

class ServiceBase {
  
  final String host;
  final String port;
  final Serializer serializer;
  final OnConflictFunction onConflict;
  
  ServiceBase(this.host, this.port, this.serializer, this.onConflict);
  
  Future apply(String operation, Map<String, dynamic> arguments, bool isUniqueResult) {
    Completer completer = new Completer();
    String url = 'http://${host}:$port';
    
    HttpRequest.request(url, method:operation, sendData:serializer.outgoing(arguments)).then(
        (HttpRequest request) {
          if (request.responseText.length > 0) {
            EntityFactory<Entity> factory = new EntityFactory(onConflict);
            
            List<Map<String, dynamic>> result = serializer.incoming(request.responseText);
            List<Entity> spawned = factory.spawn(result);
            
            completer.complete(isUniqueResult ? spawned.first : spawned);
          }
        }, onError: (_) {
          print('Oops, something went wrong, are you sure that the server has started up correctly?');
        }
    );
    
    return completer.future;
  }
  
}