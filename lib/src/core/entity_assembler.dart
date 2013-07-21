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
 * As soon as an [Entity] is created, it will be stored in the [EntityKey] chain,
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
  
  final List<EntityScan> _entityScans = <EntityScan>[];
  final List<List<dynamic>> _collections = <List<dynamic>>[];
  final List<DormProxy> _pendingProxies = <DormProxy>[];
  final EntityKey _keyChain = new EntityKey();
  
  ConflictManager _handleConflictAcceptClient(Entity serverEntity, Entity clientEntity) => ConflictManager.ACCEPT_CLIENT;
  
  //---------------------------------
  //
  // Singleton Constructor
  //
  //---------------------------------
  
  EntityAssembler._construct();
  
  //---------------------------------
  //
  // Factories
  //
  //---------------------------------
  
  static EntityAssembler _instance;

  factory EntityAssembler() {
    if (_instance == null) {
      _instance = new EntityAssembler._construct();
    }

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
  EntityScan scan(Type forType, String refClassName, Function constructorMethod) {
    EntityScan scan = _existingFromScanRegistry(refClassName);
    
    if(scan != null) return scan;
    
    scan = new EntityScan(refClassName, constructorMethod);
    
    ClassMirror classMirror = reflectClass(forType);
    List<Mirror> members = new List<Mirror>.from(classMirror.members.values);
    
    classMirror = classMirror.superclass;
    
    while (classMirror.qualifiedName != ENTITY_SYMBOL) {
      members.addAll(classMirror.members.values);
      
      classMirror = classMirror.superclass;
    }
    
    Mirror mirror;
    int i = members.length;
    
    while (i > 0) {
      mirror = members[--i];
      
      if (mirror is VariableMirror) scan.registerMetadataUsing(mirror);
    }
    
    _entityScans.add(scan);
    
    return scan;
  }
  
  void registerProxies(Entity entity, List<DormProxy> proxies) {
    _ProxyEntry entry;
    DormProxy proxy;
    
    if (entity._uid == null) {
      entity._uid = entity.hashCode;
      entity._scan = _createEntityScan(entity);
    }
    
    EntityScan scan = entity._scan;
    List<_ProxyEntry> proxyEntryList = scan._proxies;
    int i = proxyEntryList.length;
    int j;
    
    while (i > 0) {
      entry = proxyEntryList[--i];
      
      j = proxies.length;
      
      while (j > 0) {
        proxy = proxies[--j];
        
        if (entry.property == proxy.property) {
          scan.updateProxyWithMetadata(proxy);
          
          entry.proxy = proxy;
          
          entity._proxies.add(proxy);
          
          proxies.remove(proxy);
          
          break;
        }
      }
    }
  }
  
  //---------------------------------
  //
  // Library protected methods
  //
  //---------------------------------
  
  EntityScan _createEntityScan(Entity entity) {
    EntityScan scan = _existingFromScanRegistry(entity.refClassName);
    
    if(scan != null) return new EntityScan.fromScan(scan, entity);
    
    throw new DormError('Scan for entity not found');
  }
  
  Entity _assemble(Map<String, dynamic> rawData, DormProxy owningProxy, Serializer serializer, OnConflictFunction onConflict) {
    final String refClassName = rawData[SerializationType.ENTITY_TYPE];
    EntityScan scan;
    Entity spawnee, localNonPointerEntity;
    DormProxy proxy;
    List<_ProxyEntry> entityProxies;
    List<DormProxy> propProxies;
    int i, j;
    
    if (onConflict == null) onConflict = _handleConflictAcceptClient;
    
    i = _entityScans.length;
    
    while (i > 0) {
      scan = _entityScans[--i];
      
      if (scan.refClassName == refClassName) {
        spawnee = scan._contructorMethod();
        
        spawnee.readExternal(rawData, serializer, onConflict);
        spawnee._scan.buildKey();
        
        localNonPointerEntity = _existingFromSpawnRegistry(spawnee);
        
        _solveConflictsIfAny(
            spawnee,
            localNonPointerEntity, 
            onConflict
        );
        
        if (localNonPointerEntity != null) {
          _keyChain.remove(spawnee);
          
          return localNonPointerEntity;
        }
        
        if (spawnee._isPointer) {
          if (owningProxy != null) {
            _pendingProxies.add(owningProxy);
          }
          
          _keyChain.remove(spawnee);
        } else {
          propProxies = spawnee._proxies;
          
          j = propProxies.length;
          
          while (j > 0) {
            proxy = propProxies[--j];
            
            if (proxy.owner != null) {
              _collections.add(proxy.owner);
            }
          }
          
          _updateCollectionsWith(spawnee);
        }
        
        return spawnee;
      }
    }
    
    throw new DormError('Scan for entity not found');
    
    return null;
  }
  
  void _solveConflictsIfAny(Entity spawnee, Entity existingEntity, OnConflictFunction onConflict) {
    if (
        spawnee._isPointer ||
        (existingEntity == null)
    ) return;
    
    ConflictManager conflictManager;
    List<_ProxyEntry> entryProxies;
    List<_ProxyEntry> spawneeProxies;
    _ProxyEntry entryA, entryB;
    int i, j;
    
    if (onConflict == null) throw new DormError('Conflict was detected, but no onConflict method is available');
    
    conflictManager = onConflict(
        spawnee, 
        existingEntity
    );
    
    if (conflictManager == ConflictManager.ACCEPT_SERVER) {
      entryProxies = existingEntity._scan._proxies;
      
      i = entryProxies.length;
      
      while (i > 0) {
        entryA = entryProxies[--i];
        
        spawneeProxies = spawnee._scan._proxies;
        
        j = spawneeProxies.length;
        
        while (j > 0) {
          entryB = spawneeProxies[--j];
          
          if (entryA.property == entryB.property) {
            entryA.proxy._initialValue = existingEntity.notifyPropertyChange(entryA.proxy.propertySymbol, entryA.proxy._value, entryB.proxy._value);
            
            break;
          }
        }
      }
    }
  }
  
  void _updateCollectionsWith(Entity actualEntity) {
    List<dynamic> collectionEntry;
    DormProxy proxy;
    bool collectionEntryHasPointers;
    int i = _pendingProxies.length;
    
    while (i > 0) {
      proxy = _pendingProxies[--i];
      
      if (_keyChain.areSameKeySignature(proxy._value, actualEntity)) {
        proxy._initialValue = actualEntity;
        
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
              if (_keyChain.areSameKeySignature(entry, actualEntity)) {
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
  
  Entity _existingFromSpawnRegistry(Entity entity) {
    Entity registeredEntity = _keyChain.getFirstSibling(entity);
    
    return (
        (registeredEntity != null) &&
        !registeredEntity._isPointer
    ) ? registeredEntity : null;
  }
  
  EntityScan _existingFromScanRegistry(String refClassName) {
    return _entityScans.firstWhere(
      (EntityScan scan) => (scan.refClassName == refClassName),
      orElse: () => null
    );
  }
}