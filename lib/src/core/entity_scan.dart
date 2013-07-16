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
  
  static String _keyEntryStart = new String.fromCharCode(2);
  static String _keyEntryEnd = new String.fromCharCode(2);
  
  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  //---------------------------------
  // key
  //---------------------------------
  
  String _cachedKey;
  
  String get key {
    if (_cachedKey != null) {
      return _cachedKey;
    }
    
    StringBuffer buffer = new StringBuffer();
    _ProxyEntry entry;
    int i = _identityProxies.length;
    
    while (i > 0) {
      entry = _identityProxies[--i];
      
      buffer.writeAll(<String>[_keyEntryStart, entry.property, _keyEntryEnd, _keyEntryStart, entry.proxy._value.toString(), _keyEntryEnd]);
    }
    
    _cachedKey = buffer.toString();
    
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
  
  bool equalsBasedOnRefAndKey(EntityScan otherScan, {String compareKey}) {
    return(
        (refClassName == otherScan.refClassName) && 
        (key == ((compareKey == null) ? otherScan.key : compareKey))
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