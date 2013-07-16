part of dorm;

class EntityAssembler {
  
  //---------------------------------
  //
  // Private properties
  //
  //---------------------------------
  
  final List<EntityScan> _entityScans = <EntityScan>[];
  final List<DormProxy> _proxyRegistry = <DormProxy>[];
  final List<SpawnEntry> _spawnRegistry = <SpawnEntry>[];
  
  int _proxyCount = 0;
  
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
    const Symbol entitySymbol = const Symbol('dorm.Entity');
    EntityScan scan = _getExistingScan(refClassName);
    
    if(scan != null) {
      return scan;
    }
    
    scan = new EntityScan()
    ..refClassName = refClassName
    ..contructorMethod = constructorMethod;
    
    ClassMirror classMirror = reflectClass(forType);
    
    Map<Symbol, Mirror> members = new Map<Symbol, Mirror>.from(classMirror.members);
    
    classMirror = classMirror.superclass;
    
    while (classMirror.qualifiedName != entitySymbol) {
      members.addAll(classMirror.members);
      
      classMirror = classMirror.superclass;
    }
    
    members.forEach(
      (Symbol symbol, Mirror mirror) {
        if (mirror is VariableMirror) {
          InstanceMirror instanceMirror;
          Property property;
          int i = mirror.metadata.length;
          int j;
          bool isIdentity;
          dynamic metatag;
          
          while (i > 0) {
            instanceMirror = mirror.metadata[--i];
            
            if (instanceMirror.reflectee is Property) {
              property = instanceMirror.reflectee as Property;
              
              isIdentity = false;
              
              j = mirror.metadata.length;
              
              while (j > 0) {
                metatag = mirror.metadata[--j].reflectee;
                
                scan.metadataCache.registerTagForProperty(property.property, metatag);
                
                if (metatag is Id) {
                  isIdentity = true;
                }
              }
              
              scan.addProxy(property, isIdentity);
            }
          }
        }
      }
    );
    
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
          PropertyMetadataCache propertyMetadataCache = scan.metadataCache.obtainTagForProperty(proxy.property);
          
          proxy.isId = propertyMetadataCache.isId;
          proxy.isTransient = propertyMetadataCache.isTransient;
          proxy.isNullable = propertyMetadataCache.isNullable;
          proxy.isLabelField = propertyMetadataCache.isLabelField;
          proxy.isMutable = (scan.isMutableEntity && propertyMetadataCache.isMutable);
          
          proxy._initialValue = propertyMetadataCache.initialValue;
          
          entry.proxy = proxy;
          
          entity._proxies.add(proxy);
          
          _proxyRegistry.add(proxy);
          
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
    Entity entity, returningEntity;
    int i, j;
    
    if (onConflict == null) {
      onConflict = _handleConflictAcceptClient;
    }
    
    i = _entityScans.length;
    
    while (i > 0) {
      scan = _entityScans[--i];
      
      if (scan.refClassName == refClassName) {
        entity = scan.contructorMethod();
        
        entity.readExternal(rawData, onConflict);
        entity.changes.listen(entity._identityKeyListener);
        
        returningEntity = _existingFromSpawnRegistry(refClassName, entity._scan.key, entity);
        
        if (!entity._isPointer) {
          entity = _registerSpawnedEntity(
              entity,
              returningEntity, 
              refClassName, onConflict
          );
          
          returningEntity = entity;
        } else if (returningEntity._isPointer) {
          _proxyCount++;
        }
        
        return returningEntity;
      }
    }
    
    throw new DormError('Scan for entity not found');
    
    return null;
  }
  
  Entity _registerSpawnedEntity(Entity spawnee, Entity existingEntity, String refClassName, OnConflictFunction onConflict) {
    ConflictManager conflictManager;
    List<_ProxyEntry> entryProxies;
    List<_ProxyEntry> spawneeProxies;
    SpawnEntry entry = _getSpawnRegistryForRefClassName(refClassName);
    _ProxyEntry entryA, entryB;
    int i, j;
    
    if (spawnee != existingEntity) {
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
              
              _proxyRegistry.remove(entryB.proxy);
              
              break;
            }
          }
        }
      } else if (conflictManager == ConflictManager.ACCEPT_CLIENT) {
        spawneeProxies = spawnee._scan._proxies;
        
        i = spawneeProxies.length;
        
        while (i > 0) {
          _proxyRegistry.remove(spawneeProxies[--i].proxy);
        }
      }
      
      _swapEntries(existingEntity);
    }
    
    if (!entry.entities.contains(existingEntity)) {
      entry.entities.add(existingEntity);
    }
    
    _swapPointers(existingEntity);
    
    return existingEntity;
  }
  
  void _swapPointers(Entity actualEntity) {
    if (_proxyCount == 0) {
      return;
    }
    
    DormProxy proxy;
    int i = _proxyRegistry.length;
    
    while (i > 0) {
      proxy = _proxyRegistry[--i];
      
      if (proxy.owner != null) {
        proxy.owner.forEach(
            (dynamic entry) {
              if (_areEqualByKey(entry, actualEntity)) {
                _proxyCount--;
                
                proxy.owner[proxy.owner.indexOf(entry)] = actualEntity;
              }
            }
        );
      } else if (_areEqualByKey(proxy._value, actualEntity)) {
        _proxyCount--;
        
        proxy._initialValue = actualEntity;
      }
    }
  }
  
  void _swapEntries(Entity actualEntity) {
    DormProxy proxy;
    int i = _proxyRegistry.length;
    
    while (i > 0) {
      proxy = _proxyRegistry[--i];
      
      if (proxy.owner != null) {
        proxy.owner.forEach(
            (dynamic entry) {
              if (_areEqualByKey(entry, actualEntity)) {
                proxy.owner[proxy.owner.indexOf(entry)] = actualEntity;
              }
            }
        );
      } else if (_areEqualByKey(proxy._value, actualEntity)) {
        proxy._initialValue = actualEntity;
      }
    }
  }
  
  Entity _existingFromSpawnRegistry(String refClassName, _ProxyKey key, Entity entity) {
    Entity registeredEntity;
    
    registeredEntity = _getSpawnRegistryForRefClassName(refClassName).entities.firstWhere(
        (Entity lookup) => (lookup._scan.key == key),
        orElse: () => null
    );
    
    if (
        (registeredEntity != null) &&
        !registeredEntity._isPointer
    ) {
      return registeredEntity;
    }
    
    return entity;
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
  
  SpawnEntry _getSpawnRegistryForRefClassName(String refClassName) {
    return _spawnRegistry.firstWhere(
        (SpawnEntry registryEntry) => (registryEntry.refClassName == refClassName),
        orElse: () {
          SpawnEntry registryEntry = new SpawnEntry(refClassName);
          
          _spawnRegistry.add(registryEntry);
          
          return registryEntry;
        }
    );
  }
  
  bool _areEqualByKey(dynamic instance, Entity compareEntity) {
    Entity entity;
    
    if (instance is Entity) {
      entity = instance as Entity;
      
      return (
          entity._isPointer &&
          entity._scan.equalsBasedOnRefAndKey(compareEntity._scan)
      );
    }
    
    return false;
  }
  
  ConflictManager _handleConflictAcceptClient(Entity serverEntity, Entity clientEntity) {
    return ConflictManager.ACCEPT_CLIENT;
  }
}

class SpawnEntry {
  
  final String refClassName;
  final List<Entity> entities = <Entity>[];
  
  SpawnEntry(this.refClassName);
  
}