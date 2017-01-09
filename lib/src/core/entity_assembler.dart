part of dorm;

///
/// This class is a singleton, you may obtain the instance at any time in the following manner :
///
///     main() {
///       EntityAssembler assemblerSingletonInstance = new EntityAssembler();
///     }
///
/// While it is possible to create an [Entity] directly with the assembler, you should use [EntityFactory]
/// with your services to facilitate this.
///
/// The assembler is responsible for the creation of an [Entity] and also continues to maintain it afterwards.
/// As soon as an [Entity] is created, it will be stored in the [EntityKeyChain] chain,
/// should the same [Entity] then at a later time be reloaded in any way,
/// then the assembler will choose to update it in the case of ConflictManager.ACCEPT_SERVER
/// or keep the client [Entity] unchanged in case of ConflictManager.ACCEPT_CLIENT.
/// This [ConflictManager] should be passed with the main spawn function of the [EntityFactory]
///
class EntityAssembler {
  
  //---------------------------------
  //
  // Private properties
  //
  //---------------------------------
  
  final Map<String, EntityRootScan> _entityScans = <String, EntityRootScan>{};
  
  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------

  bool usePointers = true;
  
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
  
  void registerProxies(Entity entity, List<DormProxy<dynamic>> proxies) {
    if (entity._scan == null) entity._scan = _createEntityScan(entity);
    
    if (entity._scan == null) return;
    
    final EntityScan scan = entity._scan;
    DormProxy<dynamic> proxy;
    _DormProxyPropertyInfo<_DormPropertyInfo> I;
    bool hasUnknownMapping = false;
    
    for (int i=0, len=proxies.length; i<len; i++) {
      proxy = proxies[i];
      
      I = scan._proxyMap[proxy._property];
      
      if (!scan._root._hasMapping) {
        if (!hasUnknownMapping) hasUnknownMapping = (scan._root._propertyToSymbol[proxy._property] == null);
        
        scan._root._propertyToSymbol[proxy._property] = proxy._propertySymbol;
        scan._root._symbolToProperty[proxy._propertySymbol] = proxy._property;
      }
      
      if (I != null) proxy._updateWithMetadata(
        I..proxy = proxy, 
        scan
      );
    }
    
    scan._root._hasMapping = !hasUnknownMapping;
  }
  
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
  
  Entity _assemble(Map<String, dynamic> rawData, DormProxy<dynamic> owningProxy, Serializer<dynamic, Map<String, dynamic>> serializer, OnConflictFunction onConflict, String forType) {
    final String refClassName = _fetchRefClassName(rawData, forType);
    final bool isDetached = (rawData[SerializationType.DETACHED] != null);
    Entity spawnee;
    
    if (onConflict == null) onConflict = (Entity serverEntity, Entity clientEntity) => ConflictManager.AcceptClient;
    
    spawnee = spawn(refClassName);
    
    spawnee.readExternal(rawData, serializer, onConflict);
    
    if (isDetached) return spawnee;
    
    final bool isSpawneeUnsaved = spawnee.isUnsaved();
    
    if (isSpawneeUnsaved) return spawnee;
    
    return spawnee;
  }
}