part of dorm;

class EntityRootScan {
  
  final EntityKeyChain _keyChain = new EntityKeyChain();
  final EntityCtor _entityCtor;
  MetadataCache _metadataCache;
  Entity _unusedInstance;
  
  final String refClassName;
  bool isMutableEntity = true;
  
  final List<_DormProxyListEntry> _identityProxies = <_DormProxyListEntry>[], _proxies = <_DormProxyListEntry>[];
  
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
    _DormProxyListEntry entry;
    Property property;
    int i = mirror.metadata.length, j;
    bool isIdentity;
    dynamic metatag;
    
    _metadataCache = new MetadataCache();
    
    while (i > 0) {
      instanceMirror = mirror.metadata[--i];
      
      if (instanceMirror.reflectee is Property) {
        property = instanceMirror.reflectee as Property;
        
        entry = new _DormProxyListEntry(property.property, property.propertySymbol, property.type, new _PropertyMetadataCache(property.property));
        
        isIdentity = false;
        
        j = mirror.metadata.length;
        
        while (j > 0) {
          metatag = mirror.metadata[--j].reflectee;
          
          _metadataCache.registerTagForProperty(entry, metatag);
          
          if (metatag is Id) isIdentity = true;
        }
        
        _proxies.add(entry);
        
        if (isIdentity) _identityProxies.add(entry);
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
  
  final List<_DormProxyListEntry> _identityProxies = <_DormProxyListEntry>[], _proxies = <_DormProxyListEntry>[];
  
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
    EntityKeyChain nextKey = _root._keyChain;
    
    _identityProxies.forEach(
      (_DormProxyListEntry entry) =>  nextKey = nextKey._setKeyValue(entry.propertySymbol, entry.proxy._value)   
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
    
    root._proxies.forEach(
       (_DormProxyListEntry entry) {
         final _DormProxyListEntry clonedEntry = new _DormProxyListEntry.from(entry);
         
         newScan._proxies.add(clonedEntry);
         
         if (clonedEntry.metadataCache.isId) newScan._identityProxies.add(clonedEntry);
         
         if (clonedEntry.metadataCache.isId && clonedEntry.metadataCache.isMutable) useChangeListener = true;
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
    
    if (
        (matchingChange != null) &&
        !(matchingChange.object as Entity).isUnsaved()
    ) (matchingChange.object as Entity)._scan.buildKey();
  }
}

//---------------------------------
//
// Private classes
//
//---------------------------------

//---------------------------------
// _ProxyEntry
//---------------------------------

class _DormProxyListEntry<T extends _DormProxyListEntry> extends Comparable {
  
  final String property;
  final Symbol propertySymbol;
  final Type type;
  final _PropertyMetadataCache metadataCache;
  
  // TODO:
  DormProxy proxy;
  
  _DormProxyListEntry(this.property, this.propertySymbol, this.type, this.metadataCache);
  
  factory _DormProxyListEntry.from(_DormProxyListEntry value) => new _DormProxyListEntry(value.property, value.propertySymbol, value.type, value.metadataCache);
  
  @override
  int compareTo(T other) {
    if (other == null) return 1;
    
    return property.compareTo(other.property);
  }
}