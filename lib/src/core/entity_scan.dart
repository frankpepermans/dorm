part of dorm;

class EntityScan {
  
  //---------------------------------
  //
  // Private properties
  //
  //---------------------------------
  
  EntityKeyChain _rootKeyChain;
  EntityScan _original;
  EntityCtor _entityCtor;
  Entity _unusedInstance;
  EntityKeyChain _keyChain;
  MetadataCache _metadataCache;
  
  final List<_DormProxyListEntry> _identityProxies = <_DormProxyListEntry>[], _proxies = <_DormProxyListEntry>[];
  
  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  Entity entity;
  String refClassName;
  bool isMutableEntity = true;
  
  //---------------------------------
  // key
  //---------------------------------
  
  void buildKey() {
    EntityKeyChain nextKey = _rootKeyChain;
    
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
  
  EntityScan(this.refClassName, this._entityCtor);
  
  EntityScan.withKeyChain(this.refClassName, this._entityCtor) {
    _rootKeyChain = new EntityKeyChain();
  }
  
  factory EntityScan.fromScan(EntityScan originalScan, Entity forEntity) {
    final EntityScan newScan = new EntityScan(originalScan.refClassName, originalScan._entityCtor)
    .._rootKeyChain = originalScan._rootKeyChain
    .._original = originalScan
    .._metadataCache = originalScan._metadataCache
    ..entity = forEntity
    ..isMutableEntity = originalScan.isMutableEntity;
    
    bool useChangeListener = false;
    
    originalScan._proxies.forEach(
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
  
  DormProxy proxy;
  
  _DormProxyListEntry(this.property, this.propertySymbol, this.type, this.metadataCache);
  
  factory _DormProxyListEntry.from(_DormProxyListEntry value) => new _DormProxyListEntry(value.property, value.propertySymbol, value.type, value.metadataCache);
  
  @override
  int compareTo(T other) {
    if (other == null) return 1;
    
    return property.compareTo(other.property);
  }
}