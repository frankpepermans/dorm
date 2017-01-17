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
  
  EntityRootScan scan(String refClassName, Entity constructorMethod(), List<PropertyData> meta) {
    EntityRootScan scan = _entityScans[refClassName];
    
    scan ??= _entityScans[refClassName] = new EntityRootScan(refClassName, constructorMethod);

    for (int i=0, len=meta.length; i<len; i++) scan.registerMetadataUsing(meta[i]);
    
    return scan;
  }
  
  void registerProxies(Entity entity, List<DormProxy<dynamic>> proxies) {
    entity._scan ??= _createEntityScan(entity);

    bool hasUnknownMapping = false;
    
    for (int i=0, len=proxies.length; i<len; i++) {
      DormProxy<dynamic> proxy = proxies[i];
      _DormProxyPropertyInfo<dynamic> I = entity._scan._proxyMap[proxy._property];
      
      if (!entity._scan._root._hasMapping) {
        if (!hasUnknownMapping) hasUnknownMapping = (entity._scan._root._propertyToSymbol[proxy._property] == null);

        entity._scan._root._propertyToSymbol[proxy._property] = proxy._propertySymbol;
        entity._scan._root._symbolToProperty[proxy._propertySymbol] = proxy._property;
      }
      
      if (I != null) {
        I.proxy = proxy;

        proxy._updateWithMetadata(I.info.metadataCache);
      }
    }

    entity._scan._root._hasMapping = !hasUnknownMapping;
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
  
  Entity spawn(String refClassName) {
    final EntityRootScan entityScan = _entityScans[refClassName];
    
    if (entityScan == null) throw new DormError('Scan for entity not found: $refClassName');
    
    return entityScan._entityCtor();
  }

  Entity _assemble(Map<String, dynamic> rawData, DormProxy<dynamic> owningProxy, Serializer<dynamic, Map<String, dynamic>> serializer)
    => spawn(rawData[SerializationType.ENTITY_TYPE])..readExternal(rawData, serializer);
}