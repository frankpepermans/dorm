part of dorm;

class EntityRootScan {
  
  final String refClassName;
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
    
    final List<dynamic> allMeta = M['metatags'] as List<dynamic>;
    final String N = M['name'] as String;
    final Type T = M['type'] as Type;
    final String typeStr = M['typeStaticStr'] as String;
    final _DormPropertyInfo entry = new _DormPropertyInfo(N, S, T, typeStr, new _PropertyMetadataCache(N));

    entry.metadataCache.expectedType = entry.typeStatic;
    
    _metadataCache = new MetadataCache();
    
    allMeta.forEach(
      (dynamic meta) => _metadataCache.registerTagForProperty(entry, meta)
    );
    
    _rootProxies.add(entry);
  }
}

class EntityScan {
  
  //---------------------------------
  //
  // Private properties
  //
  //---------------------------------
  
  final EntityRootScan _root;
  
  List<_DormProxyPropertyInfo<_DormPropertyInfo>> _identityProxies, _proxies;
  HashMap<String, _DormProxyPropertyInfo<_DormPropertyInfo>> _proxyMap;
  
  //---------------------------------
  //
  // Public properties
  //
  //---------------------------------
  
  final Entity entity;
  
  //---------------------------------
  //
  // Constructor
  //
  //---------------------------------
  
  EntityScan(this._root, this.entity);
  
  factory EntityScan.fromRootScan(EntityRootScan root, Entity forEntity) {
    final EntityScan newScan = new EntityScan(root, forEntity).._initialize();
    final int len = root._rootProxies.length;
    _DormProxyPropertyInfo<_DormPropertyInfo> clonedEntry;
    
    for (int i=0; i<len; i++) {
      clonedEntry = new _DormProxyPropertyInfo<_DormPropertyInfo>.from(root._rootProxies.elementAt(i));
      
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
  
  /*void _entity_identityChangeHandler() {
    if (!entity.isUnsaved()) {
      buildKey();
      
      if (!_keyChain.entityScans.contains(this)) _keyChain.entityScans.add(this);
    }
  }*/
  
  void _initialize() {
    if (_identityProxies == null) {
      _identityProxies = <_DormProxyPropertyInfo<_DormPropertyInfo>>[];
      _proxies = <_DormProxyPropertyInfo<_DormPropertyInfo>>[];
      _proxyMap = new HashMap<String, _DormProxyPropertyInfo<_DormPropertyInfo>>.identity();
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

class _DormPropertyInfo {
  
  final String property, typeStatic;
  final Symbol propertySymbol;
  final Type type;
  final _PropertyMetadataCache metadataCache;
  
  _DormPropertyInfo(this.property, this.propertySymbol, this.type, this.typeStatic, this.metadataCache);
}

//---------------------------------
// _DormProxyListEntry
//---------------------------------

class _DormProxyPropertyInfo<T extends _DormPropertyInfo> {
  
  final T info;
  
  DormProxy<dynamic> _proxy;
  
  DormProxy<dynamic> get proxy => _proxy;
  set proxy(DormProxy<dynamic> value) {
    _proxy = value.._changeHandler = _changeHandler;
  }
  
  Function _changeHandler;
  
  _DormProxyPropertyInfo(this.info);
  
  factory _DormProxyPropertyInfo.from(T value) => new _DormProxyPropertyInfo<T>(value);
}