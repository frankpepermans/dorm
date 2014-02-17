part of dorm;

class EntityRootScan {
  
  final EntityKeyChain _rootKeyChain = new EntityKeyChain();
  final EntityCtor _entityCtor;
  MetadataCache _metadataCache;
  List<Entity> _unusedInstances = new List<Entity>();
  
  final String refClassName;
  bool isMutableEntity = true;
  
  final List<_DormPropertyInfo> _rootProxies = <_DormPropertyInfo>[];
  
  EntityRootScan(this.refClassName, this._entityCtor);
  
  //---------------------------------
  //
  // Public methods
  //
  //---------------------------------
  
  void detectIfMutable(ClassMirror classMirror) {
    if (
        isMutableEntity &&
        classMirror.metadata.firstWhere(
            (InstanceMirror classMetaData) => (classMetaData.reflectee is Immutable),
            orElse: () => null
        ) != null
    ) isMutableEntity = false;
  }
  
  void registerMetadataUsing(VariableMirror mirror) {
    InstanceMirror instanceMirror;
    _DormPropertyInfo entry;
    Property property;
    int i = mirror.metadata.length, j;
    bool isIdentity;
    dynamic metatag;
    
    _metadataCache = new MetadataCache();
    
    while (i > 0) {
      instanceMirror = mirror.metadata[--i];
      
      if (instanceMirror.reflectee is Property) {
        property = instanceMirror.reflectee as Property;
        
        entry = new _DormPropertyInfo(property.property, property.propertySymbol, property.type, new _PropertyMetadataCache(property.property));
        
        isIdentity = false;
        
        j = mirror.metadata.length;
        
        while (j > 0) {
          metatag = mirror.metadata[--j].reflectee;
          
          _metadataCache.registerTagForProperty(entry, metatag);
          
          if (metatag is Id) isIdentity = true;
        }
        
        _rootProxies.add(entry);
      }
    }
  }
  
  //---------------------------------
  //
  // Protected methods
  //
  //---------------------------------
  
  Entity _unqueueUnusedInstance() => (_unusedInstances.length > 0) ? _unusedInstances.removeLast() : null;
  
  void _queueUnusedInstance(Entity entity) => _unusedInstances.add(entity);
}

class EntityScan {
  
  //---------------------------------
  //
  // Private properties
  //
  //---------------------------------
  
  final EntityRootScan _root;
  EntityKeyChain _keyChain;
  
  List<_DormProxyPropertyInfo> _identityProxies, _proxies;
  Map<String, _DormProxyPropertyInfo> _proxyMap;
  
  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  final Entity entity;
  
  //---------------------------------
  // key
  //---------------------------------
  
  void buildKey() {
    EntityKeyChain nextKey = _root._rootKeyChain;
    
    _identityProxies.forEach(
      (_DormProxyPropertyInfo entry) => nextKey = nextKey._setKeyValue(entry.info.propertySymbol, entry.proxy._value)   
    );
    
    if (_keyChain != nextKey) {
      if (_keyChain != null) _keyChain.entityScans.remove(this);
      
      _keyChain = nextKey;
    }
  }
  
  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------
  
  EntityScan(this._root, this.entity);
  
  factory EntityScan.fromRootScan(EntityRootScan root, Entity forEntity) {
    final EntityScan newScan = new EntityScan(root, forEntity).._initialize();
    
    bool useChangeListener = false;
    
    root._rootProxies.forEach(
       (_DormPropertyInfo entry) {
         final _DormProxyPropertyInfo clonedEntry = new _DormProxyPropertyInfo.from(entry);
         
         newScan._proxies.add(clonedEntry);
         newScan._proxyMap[clonedEntry.info.property] = clonedEntry;
         
         if (clonedEntry.info.metadataCache.isId) newScan._identityProxies.add(clonedEntry);
         
         if (clonedEntry.info.metadataCache.isId && clonedEntry.info.metadataCache.isMutable) useChangeListener = true;
       }
    );
    
    if (useChangeListener) forEntity.changes.listen(
      (List<ChangeRecord> changes) => _entity_changeHandler(forEntity, changes)    
    );
    
    return newScan;
  }
  
  //---------------------------------
  //
  // Private methods
  //
  //---------------------------------
  
  void _initialize() {
    if (_identityProxies == null) {
      _identityProxies = <_DormProxyPropertyInfo>[];
      _proxies = <_DormProxyPropertyInfo>[];
      _proxyMap = <String, _DormProxyPropertyInfo>{};
    }
  }
  
  static void _entity_changeHandler(Entity forEntity, List<ChangeRecord> changes) {
    if (!forEntity.isUnsaved()) {
      final HashSet<Symbol> identitySymbols = forEntity.getIdentityFields();
      
      PropertyChangeRecord matchingChange = changes.firstWhere(
          (ChangeRecord change) => (
              (change is PropertyChangeRecord) && 
              identitySymbols.contains(change.name)
          ),
          orElse: () => null
      );
      
      forEntity._scan.buildKey();
    }
  }
}

//---------------------------------
//
// Private classes
//
//---------------------------------

//---------------------------------
// _DormRootProxyListEntry
//---------------------------------

class _DormPropertyInfo<T extends _DormPropertyInfo> extends Comparable {
  
  final String property;
  final Symbol propertySymbol;
  final Type type;
  final _PropertyMetadataCache metadataCache;
  
  _DormPropertyInfo(this.property, this.propertySymbol, this.type, this.metadataCache);
  
  @override
  int compareTo(T other) => (other == null) ? 1 : property.compareTo(other.property);
}

//---------------------------------
// _DormProxyListEntry
//---------------------------------

class _DormProxyPropertyInfo<T extends _DormProxyPropertyInfo> extends Comparable {
  
  final _DormPropertyInfo info;
  
  DormProxy proxy;
  
  _DormProxyPropertyInfo(this.info);
  
  factory _DormProxyPropertyInfo.from(_DormPropertyInfo value) => new _DormProxyPropertyInfo(value);
  
  @override
  int compareTo(T other) => (other == null) ? 1 : info.property.compareTo(other.info.property);
}