import 'dart:io';
import 'dart:json';
import 'dart:typed_data';
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
                  Map<String, dynamic> data;
                  String responseContent = '';
                  
                  request.response.headers.add(HttpHeaders.CONTENT_TYPE, "application/json");
                  request.response.headers.add("Access-Control-Allow-Origin", "*, ");
                  request.response.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS, ormEntityLoadByPK, ormEntityLoad, flush");
                  request.response.headers.add("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
                  
                  String uintListToString = new String.fromCharCodes(body.body);
                  
                  if (uintListToString.length > 0) {
                    data = parse(uintListToString);
                  }
                  
                  switch (request.method) {
                    case 'ormEntityLoadByPK' :
                      responseContent = fetchService.ormEntityLoadByPK(
                          data['entityName'],
                          int.parse(data['entityId'])
                      );
                      
                      break;
                      
                    case 'ormEntityLoad' :
                      Map<String, String> where;
                      
                      if (data.containsKey('where')) {
                        where = parse(data['where']);
                      }
                      
                      responseContent = fetchService.ormEntityLoad(
                          data['entityName'],
                          where
                      );
                      
                      break;
                      
                    case 'flush' :
                      responseContent = commitService.flush(
                          data['orm_commit'],
                          data['orm_commit_delete']
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