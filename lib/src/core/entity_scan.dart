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
  
  Type entityType;
  String ref;
  Function contructorMethod;
  Symbol qualifiedName;
  String qualifiedLocalName, _key;
  ClassMirror classMirror;
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
  
  String get key {
    StringBuffer buffer = new StringBuffer();
    _ProxyEntry entry;
    int i = _identityProxies.length;
    
    while (i > 0) {
      entry = _identityProxies[--i];
      
      buffer.writeAll(<String>[_keyEntryStart, entry.property, _keyEntryEnd, _keyEntryStart, entry.proxy.value.toString(), _keyEntryEnd]);
    }
    
    return buffer.toString();
  }
  
  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------
  
  EntityScan();
  
  EntityScan.fromScan(EntityScan original) {
    List<_ProxyEntry> originalProxies = original._proxies;
    List<_ProxyEntry> originalIdentityProxies = original._identityProxies;
    _ProxyEntry otherEntry;
    _ProxyEntry clonedEntry;
    int i = originalProxies.length;
    
    this._original = original;
    
    this.entityType = original.entityType;
    this.ref = original.ref;
    this.contructorMethod = original.contructorMethod;
    this.qualifiedName = original.qualifiedName;
    this.qualifiedLocalName = original.qualifiedLocalName;
    this.classMirror = original.classMirror;
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
  
  void addProxy(String property, Symbol symbol, bool isIdentity, Symbol propertySymbol, VariableMirror mirror) {
    _ProxyEntry entry = new _ProxyEntry(property, symbol, propertySymbol, mirror);
    
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
  final Symbol symbol;
  final Symbol propertySymbol;
  final VariableMirror mirror;
  
  DormProxy proxy;
  
  _ProxyEntry(this.property, this.symbol, this.propertySymbol, this.mirror);
  
  _ProxyEntry clone() {
    return new _ProxyEntry(property, symbol, propertySymbol, mirror);
  }
  
}