part of dorm_json_mock_server;

class FetchService extends BaseService {
  
  final JsonDatabase dbo = new JsonDatabase();
  
  FetchService() : super();
  
  String ormEntityLoadByPK(String entityName, int entityId) {
    dbo.resetCache();
    
    List<Map<String, dynamic>> result = dbo.ormEntityLoad(
        entityName, 
        entityId:entityId
    );
    
    return stringify(result.first);
  }
  
  String ormEntityLoad(String entityName, Map<String, String> where) {
    List<Map<String, dynamic>> result;
    
    dbo.resetCache();
    
    if (where != null) {
      result = dbo.ormEntityLoad(
          entityName,
          whereHandler: (Map<String, dynamic> fkRow) {
            bool isMatch = true;
            
            where.forEach(
                (String field, dynamic value) {
                  String rowColumnName = dbo.getTableColumnForProperty(entityName, field);
                  
                  if (fkRow[rowColumnName] != value) {
                    isMatch = false;
                  }
                }
            );
            
            return isMatch;
          }
      );
      
      return stringify(result);
    } else {
      result = dbo.ormEntityLoad(entityName);
      
      return stringify(result);
    }
  }
  
}