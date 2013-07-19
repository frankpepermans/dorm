part of dorm;

class EntityAssembler {
  
  //---------------------------------
  //
  // Private properties
  //
  //---------------------------------
  
  static const Symbol ENTITY_SYMBOL = const Symbol('dorm.Entity');
  
  final List<EntityScan> _entityScans = <EntityScan>[];
  final List<List<dynamic>> _collections = <List<dynamic>>[];
  final EntityKey _keyChain = new EntityKey();
  
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
  
  EntityScan scan(Type forType, String refClassName, Function constructorMethod) {
    EntityScan scan = _getExistingScan(refClassName);
    
    if(scan != null) {
      return scan;
    }
    
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
      entity._scan = _getScanForInstance(entity);
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
  
  EntityScan _getScanForInstance(Entity entity) {
    EntityScan scan = _getExistingScan(entity.refClassName);
    
    if(scan != null) {
      return new EntityScan.fromScan(scan, entity);
    }
    
    throw new DormError('Scan for entity not found');
  }
  
  Entity _assemble(Map<String, dynamic> rawData, OnConflictFunction onConflict) {
    final String refClassName = rawData[SerializationType.ENTITY_TYPE];
    EntityScan scan;
    Entity spawnee, localNonPointerEntity;
    DormProxy proxy;
    List<_ProxyEntry> entityProxies;
    List<DormProxy> propProxies;
    int i, j;
    
    if (onConflict == null) {
      onConflict = _handleConflictAcceptClient;
    }
    
    i = _entityScans.length;
    
    while (i > 0) {
      scan = _entityScans[--i];
      
      if (scan.refClassName == refClassName) {
        spawnee = scan._contructorMethod();
        
        spawnee.readExternal(rawData, onConflict);
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
    ) {
      return;
    }
    
    ConflictManager conflictManager;
    List<_ProxyEntry> entryProxies;
    List<_ProxyEntry> spawneeProxies;
    _ProxyEntry entryA, entryB;
    int i, j;
    
    if (onConflict == null) {
      throw new DormError('Conflict was detected, but no onConflict method is available');
    }
    
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
    int i = _collections.length;
    
    while (i > 0) {
      collectionEntry = _collections[--i];
      
      collectionEntry.forEach(
          (dynamic entry) {
            if (
                (entry is Entity) &&
                _keyChain.areSameKeySignature(entry, actualEntity)
            ) {
              collectionEntry[collectionEntry.indexOf(entry)] = actualEntity;
            }
          }
      );
    }
  }
  
  Entity _existingFromSpawnRegistry(Entity entity) {
    Entity registeredEntity = _keyChain.getExistingEntity(entity);
    
    if (
        (registeredEntity != null) &&
        !registeredEntity._isPointer
    ) {
      return registeredEntity;
    }
    
    return null;
  }
  
  EntityScan _getExistingScan(String refClassName) {
    EntityScan scan;
    int i = _entityScans.length;
    
    while (i > 0) {
      scan = _entityScans[--i];
      
      if (scan.refClassName == refClassName) {
        return scan;
      }
    }
    
    return null;
  }
  
  ConflictManager _handleConflictAcceptClient(Entity serverEntity, Entity clientEntity) {
    return ConflictManager.ACCEPT_CLIENT;
  }
}