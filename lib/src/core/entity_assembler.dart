part of dorm;

/**
 * This class is a singleton, you may obtain the instance at any time in the following manner :
 * 
 *     main() {
 *       EntityAssembler assemblerSingletonInstance = new EntityAssembler();
 *     }
 * 
 * While it is possible to create an [Entity] directly with the assembler, you should use [EntityFactory]
 * with your services to facilitate this.
 * 
 * The assembler is responsible for the creation of an [Entity] and also continues to maintain it afterwards. 
 * As soon as an [Entity] is created, it will be stored in the [EntityKeyChain] chain,
 * should the same [Entity] then at a later time be reloaded in any way,
 * then the assembler will choose to update it in the case of [ConflictManager.ACCEPT_SERVER]
 * or keep the client [Entity] unchanged in case of [ConflictManager.ACCEPT_CLIENT].
 * This [ConflictManager] should be passed with the main spawn function of the [EntityFactory]
 */
class EntityAssembler {
  
  //---------------------------------
  //
  // Private properties
  //
  //---------------------------------
  
  static const Symbol ENTITY_SYMBOL = const Symbol('dorm.Entity');
  
  final List<EntityRootScan> _entityScans = <EntityRootScan>[];
  final List<List<dynamic>> _collections = <List<dynamic>>[];
  final List<DormProxy> _pendingProxies = <DormProxy>[];
  
  ConflictManager _handleConflictAcceptClient(Entity serverEntity, Entity clientEntity) => ConflictManager.ACCEPT_CLIENT;
  
  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  //---------------------------------
  //
  // Singleton Constructor
  //
  //---------------------------------
  
  const EntityAssembler._construct();
  
  //---------------------------------
  //
  // Factories
  //
  //---------------------------------
  
  static EntityAssembler _instance;

  factory EntityAssembler() {
    if (_instance == null) _instance = new EntityAssembler._construct();

    return _instance;
  }
  
  //---------------------------------
  //
  // Public methods
  //
  //---------------------------------
  
  /**
   * TO_DO: scan requires mirrors, it would be better to move this to a build file later
   */
  EntityRootScan scan(Type forType, String refClassName, Function constructorMethod) {
    EntityRootScan scan = _existingFromScanRegistry(refClassName);
    
    if(scan != null) return scan;
    
    scan = new EntityRootScan(refClassName, constructorMethod);
    
    ClassMirror classMirror = reflectClass(forType);
    
    while (classMirror.qualifiedName != ENTITY_SYMBOL) {
      if (scan.isMutableEntity) scan.detectIfMutable(classMirror);
      
      classMirror.declarations.forEach(
          (_, Mirror mirror) {
            if ((mirror is VariableMirror) && !mirror.isStatic && mirror.isPrivate) scan.registerMetadataUsing(mirror);
          }
      );
      
      classMirror = classMirror.superclass;
    }
    
    _entityScans.add(scan);
    
    return scan;
  }
  
  void registerProxies(Entity entity, List<DormProxy> proxies) {
    if (entity._scan == null) entity._scan = _createEntityScan(entity);
    
    final EntityScan scan = entity._scan;
    DormProxy proxy;
    _DormProxyPropertyInfo scanProxy;
    int i = proxies.length;
    
    while (i > 0) {
      proxy = proxies[--i];
      
      scanProxy = scan._proxies[proxy._property];
      
      scanProxy.proxy = proxy;
      
      proxy._updateWithMetadata(
          scanProxy, 
          scan
      );
    }
  }
  
  //---------------------------------
  //
  // Library protected methods
  //
  //---------------------------------
  
  EntityScan _createEntityScan(Entity entity) {
    EntityRootScan scan = _existingFromScanRegistry(entity.refClassName);
    
    if(scan != null) return new EntityScan.fromRootScan(scan, entity);
    
    throw new DormError('Scan for entity not found');
  }
  
  Entity _assemble(Map<String, dynamic> rawData, DormProxy owningProxy, Serializer serializer, OnConflictFunction onConflict) {
    final String refClassName = rawData[SerializationType.ENTITY_TYPE];
    EntityRootScan entityScan;
    Entity spawnee, localNonPointerEntity;
    
    if (onConflict == null) onConflict = _handleConflictAcceptClient;
    
    entityScan = _existingFromScanRegistry(refClassName);
    
    if (entityScan == null) throw new DormError('Scan for entity not found');
    
    if (entityScan._unusedInstance != null) {
      spawnee = entityScan._unusedInstance;
      
      entityScan._unusedInstance = null;
    } else {
      spawnee = entityScan._entityCtor();
    }
    
    spawnee.readExternal(rawData, serializer, onConflict);
    
    final bool isSpawneeUnsaved = spawnee.isUnsaved();
    
    if (isSpawneeUnsaved) {
      if (spawnee._isPointer) throw new DormError('Ambiguous reference, entity is unsaved and is also a pointer');
      else return spawnee;
    }
    
    spawnee._scan.buildKey();
    
    localNonPointerEntity = EntityKeyChain.getFirstSibling(spawnee._scan, allowPointers: false);
    
    if (
        !spawnee._isPointer &&
        (localNonPointerEntity != null)
    ) _solveConflictsIfAny(
        spawnee,
        localNonPointerEntity, 
        onConflict
    );
    
    if (localNonPointerEntity != null) {
      entityScan._unusedInstance = spawnee;
      
      return localNonPointerEntity;
    }
    
    if (spawnee._isPointer) {
      if (owningProxy != null) _pendingProxies.add(owningProxy);
    } else {
      spawnee._scan._keyChain.entityScans.add(spawnee._scan);
      
      spawnee._scan._proxies.forEach(
          (String property, _DormProxyPropertyInfo entry) {
            if (entry.proxy.owner != null) _collections.add(entry.proxy.owner);
          }
      );
      
      _updateCollectionsWith(spawnee);
    }
    
    return spawnee;
  }
  
  void _solveConflictsIfAny(Entity spawnee, Entity existingEntity, OnConflictFunction onConflict) {
    ConflictManager conflictManager;
    Map<String, _DormProxyPropertyInfo> entryProxies, spawneeProxies;
    int i, j;
    
    if (onConflict == null) throw new DormError('Conflict was detected, but no onConflict method is available');
    
    conflictManager = onConflict(
        spawnee, 
        existingEntity
    );
    
    if (conflictManager == ConflictManager.ACCEPT_SERVER) {
      entryProxies = existingEntity._scan._proxies;
      
      entryProxies.forEach(
          (String property, _DormProxyPropertyInfo entry) {
            spawneeProxies = spawnee._scan._proxies;
            
            final _DormProxyPropertyInfo entryMatch = spawneeProxies[entry.info.property];
            
            if (entryMatch != null && entryMatch.proxy.hasDelta) entry.proxy.setInitialValue(existingEntity.notifyPropertyChange(entry.proxy._propertySymbol, entry.proxy._value, entryMatch.proxy._value));
          }
      );
    }
  }
  
  void _updateCollectionsWith(Entity actualEntity) {
    List<dynamic> collectionEntry;
    DormProxy proxy;
    bool collectionEntryHasPointers;
    int i = _pendingProxies.length;
    
    while (i > 0) {
      proxy = _pendingProxies[--i];
      
      if (EntityKeyChain.areSameKeySignature(proxy._value._scan, actualEntity._scan)) {
        proxy.setInitialValue(actualEntity);
        
        _pendingProxies.remove(proxy);
      }
    }
    
    i = _collections.length;
    
    while (i > 0) {
      collectionEntry = _collections[--i];
      
      collectionEntryHasPointers = false;
      
      collectionEntry.forEach(
          (dynamic entry) {
            if (entry is Entity) {
              if (EntityKeyChain.areSameKeySignature(entry._scan, actualEntity._scan)) {
                collectionEntry[collectionEntry.indexOf(entry)] = actualEntity;
              } else if (entry._isPointer) {
                collectionEntryHasPointers = true;
              }
            }
          }
      );
      
      if (!collectionEntryHasPointers) _collections.remove(collectionEntry);
    }
  }
  
  EntityRootScan _existingFromScanRegistry(String refClassName) {
    return _entityScans.firstWhere(
      (EntityRootScan scan) => (scan.refClassName.compareTo(refClassName) == 0),
      orElse: () => null
    );
  }
}