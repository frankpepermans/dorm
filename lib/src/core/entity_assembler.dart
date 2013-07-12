part of dorm;

class EntityAssembler {
  
  //---------------------------------
  //
  // Private properties
  //
  //---------------------------------
  
  List<EntityScan> _entityScans = <EntityScan>[];
  List<Proxy> _proxyRegistry = <Proxy>[];
  Map<String, Map<String, Entity>> _spawnRegistry = new Map<String, Map<String, Entity>>();
  
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
  
  EntityScan scan(Type forType) {
    const Symbol entitySymbol = const Symbol('dorm.Entity');
    EntityScan scan = _getExistingScan(forType);
    InstanceMirror instanceMirror;
    int i;
    
    if(scan != null) {
      return scan;
    }
    
    scan = new EntityScan();
    
    scan.entityType = forType;
    
    Property property;
    ClassMirror classMirror = reflectClass(forType);
    List<InstanceMirror> metadata = <InstanceMirror>[];
    Map<Symbol, Mirror> members = new Map<Symbol, Mirror>();
    
    scan.classMirror = classMirror;
    
    classMirror.metadata.forEach(
        (InstanceMirror metadata) {
          if (metadata.reflectee is Ref) {
            scan.qualifiedName = new Symbol((metadata.reflectee as Ref).path);
            scan.qualifiedLocalName = (metadata.reflectee as Ref).path;
          }
        }
    );
    
    metadata.addAll(classMirror.metadata);
    members.addAll(classMirror.members);
    
    classMirror = classMirror.superclass;
    
    while (classMirror.qualifiedName != entitySymbol) {
      metadata.addAll(classMirror.metadata);
      members.addAll(classMirror.members);
      
      classMirror = classMirror.superclass;
    }
    
    i = metadata.length;
    
    while (i > 0) {
      instanceMirror = metadata[--i];
      
      if (instanceMirror.reflectee is Immutable) {
        scan.isMutableEntity = false;
        
        break;
      }
    }
    
    members.forEach(
      (Symbol symbol, Mirror mirror) {
        if (mirror is VariableMirror) {
          i = mirror.metadata.length;
          
          while (i > 0) {
            instanceMirror = mirror.metadata[--i];
            
            if (instanceMirror.reflectee is Property) {
              property = instanceMirror.reflectee as Property;
              
              scan.addProxy(
                  property.property, 
                  symbol, 
                  property.propertySymbol,
                  mirror
              );
            }
          }
        }
      }
    );
    
    _entityScans.add(scan);
    
    return scan;
  }
  
  //---------------------------------
  //
  // Library protected methods
  //
  //---------------------------------
  
  EntityScan _getScanForInstance(Entity entity) {
    EntityScan scan = _getExistingScan(entity.runtimeType);
    
    if(scan != null) {
      return new EntityScan.fromScan(scan);
    }
    
    throw new DormError('Scan for entity not found');
  }
  
  String _buildKey(Entity entity) {
    if (entity._scan.key != null) {
      return entity._scan.key;
    }
    
    List<String> idList = <String>[];
    
    entity._scan._proxies.forEach(
        (_ProxyEntry entry) {
          if (entry.proxy.isId) {
            idList.add('${entry.property}?${entry.proxy.value}');
          }
        }
    );
    
    entity._scan.key = idList.join('??');
    
    return entity._scan.key;
  }
  
  Entity _assemble(Map<String, dynamic> rawData, OnConflictFunction onConflict) {
    final String type = rawData[SerializationType.ENTITY_TYPE];
    final Symbol typeSymbol = new Symbol(type);
    EntityScan scan;
    Entity entity, returningEntity;
    InstanceMirror instanceMirror;
    MethodMirror methodMirror;
    String key;
    int i;
    
    if (onConflict == null) {
      onConflict = _handleConflictAcceptClient;
    }
    
    i = _entityScans.length;
    
    while (i > 0) {
      scan = _entityScans[--i];
      
      if (scan.qualifiedName == typeSymbol) {
        methodMirror = scan.classMirror.constructors[scan.classMirror.simpleName];
        
        instanceMirror = scan.classMirror.newInstance(methodMirror.constructorName, []);
        
        entity = instanceMirror.reflectee;
        entity._uid = entity.hashCode;
        entity._mirror = instanceMirror;
        entity._scan = _getScanForInstance(entity);
        
        _initialize(entity);
        
        entity.readExternal(rawData, onConflict);
        
        key = _buildKey(entity);
        
        if (!entity._isPointer) {
          entity = _registerSpawnedEntity(
              entity,
              _existingFromSpawnRegistry(type, key, entity), 
              type, key, onConflict
          );
          
          returningEntity = entity;
        } else {
          returningEntity = _existingFromSpawnRegistry(type, key, entity);
        }
        
        return returningEntity;
      }
    }
    
    throw new DormError('Scan for entity not found');
    
    return null;
  }
  
  Entity _registerSpawnedEntity(Entity spawnee, Entity existingEntity, String type, String key, OnConflictFunction onConflict) {
    ConflictManager conflictManager;
    Map<String, Entity> typeRegistry;
    List<_ProxyEntry> entryProxies;
    List<_ProxyEntry> spawneeProxies;
    _ProxyEntry entryA, entryB;
    int i, j;
    
    if (!_spawnRegistry.containsKey(type)) {
      _spawnRegistry[type] = new Map<String, Entity>();
    }
    
    typeRegistry = _spawnRegistry[type];
    
    if (spawnee != existingEntity) {
      if (onConflict == null) {
        throw new DormError('Conflict was detected, but no onConflict method is available');
      }
      
      conflictManager = onConflict(spawnee, typeRegistry[key]);
      
      if (conflictManager == ConflictManager.ACCEPT_SERVER) {
        entryProxies = existingEntity._scan._proxies;
        
        i = entryProxies.length;
        
        while (i > 0) {
          entryA = entryProxies[--i];
          
          spawneeProxies = spawnee._scan._proxies;
          
          j = spawneeProxies.length;
          
          while (j > 0) {
            entryB = spawneeProxies[--j];
            
            if (entryA.propertySymbol == entryB.propertySymbol) {
              entryA.proxy._initialValue = existingEntity.notifyPropertyChange(entryA.proxy.propertySymbol, entryA.proxy._value, entryB.proxy._value);
              
              _proxyRegistry.remove(entryB.proxy);
              
              break;
            }
          }
        }
      }
      
      _swapEntries(existingEntity, key);
    }
    
    typeRegistry[key] = existingEntity;
    
    _swapPointers(existingEntity, key);
    
    return existingEntity;
  }
  
  void _swapPointers(Entity actualEntity, String key) {
    Proxy proxy;
    int i = _proxyRegistry.length;
    
    while (i > 0) {
      proxy = _proxyRegistry[--i];
      
      if (proxy.owner != null) {
        proxy.owner.forEach(
            (dynamic entry) {
              if (_areEqualByKey(entry, actualEntity, key)) {
                proxy.owner[proxy.owner.indexOf(entry)] = actualEntity;
              }
            }
        );
      } else if (_areEqualByKey(proxy._value, actualEntity, key)) {
        proxy._initialValue = actualEntity;
      }
    }
  }
  
  void _swapEntries(Entity actualEntity, String key) {
    Proxy proxy;
    int i = _proxyRegistry.length;
    
    while (i > 0) {
      proxy = _proxyRegistry[--i];
      
      if (proxy.owner != null) {
        proxy.owner.forEach(
            (dynamic entry) {
              if (_areEqualByKey(entry, actualEntity, key)) {
                proxy.owner[proxy.owner.indexOf(entry)] = actualEntity;
              }
            }
        );
      } else if (_areEqualByKey(proxy._value, actualEntity, key)) {
        proxy._initialValue = actualEntity;
      }
    }
  }
  
  Entity _existingFromSpawnRegistry(String type, String key, Entity entity) {
    Map<String, Entity> typeRegistry;
    
    if (!_spawnRegistry.containsKey(type)) {
      _spawnRegistry[type] = new Map<String, Entity>();
    }
    
    typeRegistry = _spawnRegistry[type];
    
    if (typeRegistry.containsKey(key)) {
      Entity registeredEntity = typeRegistry[key];
      
      if (!registeredEntity._isPointer) {
        return registeredEntity;
      }
    }
    
    return entity;
  }
  
  List<Type> _reflectedTypes = new List<Type>();
  
  EntityScan _getExistingScan(Type forType) {
    EntityScan scan;
    int i = _entityScans.length;
    
    while (i > 0) {
      scan = _entityScans[--i];
      
      if (scan.entityType == forType) {
        return scan;
      }
    }
    
    return null;
  }
  
  void _initialize(Entity entity) {
    _ProxyEntry entry;
    Proxy proxy;
    InstanceMirror metadata;
    List<InstanceMirror> instanceMirrors;
    List<_ProxyEntry> proxyEntryList = entity._scan._proxies;
    dynamic reflectee;
    int i = proxyEntryList.length;
    int j;
    
    while (i > 0) {
      entry = proxyEntryList[--i];
      
      proxy = new Proxy._construct(null, true)
      ..property = entry.property
      ..propertySymbol = entry.propertySymbol;
      
      instanceMirrors = entry.mirror.metadata;
      
      j = instanceMirrors.length;
      
      while (j > 0) {
        metadata = instanceMirrors[--j];
        
        reflectee = metadata.reflectee;
        
        if (reflectee is Id) {
          proxy.isId = true;
        } else if (reflectee is Transient) {
          proxy.isTransient = true;
        } else if (reflectee is NotNullable) {
          proxy.isNullable = false;
        } else if (reflectee is DefaultValue) {
          proxy._initialValue = (reflectee as DefaultValue).value;
        } else if (reflectee is LabelField) {
          proxy.isLabelField = true;
        } else if (
            !entity._scan.isMutableEntity ||
            (reflectee is Immutable)
        ) {
          proxy.isMutable = false;
        }
      }
      
      entry.proxy = proxy;
      
      _proxyRegistry.add(proxy);
      
      entity._mirror.setField(entry.symbol, proxy);
    }
  }
  
  bool _areEqualByKey(dynamic instance, Entity compareEntity, String key) {
    Entity entity;
    
    if (instance is Entity) {
      entity = instance as Entity;
      
      return (
          entity._isPointer &&
          (entity._scan.qualifiedLocalName == compareEntity._scan.qualifiedLocalName) && 
          (_buildKey(entity) == key)
      );
    }
    
    return false;
  }
  
  ConflictManager _handleConflictAcceptClient(Entity serverEntity, Entity clientEntity) {
    return ConflictManager.ACCEPT_CLIENT;
  }
}