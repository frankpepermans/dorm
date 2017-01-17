part of dorm;

class EntityRootScan {
  
  final String refClassName;
  final EntityCtor _entityCtor;
  final Map<String, Symbol> _propertyToSymbol = <String, Symbol>{};
  final Map<Symbol, String> _symbolToProperty = <Symbol, String>{};
  final List<_DormPropertyInfo> _rootProxies = <_DormPropertyInfo>[];
  MetadataCache _metadataCache;
  bool _hasMapping = false;
  
  EntityRootScan(this.refClassName, this._entityCtor);
  
  //---------------------------------
  //
  // Public methods
  //
  //---------------------------------
  
  void registerMetadataUsing(PropertyData propertyData) {
    if (_rootProxies.firstWhere((_DormPropertyInfo I) => (I.propertySymbol == propertyData.symbol), orElse: () => null) != null) return;

    final _DormPropertyInfo entry = new _DormPropertyInfo(propertyData.name, propertyData.symbol, propertyData.type, new _PropertyMetadataCache(propertyData.name));
    
    _metadataCache = new MetadataCache();

    propertyData.metatags.forEach(
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
  
  List<_DormProxyPropertyInfo<dynamic>> _identityProxies, _proxies;
  HashMap<String, _DormProxyPropertyInfo<dynamic>> _proxyMap;
  
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
    
    for (int i=0, len = root._rootProxies.length; i<len; i++) {
      _DormProxyPropertyInfo<dynamic> clonedEntry = new _DormProxyPropertyInfo<dynamic>.from(root._rootProxies.elementAt(i));
      
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
      _identityProxies = <_DormProxyPropertyInfo<dynamic>>[];
      _proxies = <_DormProxyPropertyInfo<dynamic>>[];
      _proxyMap = new HashMap<String, _DormProxyPropertyInfo<dynamic>>.identity();
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
  
  final String property;
  final Symbol propertySymbol;
  final Type type;
  final _PropertyMetadataCache metadataCache;
  
  _DormPropertyInfo(this.property, this.propertySymbol, this.type, this.metadataCache);
}

//---------------------------------
// _DormProxyListEntry
//---------------------------------

class _DormProxyPropertyInfo<T> {
  
  final _DormPropertyInfo info;
  
  DormProxy<T> proxy;
  
  _DormProxyPropertyInfo(this.info);
  
  factory _DormProxyPropertyInfo.from(_DormPropertyInfo value) => new _DormProxyPropertyInfo<T>(value);
}