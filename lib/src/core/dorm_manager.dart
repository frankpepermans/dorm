part of dorm;

typedef bool IsDirtyHandler(Entity instance);

class DormManager extends ChangeNotifier {
  
  //-----------------------------------
  //
  // Private properties
  //
  //-----------------------------------
  
  List<Entity> _observeList = <Entity>[];
  List<Entity> _queue = <Entity>[];
  List<Entity> _deleteQueue = <Entity>[];
  List<String> _ignoredProperties = <String>[];
  HashMap<Entity, StreamSubscription> _dirtyListeners = new HashMap<Entity, StreamSubscription>.identity();
  bool _forcedDirtyStatus = false;
  
  //-----------------------------------
  //
  // Public properties
  //
  //-----------------------------------
  
  //-----------------------------------
  // id
  //-----------------------------------
  
  String _id;
  
  String get id => _id;
  
  bool ignoresUnsavedStatus = false;
  
  //-----------------------------------
  // dirtyHandler
  //-----------------------------------
  
  IsDirtyHandler _dirtyHandler;
  
  IsDirtyHandler get dirtyHandler => _dirtyHandler;
  
  void set dirtyHandler(IsDirtyHandler value) {
    if (value != _dirtyHandler) {
      _dirtyHandler = value;
    }
  }
  
  //-----------------------------------
  // queueLength
  //-----------------------------------
  
  static const Symbol IS_COMMIT_REQUIRED = const Symbol('dorm.core.DormManager.isCommitRequired');
  static const Symbol IS_COMMIT_NOT_REQUIRED = const Symbol('dorm.core.DormManager.isCommitNotRequired');
  
  bool _isCommitStatusInvalidated = false;
  bool _isCommitRequired = false;
  
  bool get isCommitRequired => _isCommitRequired;
  void set isCommitRequired(bool value) {
    if (value != _isCommitRequired) _isCommitRequired = value;
    
    notifyChange(
        new PropertyChangeRecord(
            this,
            value ? IS_COMMIT_REQUIRED : IS_COMMIT_NOT_REQUIRED,
            false, true
        )    
    );
  }
  
  void _updateIsCommitRequired() {
    bool status = false;
    
    if (!_forcedDirtyStatus) {
      final List<Entity> fullList = new List<Entity>()
      ..addAll(_queue)
      ..addAll(_deleteQueue);
      
      final Entity firstDirtyEntity = fullList.firstWhere(
        (Entity entity) => _getDirtyStatus(entity), 
        orElse: () => null
      );
      
      status = (firstDirtyEntity != null);
    } else status = true;
    
    isCommitRequired = status;
  }
  
  //-----------------------------------
  //
  // Constructor
  //
  //-----------------------------------
  
  DormManager({String id}) {
    this._id = id;
  }
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  void addPropertyToIgnore(String propertyName) => _ignoredProperties.add(propertyName);
  
  void invalidateCommitStatus() {
    if (!_isCommitStatusInvalidated) {
      _isCommitStatusInvalidated = true;
      
      _updateIsCommitRequired();
      
      final Timer timeout = new Timer(
          const Duration(milliseconds: 50),
          () {
            _isCommitStatusInvalidated = false;
            
            _updateIsCommitRequired();
          }
      );
    }
  }
  
  void resetCommitStatus() {
    isCommitRequired = false;
  }
  
  void forceDirtyStatus(bool value) {
    _forcedDirtyStatus = value;
    
    invalidateCommitStatus();
  }
  
  bool isQueued(Entity entity, {bool forDelete: false}) {
    if (forDelete) return _deleteQueue.contains(entity);
    
    return _queue.contains(entity);
  }
  
  void queueAsDeleted(Entity entity) {
    if (
        entity.isMutable &&
        !_deleteQueue.contains(entity)
    ) {
      _queue.remove(entity);
      _deleteQueue.add(entity);
      
      invalidateCommitStatus();
    }
  }
  
  void queue(Entity entity) {
    if (
        entity.isMutable &&
        !_queue.contains(entity)/* &&
        entity.isDirty()*/
    ) {
      _deleteQueue.remove(entity);
      _queue.add(entity);
      
      invalidateCommitStatus();
      
      StreamSubscription subscription = _dirtyListeners[entity];
      
      if (subscription != null) {
        subscription.cancel();
        
        _dirtyListeners.remove(subscription);
      }
      
      _dirtyListeners[entity] = entity.changes.listen(
        (_) => invalidateCommitStatus()
      );
    }
  }
  
  void unqueue(Entity entity) {
    if (entity.isMutable) {
      if (_queue.contains(entity)) _queue.remove(entity);
      if (_deleteQueue.contains(entity)) _deleteQueue.remove(entity);
      
      invalidateCommitStatus();
      
      StreamSubscription subscription = _dirtyListeners[entity];
      
      if (subscription != null) {
        subscription.cancel();
        
        _dirtyListeners.remove(subscription);
      }
    }
  }
  
  void queueAll(Iterable<Entity> entities, {bool asDeleted: false}) {
    entities.forEach(
      (Entity entity) => asDeleted ? queueAsDeleted(entity) : queue(entity)    
    );
  }
  
  void unqueueAll(Iterable<Entity> entities) {
    entities.forEach(
      (Entity entity) => unqueue(entity)    
    );
  }
  
  void revertAllChanges() {
    _dirtyListeners.forEach(
      (_, StreamSubscription subscription) => subscription.cancel() 
    );
    
    _dirtyListeners = new HashMap<Entity, StreamSubscription>.identity();
    
    _queue.forEach(
      (Entity entity) => entity.revertChanges()
    );
    
    _deleteQueue.forEach(
        (Entity entity) => entity.revertChanges()
    );
    
    clear();
  }
  
  void clear({bool clearNormalQueue: true, bool clearDeleteQueue: true}) {
    _forcedDirtyStatus = false;
    //_isCommitRequired = false;
    
    _flushInternal(clearNormalQueue, clearDeleteQueue);
    
    invalidateCommitStatus();
  }
  
  DormManagerCommitStructure drain({bool ignoreMutable: false, bool ignoreDirty: false}) {
    final List<Entity> rollbackCommit = new List<Entity>.from(_queue);
    final List<Entity> rollbackDelete = new List<Entity>.from(_deleteQueue);
    List<Entity> queueRecursive = <Entity>[];
    List<Entity> deleteQueueRecursive = <Entity>[];
    
    queueRecursive.addAll(_queue);
    deleteQueueRecursive.addAll(_deleteQueue);
    
    _queue.forEach(
      (Entity entity) => _scanRecursively(entity, queueRecursive, ignoreMutable, ignoreDirty, false)
    );
    
    _deleteQueue.forEach(
        (Entity entity) => _scanRecursively(entity, deleteQueueRecursive, ignoreMutable, ignoreDirty, true)
    );
    
    _queue = queueRecursive;
    _deleteQueue = deleteQueueRecursive;
    
    _flushInternal(true, true);
    
    _queue.forEach(
        (Entity entity) => entity.validate()
    );
    
    _deleteQueue.forEach(
        (Entity entity) => entity.validate()
    );
    
    return new DormManagerCommitStructure(this, queueRecursive, deleteQueueRecursive, rollbackCommit, rollbackDelete);
  }
  
  //-----------------------------------
  //
  // Private methods
  //
  //-----------------------------------
  
  bool _getDirtyStatus(Entity entity) {
    if (_dirtyHandler != null) return _dirtyHandler(entity);
    
    return entity.isDirty(ignoresUnsavedStatus: ignoresUnsavedStatus, ignoredProperties: _ignoredProperties);
  }
  
  bool _isProtected(Entity masterEntity, Symbol field) {
     final Map<String, dynamic> genericAnnotations = masterEntity.getGenericAnnotations(field);
     final bool unprotected = (
         (genericAnnotations['protected'] == null) ||
         (genericAnnotations['protected'] == false)
     );
     
     return !unprotected;
  }
  
  void _scanRecursively(Entity entity, List<Entity> list, bool ignoreMutable, bool ignoreDirty, bool isDelete) {
    entity._scan._proxies.forEach(
      (_DormProxyPropertyInfo entry) {
        if (entry.proxy.value is Entity) {
          final Entity tmpEntity = entry.proxy.value as Entity;
          
          if (
              (ignoreMutable || tmpEntity.isMutable) &&
              !list.contains(tmpEntity) &&
              (ignoreDirty || tmpEntity.isDirty()) &&
              (!isDelete || !_isProtected(entity, entry.info.propertySymbol))
          ) {
            list.add(tmpEntity);
            
            _scanRecursively(tmpEntity, list, ignoreMutable, ignoreDirty, isDelete);
          }
        } else if (entry.proxy.value is Iterable) {
          Iterable<Entity> entityList = entry.proxy.value;
          
          entityList.forEach(
            (Entity listEntity) {
              if (
                  (ignoreMutable || listEntity.isMutable) &&
                  !list.contains(listEntity) &&
                  (ignoreDirty || listEntity.isDirty()) &&
                  (!isDelete || !_isProtected(entity, entry.info.propertySymbol))
              ) {
                list.add(listEntity);
                
                _scanRecursively(listEntity, list, ignoreMutable, ignoreDirty, isDelete);
              }
            }
          );
        }
      }
    );
  }
  
  void _flushInternal(bool clearNormalQueue, bool clearDeleteQueue) {
    if (clearNormalQueue) _queue = <Entity>[];
    if (clearDeleteQueue) _deleteQueue = <Entity>[];
  }
  
}

//-----------------------------------
//
// Internal objects
//
//-----------------------------------

class DormManagerCommitStructure {
  
  final DormManager manager;
  final List<Entity> dataToCommit;
  final List<Entity> dataToDelete;
  final List<Entity> rollbackCommit;
  final List<Entity> rollbackDelete;
  
  const DormManagerCommitStructure(this.manager, this.dataToCommit, this.dataToDelete, this.rollbackCommit, this.rollbackDelete);
  
  void rollback() {
    manager.queueAll(rollbackCommit, asDeleted: false);
    manager.queueAll(rollbackDelete, asDeleted: true);
  }
  
}