part of orm_infrastructure;

class CommitService extends ServiceBase {
  
  CommitService(String host, String port, Serializer serializer, OnConflictFunction onConflict) : super(host, port, serializer, onConflict);
  
  Future<ObservableList<Entity>> flush(List<Entity> dataToCommit, List<Entity> dataToDelete) {
    Map<String, dynamic> arguments = new Map<String, dynamic>();
    
    arguments['orm_commit'] = dataToCommit;
    arguments['orm_commit_delete'] = dataToDelete;
    
    return apply('flush', arguments, false);
  }
  
}