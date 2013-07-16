part of dorm;

class EntityScan {
  
  //---------------------------------
  //
  // Private properties
  //
  //---------------------------------
  
  EntityScan _original;
  Entity entity;
  
  List<_ProxyEntry> _proxies = new List<_ProxyEntry>();
  List<_ProxyEntry> _identityProxies = new List<_ProxyEntry>();
  
  Function contructorMethod;
  MetadataCache metadataCache;
  String refClassName, _key;
  bool isMutableEntity = true;
  
  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  //---------------------------------
  // key
  //---------------------------------
  
  _ProxyKey _cachedKey;
  
  _ProxyKey get key {
    if (_cachedKey != null) {
      return _cachedKey;
    }
    
    int len = _identityProxies.length;
    _cachedKey = new _ProxyKey(len);
    _ProxyEntry entry;
    int i;
    
    for (i=0; i<len; i++) {
      entry = _identityProxies[i];
      
      _cachedKey.codes[i] = entry.proxy.propertySymbol.hashCode;
      _cachedKey.values[i] = entry.proxy._value;
    }
    
    return _cachedKey;
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
    _ProxyEntry otherEntry;
    _ProxyEntry clonedEntry;
    int i = originalProxies.length;
    
    this._original = original;
    this.entity = entity;
    
    this.contructorMethod = original.contructorMethod;
    this.metadataCache = original.metadataCache;
    this.refClassName = original.refClassName;
    this.isMutableEntity = original.isMutableEntity;
    
    while (i > 0) {
      otherEntry = originalProxies[--i];
      
      clonedEntry = otherEntry.clone();
      
      this._proxies.add(clonedEntry);
      
      if (originalIdentityProxies.contains(otherEntry)) {
        this._identityProxies.add(clonedEntry);
      }
    }
  }
  
  //---------------------------------
  //
  // Public methods
  //
  //---------------------------------
  
  void addProxy(Property property, bool isIdentity) {
    _ProxyEntry entry = new _ProxyEntry(property.property);
    
    _proxies.add(entry);
    
    if (isIdentity) {
      _identityProxies.add(entry);
    }
  }
  
  bool equalsBasedOnRefAndKey(EntityScan otherScan) {
    return(
        (refClassName == otherScan.refClassName) && 
        key.equals(otherScan.key)
    );
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
  
  DormProxy proxy;
  
  _ProxyEntry(this.property);
  
  _ProxyEntry clone() {
    return new _ProxyEntry(property);
  }
  
}

class _ProxyKey {
  
  final int length;
  
  List<int> codes;
  List<dynamic> values;
  
  bool operator == (_ProxyKey otherKey) => equals(otherKey);
  
  _ProxyKey(this.length) {
    codes = new List<int>(length);
    values = new List<dynamic>(length);
  }
  
  bool equals(_ProxyKey otherKey) {
    if (length != otherKey.length) {
      return false;
    }
    
    int i = length;
    
    while (i > 0) {
      if (
          (codes[--i] != otherKey.codes[i]) ||
          (values[i] != otherKey.values[i])
      ) {
        return false;
      }
    }
    
    return true;
  }
  
}