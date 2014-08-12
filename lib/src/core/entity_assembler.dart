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
  
  EntityRootScan scan(String refClassName, Function constructorMethod, List<Map<String, dynamic>> meta, bool isMutable) {
    EntityRootScan scan = _entityScans[refClassName];
    
    if(scan == null) {
      scan = new EntityRootScan(refClassName, constructorMethod)..isMutableEntity = isMutable;
      
      _entityScans[refClassName] = scan;
    }
    
    meta.forEach(
      (Map<String, dynamic> M) => scan.registerMetadataUsing(M)
    );
    
    return scan;
  }
  
  void registerProxies(Entity entity, List<DormProxy> proxies) {
    if (entity._scan == null) entity._scan = _createEntityScan(entity);
    
    if (entity._scan == null) return;
    
    final EntityScan scan = entity._scan;
    DormProxy proxy;
    _DormProxyPropertyInfo I;
    int i = proxies.length;
    
    while (i > 0) {
      proxy = proxies[--i];
      
      I = scan._proxyMap[proxy._property];
      
      if (I != null) proxy._updateWithMetadata(
        I..proxy = proxy, 
        scan
      );
      
      if (proxy.isLazy) _initLazyLoading(entity, proxy);
    }
  }
  
  HashSet<Symbol> getPropertyFieldsForType(String refClassName) {
    final EntityRootScan entityScan = _entityScans[refClassName];
    final HashSet<Symbol> set = new HashSet<Symbol>.identity();
        
    if (entityScan == null) throw new DormError('Scan for entity not found: $refClassName');
    
    entityScan._rootProxies.forEach(
      (_DormPropertyInfo I) => set.add(I.propertySymbol)
    );
    
    return set;
  }
  
  HashSet<String> getIdentityPropertyFieldsForType(String refClassName) {
    final EntityRootScan entityScan = _entityScans[refClassName];
    final HashSet<String> set = new HashSet<String>.identity();
        
    if (entityScan == null) throw new DormError('Scan for entity not found: $refClassName');
    
    entityScan._rootProxies.forEach(
      (_DormPropertyInfo I) {
        if (I.metadataCache.isId) set.add(I.property);
      }
    );
    
    return set;
  }
  
  //---------------------------------
  //
  // Library protected methods
  //
  //---------------------------------
  
  void _initLazyLoading(Entity entity, DormProxy proxy) {
    proxy._lazyHandler = (DormProxy lazyProxy) {
      final ObservableList list = lazyProxy._value as ObservableList;
      
      if (!entity.isUnsaved()) {
        final EntityFactory factory = new EntityFactory();
        final EntityLazyHandler handler = factory._lazyHandlers.firstWhere(
          (EntityLazyHandler lazyHandler) => (lazyHandler.propertySymbol == lazyProxy._propertySymbol),
          orElse: () => null
        );
        
        if (handler == null) throw new DormError('Missing a lazy handler for ${lazyProxy._property} on entity $entity');
        else handler.handler(entity, lazyProxy._propertySymbol).then(
          (List<dynamic> resultSet) {
            if (resultSet != null && resultSet.length > 0) list.addAll(resultSet);
            
            list.notifyPropertyChange(IS_LAZILY_LOADED, null, list);
          }
        );
      } else list.notifyPropertyChange(IS_LAZILY_LOADED, null, list);
    };
  }
  
  EntityScan _createEntityScan(Entity entity) {
    final EntityRootScan scan = _entityScans[entity.refClassName];
    
    if(scan != null) return new EntityScan.fromRootScan(scan, entity);
    
    return null;
  }
  
  Entity _assemble(Map<String, dynamic> rawData, DormProxy owningProxy, Serializer serializer, OnConflictFunction onConflict) {
    final String refClassName = rawData[SerializationType.ENTITY_TYPE];
    final bool isDetached = rawData.containsKey(SerializationType.DETACHED);
    EntityRootScan entityScan;
    Entity spawnee, localNonPointerEntity;
    
    if (onConflict == null) onConflict = (Entity serverEntity, Entity clientEntity) => ConflictManager.ACCEPT_CLIENT;
    
    entityScan = _entityScans[refClassName];
    
    if (entityScan == null) throw new DormError('Scan for entity not found: $refClassName');
    
    spawnee = entityScan._unusedInstance;
    
    if (spawnee == null) spawnee = entityScan._entityCtor();
    else entityScan._unusedInstance = null;
    
    spawnee.readExternal(rawData, serializer, onConflict);
    
    if (isDetached) return spawnee;
    
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
    _DormProxyPropertyInfo entry, entryMatch;
    Entity entityCast;
    int i, j;
    
    if (onConflict == null) throw new DormError('Conflict was detected, but no onConflict method is available');
    
    conflictManager = onConflict(
        spawnee, 
        existingEntity
    );
    
    if (!spawnee.isMutable || (conflictManager == ConflictManager.ACCEPT_SERVER)) {
      entryProxies = existingEntity._scan._proxies;
      
      i = entryProxies.length;
      
      while (i > 0) {
        entry = entryProxies.elementAt(--i);
        
        entryMatch = spawnee._scan._proxies.firstWhere(
          (_DormProxyPropertyInfo E) => (entry.info.property == E.info.property),
          orElse: () => null
        );
        
        if (entryMatch != null) {
          entry.proxy.setInitialValue(existingEntity.notifyPropertyChange(entry.proxy._propertySymbol, entry.proxy._value, entryMatch.proxy._value));
          
          if (entry.proxy._value is Entity) {
            entityCast = entry.proxy._value as Entity;
            
            if (entityCast._isPointer) _pendingProxies.add(entry.proxy);
          } else if (entry.proxy._value is Iterable) _pendingProxies.add(entry.proxy);
        }
      }
    } else if (conflictManager == ConflictManager.ACCEPT_SERVER_DIRTY) {
      entryProxies = existingEntity._scan._proxies;
      
      i = entryProxies.length;
      
      while (i > 0) {
        entry = entryProxies.elementAt(--i);
        
        entryMatch = spawnee._scan._proxies.firstWhere(
          (_DormProxyPropertyInfo E) => (entry.info.property == E.info.property),
          orElse: () => null
        );
        
        if (entryMatch != null) {
          entry.proxy.value = existingEntity.notifyPropertyChange(entry.proxy._propertySymbol, entry.proxy._value, entryMatch.proxy._value);
          
          if (entry.proxy._value is Entity) {
            entityCast = entry.proxy._value as Entity;
            
            if (entityCast._isPointer) _pendingProxies.add(entry.proxy);
          } else if (entry.proxy._value is Iterable) _pendingProxies.add(entry.proxy);
        }
      }
    }
  }
  
  void _updateCollectionsWith(Entity actualEntity) {
    List<dynamic> collectionEntry;
    DormProxy proxy;
    Entity entity;
    dynamic listEntry;
    bool collectionEntryHasPointers;
    List entityList;
    int i = _pendingProxies.length, j;
    
    while (i > 0) {
      proxy = _pendingProxies[--i];
      
      if (proxy._value is Entity) {
        entity = proxy._value as Entity;
        
        if (EntityKeyChain.areSameKeySignature(entity._scan, actualEntity._scan)) {
          proxy.setInitialValue(actualEntity);
          
          _pendingProxies.remove(proxy);
        }
      } else if (proxy._value is Iterable) {
        entityList = proxy._value as List;
        
        j = entityList.length;
        
        bool hasPointers = false, containsEntities;
        
        while (j > 0) {
          listEntry = entityList[--j];
          
          containsEntities = (listEntry is Entity);
          
          if (
            containsEntities &&
            EntityKeyChain.areSameKeySignature(listEntry._scan, actualEntity._scan)
          ) entityList[j] = actualEntity;
          
          if (containsEntities && !hasPointers) hasPointers = (entityList[j] as Entity)._isPointer;
        }
        
        if (!hasPointers) _pendingProxies.remove(proxy);
      }
    }
  }
}