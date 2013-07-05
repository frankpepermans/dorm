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
      (String key, dynamic value) {
        if (
            (value is List) ||
            (value is Map)
        ) {
          data.append(key, serializer.outgoing(value));
        } else {
          data.append(key, value.toString());
        }
      }
    );
    
    HttpRequest.request(url, method:operation, sendData:data).then(
        (HttpRequest request) {
          if (request.responseText.length > 0) {
            dynamic result = serializer.incoming(request.responseText);
            
            EntityManager entityManager = new EntityManager();
            
            if (result is List) {
              List<Entity> resultList = <Entity>[];
              
              result.forEach(
                  (Map<String, dynamic> resultEntry) => resultList.add(
                      entityManager._spawn(resultEntry, onConflict)
                  )  
              );
              
              completer.complete(resultList);
            } else if (result is Map<String, dynamic>) {
              Entity resultEntity = entityManager._spawn(result, onConflict);
              
              completer.complete(resultEntity);
            }
          }
        }, onError: (_) {
          print('Oops, something went wrong, are you sure that the server has started up correctly?');
        }
    );
    
    return completer.future;
  }
  
}