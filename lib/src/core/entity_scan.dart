part of dorm;

class EntityScan {
  
  //---------------------------------
  //
  // Private properties
  //
  //---------------------------------
  
  EntityScan _original;
  EntityCtor _entityCtor;
  Entity _unusedInstance;
  List<EntityScan> _keyCollection;
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
    EntityKey nextKey = EntityAssembler._instance._keyChain;
    
    _identityProxies.forEach(
      (_DormProxyListEntry entry) =>  nextKey = nextKey._setKeyValue(entry.propertySymbol, entry.proxy._value)   
    );
    
    if (_keyCollection != nextKey.entityScans) {
      if (_keyCollection != null) _keyCollection.remove(this);
      
      _keyCollection = nextKey.entityScans;
    }
  }
  
  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------
  
  EntityScan(this.refClassName, this._entityCtor);
  
  EntityScan.fromScan(this._original, this.entity) {
    this._entityCtor = _original._entityCtor;
    this._metadataCache = _original._metadataCache;
    this.refClassName = _original.refClassName;
    this.isMutableEntity = _original.isMutableEntity;
    
    _original._proxies.forEach(
       (_DormProxyListEntry entry) {
         final _DormProxyListEntry clonedEntry = entry.clone();
         
         this._proxies.add(clonedEntry);
         
         if (entry.metadataCache.isId) {
           this._identityProxies.add(clonedEntry);
           
           entity.changes.listen(
            (List<ChangeRecord> changes)  {
              PropertyChangeRecord matchingChange = changes.firstWhere(
                    (ChangeRecord change) => (
                        (change is PropertyChangeRecord) && 
                        (change.name == clonedEntry.propertySymbol)
                    ),
                    orElse: () => null
              );
              
              if (
                  (matchingChange != null) &&
                  !entity.isUnsaved()
              ) buildKey();
            }
           );
         }
       }
    );
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
        
        entry = new _DormProxyListEntry(property.property, property.propertySymbol, property.type);
        
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
  _PropertyMetadataCache metadataCache;
  
  DormProxy proxy;
  
  _DormProxyListEntry(this.property, this.propertySymbol, this.type);
  
  _DormProxyListEntry clone() => new _DormProxyListEntry(property, propertySymbol, type)
  ..metadataCache = metadataCache;
  
  @override
  int compareTo(T other) {
    if (other == null) return 1;
    
    return property.compareTo(other.property);
  }
}