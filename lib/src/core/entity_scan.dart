part of dorm;

class EntityRootScan {
  
  final EntityKeyChain _rootKeyChain = new EntityKeyChain();
  final EntityCtor _entityCtor;
  MetadataCache _metadataCache;
  Entity _unusedInstance;
  
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
}

class EntityScan {
  
  //---------------------------------
  //
  // Private properties
  //
  //---------------------------------
  
  EntityRootScan _root;
  EntityKeyChain _keyChain;
  
  final List<_DormProxyPropertyInfo> _identityProxies = <_DormProxyPropertyInfo>[];
  final Map<String, _DormProxyPropertyInfo> _proxies = <String, _DormProxyPropertyInfo>{};
  
  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  Entity entity;
  
  //---------------------------------
  // key
  //---------------------------------
  
  void buildKey() {
    EntityKeyChain nextKey = _root._rootKeyChain;
    
    _identityProxies.forEach(
      (_DormProxyPropertyInfo entry) =>  nextKey = nextKey._setKeyValue(entry.info.propertySymbol, entry.proxy._value)   
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
  
  EntityScan();
  
  factory EntityScan.fromRootScan(EntityRootScan root, Entity forEntity) {
    final EntityScan newScan = new EntityScan()
    .._root = root
    ..entity = forEntity;
    
    bool useChangeListener = false;
    
    root._rootProxies.forEach(
       (_DormPropertyInfo entry) {
         final _DormProxyPropertyInfo clonedEntry = new _DormProxyPropertyInfo.from(entry);
         
         newScan._proxies[entry.property] = clonedEntry;
         
         if (clonedEntry.info.metadataCache.isId) newScan._identityProxies.add(clonedEntry);
         
         if (clonedEntry.info.metadataCache.isId && clonedEntry.info.metadataCache.isMutable) useChangeListener = true;
       }
    );
    
    if (useChangeListener) forEntity.changes.listen(_entity_changeHandler);
    
    return newScan;
  }
  
  //---------------------------------
  //
  // Private methods
  //
  //---------------------------------
  
  static void _entity_changeHandler(List<ChangeRecord> changes) {
    PropertyChangeRecord matchingChange = changes.firstWhere(
        (ChangeRecord change) => (
            (change is PropertyChangeRecord) && 
            (change.object as Entity).getIdentityFields().contains(change.name)
        ),
        orElse: () => null
    );
    
    final Entity targetEntity = (matchingChange != null) ? (matchingChange.object as Entity) : null;
    
    if (
        (targetEntity != null) &&
        !targetEntity.isUnsaved()
    ) targetEntity._scan.buildKey();
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