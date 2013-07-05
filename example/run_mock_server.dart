import 'dart:io';
import 'dart:json';
import 'package:dorm/dorm_json_mock_server.dart';

void main() {
  final FetchService fetchService = new FetchService();
  final CommitService commitService = new CommitService();
  
  HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 8080).then(
    (HttpServer server) {
      server.listen(
          (HttpRequest request) {
            HttpBodyHandler.processRequest(request).then(
                (HttpBody body) {
                  String responseContent = '';
                  
                  request.response.headers.add(HttpHeaders.CONTENT_TYPE, "application/json");
                  request.response.headers.add("Access-Control-Allow-Origin", "*, ");
                  request.response.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS, ormEntityLoadByPK, ormEntityLoad, flush");
                  request.response.headers.add("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
                  
                  switch (request.method) {
                    case 'ormEntityLoadByPK' :
                      responseContent = fetchService.ormEntityLoadByPK(
                          body.body['entityName'],
                          int.parse(body.body['entityId'])
                      );
                      
                      break;
                      
                    case 'ormEntityLoad' :
                      Map<String, String> where;
                      
                      if (body.body.containsKey('where')) {
                        where = parse(body.body['where']);
                      }
                      
                      responseContent = fetchService.ormEntityLoad(
                          body.body['entityName'],
                          where
                      );
                      
                      break;
                      
                    case 'flush' :
                      responseContent = commitService.flush(
                          parse(body.body['orm_commit']),
                          parse(body.body['orm_commit_delete'])
                      );
                      
                      break;
                  }
                  
                  request.response.write(responseContent);
                  
                  request.response.close();
                }
            );
           }
      );
    }
  );
}