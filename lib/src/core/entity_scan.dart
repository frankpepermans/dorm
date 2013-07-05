part of dorm;

class EntityScan {
  
  EntityScan();
  
  EntityScan _original;
  
  EntityScan.fromScan(EntityScan original) {
    this._original = original;
    
    this.entityType = original.entityType;
    this.qualifiedName = original.qualifiedName;
    this.qualifiedLocalName = original.qualifiedLocalName;
    this.classMirror = original.classMirror;
    this.key = original.key;
    this.isMutableEntity = original.isMutableEntity;
    
    original._proxies.forEach(
      (_ProxyEntry otherEntry) =>  this._proxies.add(otherEntry.clone(otherEntry))
    );
  }
  
  List<_ProxyEntry> _proxies = new List<_ProxyEntry>();
  
  Type entityType;
  Symbol qualifiedName;
  String qualifiedLocalName;
  ClassMirror classMirror;
  String key;
  bool isMutableEntity = true;
  
  void addProxy(String property, Symbol symbol, Symbol propertySymbol, VariableMirror mirror) {
    _ProxyEntry entry = new _ProxyEntry(property, symbol, propertySymbol, mirror);
    
    _proxies.add(entry);
  }
}

class _ProxyEntry {
  
  final String property;
  final Symbol symbol;
  final Symbol propertySymbol;
  final VariableMirror mirror;
  
  Proxy proxy;
  
  _ProxyEntry(this.property, this.symbol, this.propertySymbol, this.mirror);
  
  _ProxyEntry clone(_ProxyEntry value) {
    return new _ProxyEntry(value.property, value.symbol, value.propertySymbol, value.mirror);
  }
  
}