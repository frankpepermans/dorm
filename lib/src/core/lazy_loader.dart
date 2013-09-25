part of dorm;

class LazyLoader {
  
  //-----------------------------------
  //
  // Private properties
  //
  //-----------------------------------
  
  List<_InternalLazyLoaderHandler> _handlers = <_InternalLazyLoaderHandler>[];
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  void addHandler(Symbol symbol, LazyLoaderMethod method) =>
      _handlers.add(new _InternalLazyLoaderHandler(symbol, method));
  
  void removeHandler(Symbol forSymbol) => _handlers.removeWhere(
      (_InternalLazyLoaderHandler handler) => (handler.forSymbol == forSymbol)
  );
  
  Future<dynamic> load(Entity entity, Symbol forSymbol) {
    _InternalLazyLoaderHandler handler = _handlers.firstWhere(
      (_InternalLazyLoaderHandler tmpHandler) => (tmpHandler.forSymbol == forSymbol),
      orElse: () => null
    );
    
    return (handler == null) ? null : handler.method(entity, forSymbol);
  }
}

class _InternalLazyLoaderHandler {
  
  final Symbol forSymbol;
  final LazyLoaderMethod method;
  
  const _InternalLazyLoaderHandler(this.forSymbol, this.method);
  
}