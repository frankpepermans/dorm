part of dorm;

class EntityManager {
  
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
  
  EntityManager._construct();
  
  //---------------------------------
  //
  // Factories
  //
  //---------------------------------
  
  static EntityManager _instance;

  factory EntityManager() {
    if (_instance == null) {
      _instance = new EntityManager._construct();
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
  
  Entity _spawn(Map<String, dynamic> rawData, OnConflictFunction onConflict) {
    final String type = rawData[SerializationType.ENTITY_TYPE];
    final Symbol typeSymbol = new Symbol(type);
    EntityScan scan;
    Entity entity, returningEntity;
    ConflictManager conflictManager;
    MethodMirror methodMirror;
    List<Entity> entityList;
    _ProxyEntry entry;
    String key;
    int i, j;
    dynamic entryValue;
    
    if (onConflict == null) {
      onConflict = _handleConflictAcceptClient;
    }
    
    i = _entityScans.length;
    
    while (i > 0) {
      scan = _entityScans[--i];
      
      if (scan.qualifiedName == typeSymbol) {
        methodMirror = scan.classMirror.constructors[scan.classMirror.simpleName];
        
        entity = scan.classMirror.newInstance(methodMirror.constructorName, []).reflectee;
        
        entity._isPointer = (rawData.containsKey(SerializationType.POINTER));
        
        j = entity._scan._proxies.length;
        
        while (j > 0) {
          entry = entity._scan._proxies[--j];
          
          entryValue = rawData[entry.property];
          
          if (entryValue is Map) {
            entry.proxy._initialValue = _spawn(entryValue, onConflict);
          } else if (entryValue is Iterable) {
            entityList = <Entity>[];
            
            entryValue.forEach(
                (Map<String, dynamic> listValue) {
                  entityList.add(_spawn(listValue, onConflict));
                }
            );
            
            entry.proxy.owner = entityList;
            
            entry.proxy._initialValue = entityList;
          } else {
            entry.proxy._initialValue = entryValue;
          }
        }
        
        key = _buildKey(entity);
        
        if (!entity._isPointer) {
          entity = _registerSpawnedEntity(
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
  
  Entity _registerSpawnedEntity(Entity entity, String type, String key, OnConflictFunction onConflict) {
    Map<String, Entity> typeRegistry;
    
    if (!_spawnRegistry.containsKey(type)) {
      _spawnRegistry[type] = new Map<String, Entity>();
    }
    
    typeRegistry = _spawnRegistry[type];
    
    if (typeRegistry.containsKey(key)) {
      if (typeRegistry[key].isDirty()) {
        if (onConflict == null) {
          throw new DormError('Conflict was detected, but no onConflict method is available');
        }
        
        ConflictManager conflictManager = onConflict(entity, typeRegistry[key]);
        
        if (conflictManager == ConflictManager.ACCEPT_CLIENT) {
          entity = typeRegistry[key];
        }
        
        _swapEntries(entity, key);
      }
    }
    
    typeRegistry[key] = entity;
    
    _swapPointers(entity, key);
    
    return entity;
  }
  
  void _swapPointers(Entity actualEntity, String key) {
    _proxyRegistry.forEach(
        (Proxy proxy) {
          if (proxy.owner != null) {
            proxy.owner.forEach(
                (dynamic entry) {
                  if (
                      (entry.runtimeType == actualEntity.runtimeType) && 
                      entry._isPointer &&
                      (_buildKey(entry) == key)
                  ) {
                    proxy.owner[proxy.owner.indexOf(entry)] = actualEntity;
                  }
                }
            );
          } else if (
              (proxy._value.runtimeType == actualEntity.runtimeType) && 
              proxy._value._isPointer &&
              (_buildKey(proxy._value) == key)
          ) {
            proxy._initialValue = actualEntity;
          }
        }
    );
  }
  
  void _swapEntries(Entity actualEntity, String key) {
    _proxyRegistry.forEach(
        (Proxy proxy) {
          if (proxy.owner != null) {
            proxy.owner.forEach(
                (dynamic entry) {
                  if (
                      (entry.runtimeType == actualEntity.runtimeType) && 
                      (_buildKey(entry) == key)
                  ) {
                    proxy.owner[proxy.owner.indexOf(entry)] = actualEntity;
                  }
                }
            );
          } else if (
              (proxy._value.runtimeType == actualEntity.runtimeType) && 
              (_buildKey(proxy._value) == key)
          ) {
            proxy._initialValue = actualEntity;
          }
        }
    );
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
  
  /*String _keyBuilder(_ProxyEntry entry) {
    String key;
    
    if (entry.proxy.value is Entity) {
      List<String> idList = <String>[];
      Entity entity = entry.proxy.value;
      
      entity._scan._proxies.forEach(
          (_ProxyEntry entry) {
            if (entry.proxy.isId) {
              idList.add('${entry.property}?${entry.proxy.value}');
            }
          }
      );
      
      key = idList.join('??');
    } else {
      key = '${entry.property}?${entry.proxy.value}';
    }
    
    return key;
  }*/
  
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
    InstanceMirror instanceMirror = reflect(entity);
    
    entity._scan = _getScanForInstance(entity);
    
    entity._scan._proxies.forEach(
      (_ProxyEntry entry) {
        Proxy proxy = new Proxy._construct(null, true);
        
        proxy.property = entry.property;
        proxy.propertySymbol = entry.propertySymbol;
        
        entry.mirror.metadata.forEach(
            (InstanceMirror metadata) {
              if (metadata.reflectee is Id) {
                proxy.isId = true;
              } else if (metadata.reflectee is Transient) {
                proxy.isTransient = true;
              } else if (metadata.reflectee is NotNullable) {
                proxy.isNullable = false;
              } else if (metadata.reflectee is DefaultValue) {
                proxy._initialValue = (metadata.reflectee as DefaultValue).value;
              } else if (metadata.reflectee is LabelField) {
                proxy.isLabelField = true;
              } else if (
                  !entity._scan.isMutableEntity ||
                  (metadata.reflectee is Immutable)
                ) {
                proxy.isMutable = false;
              }
            }
        );
        
        entry.proxy = proxy;
        
        _proxyRegistry.add(proxy);
        
        instanceMirror.setField(entry.symbol, proxy);
      }
    );
  }
  
  ConflictManager _handleConflictAcceptClient(Entity serverEntity, Entity clientEntity) {
    return ConflictManager.ACCEPT_CLIENT;
  }
}