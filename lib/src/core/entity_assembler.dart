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
  
  final Map<String, EntityRootScan> _entityScans = <String, EntityRootScan>{};
  
  List<DormProxy> _pendingProxies = <DormProxy>[];
  
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
  
  EntityAssembler._internal();
  
  //---------------------------------
  //
  // Factories
  //
  //---------------------------------
  
  static final EntityAssembler _assembler = new EntityAssembler._internal();

  factory EntityAssembler() => _assembler;
  
  //---------------------------------
  //
  // Public methods
  //
  //---------------------------------
  
  /**
   * TO_DO: scan requires mirrors, it would be better to move this to a build file later
   */
  EntityRootScan scan(Type forType, String refClassName, Function constructorMethod) {
    EntityRootScan scan = _entityScans[refClassName];
    
    if(scan != null) return scan;
    
    scan = new EntityRootScan(refClassName, constructorMethod);
    
    ClassMirror classMirror = reflectClass(forType);
    
    while (classMirror.reflectedType != Entity) {
      if (scan.isMutableEntity) scan.detectIfMutable(classMirror);
      
      classMirror.declarations.forEach(
          (_, Mirror mirror) {
            if ((mirror is VariableMirror) && !mirror.isStatic && mirror.isPrivate) scan.registerMetadataUsing(mirror);
          }
      );
      
      classMirror = classMirror.superclass;
    }
    
    _entityScans[refClassName] = scan;
    
    return scan;
  }
  
  void registerProxies(Entity entity, List<DormProxy> proxies) {
    if (entity._scan == null) entity._scan = _createEntityScan(entity);
    
    final bool useMapForLookup = (entity._scan._proxies.length > 25);
    
    DormProxy proxy;
    _DormProxyPropertyInfo scanProxy;
    int i = proxies.length;
    
    while (i > 0) {
      proxy = proxies[--i];
      
      if (!useMapForLookup) scanProxy = entity._scan._proxies.firstWhere(
        (_DormProxyPropertyInfo entry) => (entry.info.property == proxy._property),
        orElse: () => null
      );
      else scanProxy = entity._scan._proxyMap[proxy._property];
      
      scanProxy.proxy = proxy;
      
      proxy._updateWithMetadata(
        scanProxy, 
        entity._scan
      );
    }
  }
  
  //---------------------------------
  //
  // Library protected methods
  //
  //---------------------------------
  
  EntityScan _createEntityScan(Entity entity) {
    EntityRootScan scan = _entityScans[entity.refClassName];
    
    if(scan != null) return new EntityScan.fromRootScan(scan, entity);
    
    throw new DormError('Scan for entity not found');
  }
  
  Entity _assemble(Map<String, dynamic> rawData, DormProxy owningProxy, Serializer serializer, OnConflictFunction onConflict) {
    final String refClassName = rawData[SerializationType.ENTITY_TYPE];
    EntityRootScan entityScan;
    Entity spawnee, localNonPointerEntity;
    
    if (onConflict == null) onConflict = (Entity serverEntity, Entity clientEntity) => ConflictManager.ACCEPT_CLIENT;
    
    entityScan = _entityScans[refClassName];
    
    if (entityScan == null) throw new DormError('Scan for entity not found: $refClassName');
    
    spawnee = entityScan._unusedInstance;
    
    if (spawnee == null) spawnee = entityScan._entityCtor();
    else entityScan._unusedInstance = null;
    
    spawnee.readExternal(rawData, serializer, onConflict);
    
    final bool isSpawneeUnsaved = spawnee.isUnsaved();
    
    if (isSpawneeUnsaved) {
      if (spawnee._isPointer) throw new DormError('Ambiguous reference, entity is unsaved and is also a pointer [${rawData}]');
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
      
      _updateCollectionsWith(spawnee);
    }
    
    return spawnee;
  }
  
  void _solveConflictsIfAny(Entity spawnee, Entity existingEntity, OnConflictFunction onConflict) {
    ConflictManager conflictManager;
    Iterable<_DormProxyPropertyInfo> entryProxies, spawneeProxies;
    int i, j;
    
    if (onConflict == null) throw new DormError('Conflict was detected, but no onConflict method is available');
    
    conflictManager = onConflict(
        spawnee, 
        existingEntity
    );
    
    if (conflictManager == ConflictManager.ACCEPT_SERVER) {
      entryProxies = existingEntity._scan._proxies;
      
      entryProxies.forEach(
          (_DormProxyPropertyInfo entryA) {
            final _DormProxyPropertyInfo entryMatch = spawnee._scan._proxies.firstWhere(
              (_DormProxyPropertyInfo entryB) => (entryA.info.property == entryB.info.property),
              orElse: () => null
            );
            
            if (entryMatch != null && entryMatch.proxy.hasDelta) entryA.proxy.setInitialValue(existingEntity.notifyPropertyChange(entryA.proxy._propertySymbol, entryA.proxy._value, entryMatch.proxy._value));
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
      
      if (proxy._value is Entity) {
        final Entity entity = proxy._value as Entity;
        
        if (EntityKeyChain.areSameKeySignature(entity._scan, actualEntity._scan)) {
          proxy.setInitialValue(actualEntity);
          
          _pendingProxies.remove(proxy);
        }
      } else if (proxy._value is Iterable) {
        final List entityList = proxy._value as Iterable;
        
        dynamic listEntry;
        int i = entityList.length;
        bool hasPointers = false, containsEntities;
        
        while (i > 0) {
          listEntry = entityList[--i];
          
          containsEntities = (listEntry is Entity);
          
          if (
            containsEntities &&
            EntityKeyChain.areSameKeySignature(listEntry._scan, actualEntity._scan)
          ) entityList[i] = actualEntity;
          
          if (containsEntities && !hasPointers) hasPointers = (entityList[i] as Entity)._isPointer;
        }
        
        if (!hasPointers) _pendingProxies.remove(proxy);
      }
    }
  }
}