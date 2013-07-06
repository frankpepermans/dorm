part of dorm;

class ServiceBase {
  
  final String host;
  final String port;
  final Serializer serializer;
  final OnConflictFunction onConflict;
  
  ServiceBase(this.host, this.port, this.serializer, this.onConflict);
  
  Future apply(String operation, Map<String, dynamic> arguments) {
    Completer completer = new Completer();
    FormData data = new FormData();
    String url = 'http://${host}:$port';
    
    arguments.forEach(
      (String key, dynamic value) => data.append(key, serializer.outgoing(value))
    );
    
    HttpRequest.request(url, method:operation, sendData:data).then(
        (HttpRequest request) {
          if (request.responseText.length > 0) {
            EntityFactory factory = new EntityFactory(onConflict);
            
            dynamic result = serializer.incoming(request.responseText);
            
            if (result is List<Map<String, dynamic>>) {
              completer.complete(
                  factory.spawn(result)
              );
            } else if (result is Map<String, dynamic>) {
              completer.complete(
                  factory.spawn(<Map<String, dynamic>>[result]).first
              );
            }
          }
        }, onError: (_) {
          print('Oops, something went wrong, are you sure that the server has started up correctly?');
        }
    );
    
    return completer.future;
  }
  
}