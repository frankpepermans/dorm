part of dorm;

class DormManager {
  
  //-----------------------------------
  //
  // Private properties
  //
  //-----------------------------------
  
  List<Entity> _queue = <Entity>[];
  List<Entity> _deleteQueue = <Entity>[];
  
  //-----------------------------------
  //
  // Public properties
  //
  //-----------------------------------
  
  String id;
  
  //-----------------------------------
  //
  // Constructor
  //
  //-----------------------------------
  
  DormManager({String id}) {
    this.id = id;
  }
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  void queueAsDeleted(Entity entity) {
    if (
        entity._scan.isMutableEntity &&
        !_deleteQueue.contains(entity)
    ) {
      _deleteQueue.add(entity);
    }
  }
  
  void queue(Entity entity) {
    if (
        entity._scan.isMutableEntity &&
        !_queue.contains(entity) &&
        entity.isDirty()
    ) {
      _queue.add(entity);
    }
  }
  
  DormManagerCommitStructure getCommitStructure() {
    List<Entity> queueRecursive = <Entity>[];
    List<Entity> deleteQueueRecursive = <Entity>[];
    
    queueRecursive.addAll(_queue);
    deleteQueueRecursive.addAll(_deleteQueue);
    
    _queue.forEach(
      (Entity entity) => _scanRecursively(entity, queueRecursive)
    );
    
    _deleteQueue.forEach(
        (Entity entity) => _scanRecursively(entity, deleteQueueRecursive)
    );
    
    _queue = queueRecursive;
    _deleteQueue = deleteQueueRecursive;
    
    _flushInternal();
    
    _queue.forEach(
        (Entity entity) => entity.validate()
    );
    
    _deleteQueue.forEach(
        (Entity entity) => entity.validate()
    );
    
    return new DormManagerCommitStructure(queueRecursive, deleteQueueRecursive);
  }
  
  //-----------------------------------
  //
  // Private methods
  //
  //-----------------------------------
  
  void _scanRecursively(Entity entity, List<Entity> list) {
    entity._scan._proxies.forEach(
      (_ProxyEntry entry) {
        if (entry.proxy.value is Entity) {
          if (
              entry.proxy.value._scan.isMutableEntity &&
              !list.contains(entry.proxy.value) &&
              entry.proxy.value.isDirty()
          ) {
            list.add(entry.proxy.value);
          }
        } else if (entry.proxy.value is List) {
          List<Entity> entityList = entry.proxy.value;
          
          entityList.forEach(
            (Entity listEntity) => _scanRecursively(listEntity, list)  
          );
        }
      }
    );
  }
  
  void _flushInternal() {
    _queue = <Entity>[];
    _deleteQueue = <Entity>[];
  }
  
}

//-----------------------------------
//
// Internal objects
//
//-----------------------------------

class DormManagerCommitStructure {
  
  final List<Entity> dataToCommit;
  final List<Entity> dataToDelete;
  
  const DormManagerCommitStructure(this.dataToCommit, this.dataToDelete);
  
}