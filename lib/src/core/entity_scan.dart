part of dorm;

class EntityScan {
  
  //---------------------------------
  //
  // Private properties
  //
  //---------------------------------
  
  EntityScan _original;
  Function _contructorMethod;
  Entity _unusedInstance;
  List<EntityScan> _keyCollection;
  MetadataCache _metadataCache = new MetadataCache();
  List<int> _proxyIndices;
  
  final List<_ProxyEntry> _proxies = <_ProxyEntry>[];
  final Map<String, _ProxyEntry> _proxyMap = new Map<String, _ProxyEntry>();
  final List<_ProxyEntry> _identityProxies = <_ProxyEntry>[];
  
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
      (_ProxyEntry entry) =>  nextKey = nextKey._setKeyValue(entry.propertySymbol, entry.proxy._value)   
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
  
  EntityScan(this.refClassName, this._contructorMethod);
  
  EntityScan.fromScan(this._original, this.entity) {
    this._contructorMethod = _original._contructorMethod;
    this._metadataCache = _original._metadataCache;
    this.refClassName = _original.refClassName;
    this.isMutableEntity = _original.isMutableEntity;
    
    _original._proxies.forEach(
       (_ProxyEntry entry) {
         _ProxyEntry clonedEntry = entry.clone();
         
         this._proxies.add(clonedEntry);
         this._proxyMap[entry.property] = clonedEntry;
         
         if (clonedEntry.isIdentity) this._identityProxies.add(clonedEntry);
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
    ) {
      isMutableEntity = false;
    }
  }
  
  void registerMetadataUsing(VariableMirror mirror) {
    InstanceMirror instanceMirror;
    _ProxyEntry entry;
    Property property;
    int i = mirror.metadata.length, j;
    bool isIdentity;
    dynamic metatag;
    
    while (i > 0) {
      instanceMirror = mirror.metadata[--i];
      
      if (instanceMirror.reflectee is Property) {
        property = instanceMirror.reflectee as Property;
        
        entry = new _ProxyEntry(property.property, property.propertySymbol, property.type);
        
        isIdentity = false;
        
        j = mirror.metadata.length;
        
        while (j > 0) {
          metatag = mirror.metadata[--j].reflectee;
          
          _metadataCache.registerTagForProperty(entry, metatag);
          
          if (metatag is Id) isIdentity = true;
        }
        
        entry.isIdentity = isIdentity;
        
        _proxies.add(entry);
        
        _proxyMap[property.property] = entry;
        
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

class _ProxyEntry {
  
  final String property;
  final Symbol propertySymbol;
  final Type type;
  
  bool isIdentity;
  DormProxy proxy;
  _PropertyMetadataCache metadataCache;
  
  _ProxyEntry(this.property, this.propertySymbol, this.type);
  
  _ProxyEntry clone() => new _ProxyEntry(property, propertySymbol, type)..metadataCache = metadataCache..isIdentity = isIdentity;
  
}