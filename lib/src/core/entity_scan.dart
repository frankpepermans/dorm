part of dorm;

class EntityScan {
  
  //---------------------------------
  //
  // Private properties
  //
  //---------------------------------
  
  EntityScan _original;
  
  List<_ProxyEntry> _proxies = new List<_ProxyEntry>();
  List<_ProxyEntry> _identityProxies = new List<_ProxyEntry>();
  List<EntityScan> _keyCollection;
  
  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  Entity entity;
  Function contructorMethod;
  MetadataCache metadataCache;
  String refClassName;
  bool isMutableEntity = true;
  
  //---------------------------------
  // key
  //---------------------------------
  
  void buildKey() {
    EntityKey nextKey = EntityAssembler._instance._keyChain;
    _ProxyEntry entry;
    int code;
    int i = _identityProxies.length;
    dynamic value;
    
    while (i > 0) {
      entry = _identityProxies[--i];
      
      code = entry.proxy.propertySymbol.hashCode;
      value = entry.proxy._value;
      
      nextKey[code] = value;
      
      nextKey = nextKey[[code, value]];
    }
    
    if (_keyCollection != nextKey.entityScans) {
      if (_keyCollection != null) _keyCollection.remove(this);
      
      _keyCollection = nextKey.entityScans..add(this);
    }
  }
  
  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------
  
  EntityScan() {
    metadataCache = new MetadataCache();
  }
  
  EntityScan.fromScan(EntityScan original, Entity entity) {
    List<_ProxyEntry> originalProxies = original._proxies;
    List<_ProxyEntry> originalIdentityProxies = original._identityProxies;
    _ProxyEntry clonedEntry;
    int i = originalProxies.length;
    
    this._original = original;
    this.entity = entity;
    
    this.contructorMethod = original.contructorMethod;
    this.metadataCache = original.metadataCache;
    this.refClassName = original.refClassName;
    this.isMutableEntity = original.isMutableEntity;
    
    while (i > 0) {
      clonedEntry = originalProxies[--i].clone();
      
      this._proxies.add(clonedEntry);
      
      if (clonedEntry.isIdentity) this._identityProxies.add(clonedEntry);
    }
  }
  
  //---------------------------------
  //
  // Public methods
  //
  //---------------------------------
  
  void addProxy(Property property, bool isIdentity) {
    _ProxyEntry entry = new _ProxyEntry(property.property, isIdentity);
    
    _proxies.add(entry);
    
    if (isIdentity) {
      _identityProxies.add(entry);
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
  final bool isIdentity;
  
  DormProxy proxy;
  
  _ProxyEntry(this.property, this.isIdentity);
  
  _ProxyEntry clone() {
    return new _ProxyEntry(property, isIdentity);
  }
  
}