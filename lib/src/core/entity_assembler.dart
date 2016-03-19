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
  
  EntityRootScan scan(String refClassName, Entity constructorMethod(), List<Map<String, dynamic>> meta, bool isMutable) {
    EntityRootScan scan = _entityScans[refClassName];
    
    if(scan == null)
      scan = _entityScans[refClassName] = new EntityRootScan(refClassName, constructorMethod)..isMutableEntity = isMutable;
    
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
    bool hasUnknownMapping = false;
    
    for (int i=0, len=proxies.length; i<len; i++) {
      proxy = proxies[i];
      
      I = scan._proxyMap[proxy._property];
      
      if (!scan._root._hasMapping) {
        if (!hasUnknownMapping) hasUnknownMapping = (scan._root._propertyToSymbol[proxy._property] == null);
        
        scan._root._propertyToSymbol[proxy._property] = proxy._propertySymbol;
        scan._root._symbolToProperty[proxy._propertySymbol] = proxy._property;
        
        if (!scan._root._amfSeq.contains(proxy._property)) scan._root._amfSeq.add(proxy._property);
      }
      
      if (I != null) proxy._updateWithMetadata(
        I..proxy = proxy, 
        scan
      );
      
      if (proxy.isLazy) proxy._isLazyLoadingRequired = true;
    }
    
    scan._root._hasMapping = !hasUnknownMapping;
  }
  
  Entity registerNewEntity(Entity spawnee, OnConflictFunction onConflict, {bool registerKeyInChain: true, bool solveConflicts: true}) {
    spawnee._scan.buildKey();
    
    if (registerKeyInChain) spawnee._scan._keyChain.entityScans.add(spawnee._scan);
    
    final Entity actualEntity = _handleExistingEntity(spawnee, onConflict, solveConflicts: solveConflicts);
    
    if (registerKeyInChain && spawnee != actualEntity) {
      spawnee._scan._keyChain.entityScans.remove(spawnee._scan);
      
      _updateCollectionsWith(actualEntity);
    }
    
    return actualEntity;
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
  
  void clearAll() => _entityScans.forEach(
    (_, EntityRootScan ERS) => ERS.clearKey()
  );
  
  //---------------------------------
  //
  // Library protected methods
  //
  //---------------------------------
  
  EntityScan _createEntityScan(Entity entity) {
    final EntityRootScan scan = _entityScans[entity.refClassName];
    
    if(scan != null) return new EntityScan.fromRootScan(scan, entity);
    
    return null;
  }
  
  String _fetchRefClassName(Map<String, dynamic> rawData, String forType) {
    String refClassName = rawData[SerializationType.ENTITY_TYPE];
    
    if (refClassName == null) {
      final List<String> S = forType.split('<');
      
      if (S.length > 1) refClassName = S.last.split('>').first;
      else refClassName = forType;
    }
    
    return refClassName;
  }
  
  Entity spawn(String refClassName) {
    final EntityRootScan entityScan = _entityScans[refClassName];
    
    if (entityScan == null) throw new DormError('Scan for entity not found: $refClassName');
    
    Entity spawnee = entityScan._unusedInstance;
    
    if (spawnee == null) spawnee = entityScan._entityCtor();
    else entityScan._unusedInstance = null;
    
    return spawnee;
  }
  
  Entity _assemble(Map<String, dynamic> rawData, DormProxy owningProxy, Serializer serializer, OnConflictFunction onConflict, String forType) {
    final String refClassName = _fetchRefClassName(rawData, forType);
    final bool isDetached = (rawData[SerializationType.DETACHED] != null);
    Entity spawnee, existingEntity;
    
    if (onConflict == null) onConflict = (Entity serverEntity, Entity clientEntity) => ConflictManager.AcceptClient;
    
    spawnee = spawn(refClassName);
    
    spawnee.readExternal(rawData, serializer, onConflict);
    
    if (isDetached) return spawnee;
    
    final bool isSpawneeUnsaved = spawnee.isUnsaved();
    
    if (isSpawneeUnsaved) {
      if (spawnee._isPointer) throw new DormError('Ambiguous reference, entity is unsaved and is also a pointer [${rawData}]');
      else return spawnee;
    }
    
    existingEntity = registerNewEntity(spawnee, onConflict, registerKeyInChain: false);
    
    if (existingEntity != spawnee) {
      _entityScans[refClassName]._unusedInstance = spawnee;
      
      return existingEntity;
    }
    
    if (spawnee._isPointer) {
      if (owningProxy != null) _pendingProxies.add(owningProxy);
    } else {
      spawnee._scan._keyChain.entityScans.add(spawnee._scan);
      
      _updateCollectionsWith(spawnee);
    }
    
    return spawnee;
  }
  
  Entity _handleExistingEntity(Entity spawnee, OnConflictFunction onConflict, {bool solveConflicts: true}) {
    final Entity localNonPointerEntity = EntityKeyChain.getFirstSibling(spawnee._scan, allowPointers: false);
    
    if (
        !spawnee._isPointer &&
        (localNonPointerEntity != null)
    ) {
      if (solveConflicts) _solveConflictsIfAny(
          spawnee,
          localNonPointerEntity, 
          onConflict
      );
      
      return localNonPointerEntity;
    }
    
    return spawnee;
  }
  
  void _solveConflictsIfAny(Entity spawnee, Entity existingEntity, OnConflictFunction onConflict) {
    ConflictManager conflictManager;
    Iterable<_DormProxyPropertyInfo> entryProxies;
    _DormProxyPropertyInfo entry, entryMatch;
    Entity entityCast;
    
    if (onConflict == null) throw new DormError('Conflict was detected, but no onConflict method is available');
    
    conflictManager = onConflict(
        spawnee, 
        existingEntity
    );
    
    if (conflictManager == ConflictManager.Ignore) return;
    
    if (!spawnee.isMutable || (conflictManager == ConflictManager.AcceptServer)) {
      entryProxies = existingEntity._scan._proxies;
      
      final int len=entryProxies.length;
      
      for (int i=0; i<len; i++) {
        entry = entryProxies.elementAt(i);
        
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
    } else if (conflictManager == ConflictManager.AcceptServerDirty) {
      entryProxies = existingEntity._scan._proxies;
      
      for (int i=0, len=entryProxies.length; i<len; i++) {
        entry = entryProxies.elementAt(i);
        
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
    final int len = _pendingProxies.length;
    DormProxy proxy;
    Entity entity;
    dynamic listEntry;
    
    for (int i=0; i<len; i++) {
      proxy = _pendingProxies[i];
      
      if (proxy._value is Entity) {
        entity = proxy._value as Entity;
        
        if (EntityKeyChain.areSameKeySignature(entity._scan, actualEntity._scan)) {
          proxy.setInitialValue(actualEntity);
          
          _pendingProxies.remove(proxy);
        }
      } else if (proxy._value is List) {
        final int len=proxy._value.length;
        bool hasPointers = false, containsEntities = false;
        
        for (int j=0; j<len; j++) {
          listEntry = proxy._value[j];
          
          if (!containsEntities) containsEntities = (listEntry is Entity);
          
          if (
            containsEntities &&
            EntityKeyChain.areSameKeySignature(listEntry._scan, actualEntity._scan)
          ) proxy._value[j] = actualEntity;
          
          if (containsEntities && !hasPointers) hasPointers = listEntry._isPointer;
        }
        
        if (
            !hasPointers && 
            (
                (proxy._resultLen == -1) || (proxy._resultLen == len)
            )
        ) _pendingProxies.remove(proxy);
      }
    }
  }
}