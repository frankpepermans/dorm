part of dorm;

class EntityRootScan {
  
  final String refClassName;
  final EntityKeyChain _rootKeyChain = new EntityKeyChain();
  final EntityCtor _entityCtor;
  final Map<String, Symbol> _propertyToSymbol = <String, Symbol>{};
  final Map<Symbol, String> _symbolToProperty = <Symbol, String>{};
  final List<_DormPropertyInfo> _rootProxies = <_DormPropertyInfo>[];
  MetadataCache _metadataCache;
  Entity _unusedInstance;
  bool isMutableEntity = true;
  bool _hasMapping = false;
  
  EntityRootScan(this.refClassName, this._entityCtor);
  
  //---------------------------------
  //
  // Public methods
  //
  //---------------------------------
  
  void registerMetadataUsing(Map<String, dynamic> M) {
    final Symbol S = M['symbol'] as Symbol;
        
    if (_rootProxies.firstWhere((_DormPropertyInfo I) => (I.propertySymbol == S), orElse: () => null) != null) return;
    
    final List allMeta = M['metatags'] as List;
    final String N = M['name'] as String;
    final Type T = M['type'] as Type;
    final String typeStr = M['typeStaticStr'] as String;
    final _DormPropertyInfo entry = new _DormPropertyInfo(N, S, T, typeStr, new _PropertyMetadataCache(N));
    bool isIdentity = false;
    
    entry.metadataCache.expectedType = entry.typeStatic;
    
    _metadataCache = new MetadataCache();
    
    allMeta.forEach(
      (Object meta) {
        _metadataCache.registerTagForProperty(entry, meta);
        
        if (meta is Id) isIdentity = true;
      }
    );
    
    _rootProxies.add(entry);
  }
  
  void clearKey() => _rootKeyChain.entityScans.clear();
}

class EntityScan {
  
  //---------------------------------
  //
  // Private properties
  //
  //---------------------------------
  
  final EntityRootScan _root;
  EntityKeyChain _keyChain;
  
  List<_DormProxyPropertyInfo> _identityProxies, _proxies;
  HashMap<String, _DormProxyPropertyInfo> _proxyMap;
  
  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  final Entity entity;
  
  //---------------------------------
  // key
  //---------------------------------
  
  void buildKey() {
    final int len = _identityProxies.length;
    EntityKeyChain nextKey = _root._rootKeyChain;
    _DormProxyPropertyInfo entry;
    
    for (int i=0; i<len; 
        entry = _identityProxies[i++], 
        nextKey = nextKey._setKeyValue(entry.info.propertySymbol, entry.proxy._value)
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
  
  EntityScan(this._root, this.entity);
  
  factory EntityScan.fromRootScan(EntityRootScan root, Entity forEntity) {
    final EntityScan newScan = new EntityScan(root, forEntity).._initialize();
    final int len = root._rootProxies.length;
    _DormProxyPropertyInfo clonedEntry;
    
    for (int i=0; i<len; i++) {
      clonedEntry = new _DormProxyPropertyInfo.from(root._rootProxies.elementAt(i));
      
      newScan._proxies.add(clonedEntry);
      newScan._proxyMap[clonedEntry.info.property] = clonedEntry;
      
      if (clonedEntry.info.metadataCache.isId) {
        newScan._identityProxies.add(clonedEntry);
        
        //if (clonedEntry.info.metadataCache.isMutable) clonedEntry._changeHandler = newScan._entity_identityChangeHandler;
      }
    }
    
    return newScan;
  }
  
  //---------------------------------
  //
  // Private methods
  //
  //---------------------------------
  
  bool _evictEntity(Entity entity) {
    if (_keyChain != null) return _keyChain.evictEntity(entity);
    
    return false;
  }
  
  /*void _entity_identityChangeHandler() {
    if (!entity.isUnsaved()) {
      buildKey();
      
      if (!_keyChain.entityScans.contains(this)) _keyChain.entityScans.add(this);
    }
  }*/
  
  void _initialize() {
    if (_identityProxies == null) {
      _identityProxies = <_DormProxyPropertyInfo>[];
      _proxies = <_DormProxyPropertyInfo>[];
      _proxyMap = new HashMap<String, _DormProxyPropertyInfo>.identity();
    }
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
  
  final String property, typeStatic;
  final Symbol propertySymbol;
  final Type type;
  final _PropertyMetadataCache metadataCache;
  
  _DormPropertyInfo(this.property, this.propertySymbol, this.type, this.typeStatic, this.metadataCache);
  
  @override
  int compareTo(T other) => (other == null) ? 1 : property.compareTo(other.property);
}

//---------------------------------
// _DormProxyListEntry
//---------------------------------

class _DormProxyPropertyInfo<T extends _DormProxyPropertyInfo> extends Comparable {
  
  final _DormPropertyInfo info;
  
  DormProxy _proxy;
  
  DormProxy get proxy => _proxy;
  void set proxy(DormProxy value) {
    _proxy = value.._changeHandler = _changeHandler;
  }
  
  Function _changeHandler;
  
  _DormProxyPropertyInfo(this.info);
  
  factory _DormProxyPropertyInfo.from(_DormPropertyInfo value) => new _DormProxyPropertyInfo(value);
  
  @override
  int compareTo(T other) => (other == null) ? 1 : info.property.compareTo(other.info.property);
}