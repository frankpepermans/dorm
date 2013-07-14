part of orm_infrastructure;

class FetchService extends ServiceBase {
  
  FetchService(String host, String port, Serializer serializer, OnConflictFunction onConflict) : super(host, port, serializer, onConflict);
  
  Future<Entity> ormEntityLoadByPK(
      String entityName, 
      int entityId
  ) {
    Map<String, dynamic> arguments = new Map<String, dynamic>();
    
    arguments['entityName'] = entityName;
    arguments['entityId'] = entityId;
    
    return apply('ormEntityLoadByPK', arguments, true);
  }
  
  Future<ObservableList<Entity>> ormEntityLoad(
      String entityName, {
        Map<String, dynamic> where
      }
  ) {
    Map<String, dynamic> arguments = new Map<String, dynamic>();
    
    arguments['entityName'] = entityName;
    
    if (where != null) {
      arguments['where'] = where;
    }
    
    return apply('ormEntityLoad', arguments, false);
  }
  
}