part of dorm;

abstract class Entity implements Externalizable {
  static final EntityAssembler ASSEMBLER = new EntityAssembler();
  static final EntityFactory<Entity> FACTORY = new EntityFactory<Entity>();
  static Serializer<dynamic, Map<String, dynamic>> _serializerWorkaround;
  static int _nextUid = 1;

  //-----------------------------------
  //
  // Private properties
  //
  //-----------------------------------

  EntityScan _scan;
  int _uid = _nextUid++;

  static void DO_SCAN([String R, Function C]) {}

  //-----------------------------------
  //
  // Public properties
  //
  //-----------------------------------

  //-----------------------------------
  // refClassName
  //-----------------------------------

  String get refClassName;

  //-----------------------------------
  //
  // Operator overloads
  //
  //-----------------------------------

  dynamic operator [](Symbol propertyField) {
    if (propertyField == #hashCodeInternal) return _uid;

    final _DormProxyPropertyInfo<dynamic> result = _scan._proxies.firstWhere(
        (_DormProxyPropertyInfo<dynamic> entry) =>
            (entry.info.propertySymbol == propertyField),
        orElse: () => null);

    return (result != null) ? result.proxy.value : null;
  }

  void operator []=(Symbol propertyField, dynamic propertyValue) {
    final _DormProxyPropertyInfo<dynamic> result = _scan._proxies.firstWhere(
        (_DormProxyPropertyInfo<dynamic> entry) =>
            (entry.info.propertySymbol == propertyField),
        orElse: () => null);

    if (result != null) result.proxy.value = propertyValue;
  }

  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------

  static final Map<String, HashSet<Symbol>> _identityFieldsMap =
      <String, HashSet<Symbol>>{};

  ///
  /// Unrolls all [Entity] identity fields to a one-dimensional [List]
  ///
  HashSet<Symbol> getIdentityFields() {
    HashSet<Symbol> fields = _identityFieldsMap[refClassName];

    if (fields != null) return fields;

    fields = new HashSet<Symbol>.identity();

    _scan._identityProxies.forEach((_DormProxyPropertyInfo<dynamic> entry) =>
        fields.add(entry.info.propertySymbol));

    _identityFieldsMap[refClassName] = fields;

    return fields;
  }

  ///
  /// Returns the String representation of a property using the property symbol
  ///
  String getPropertyByField(Symbol propertyField) =>
      _scan._root._symbolToProperty[propertyField];

  ///
  /// Returns the Symbol representation of a property using the property name as String
  ///
  Symbol getFieldByProperty(String property) =>
      _scan._root._propertyToSymbol[property];

  static final Map<String, HashSet<Symbol>> _propertyList =
      <String, HashSet<Symbol>>{};

  ///
  /// Returns a [List] containing [Symbol]s of all properties belonging to this [Entity].
  ///
  HashSet<Symbol> getPropertyList() {
    HashSet<Symbol> properties = _propertyList[refClassName];

    if (properties != null) return properties;

    properties = new HashSet<Symbol>.identity();

    _scan._proxies.forEach((_DormProxyPropertyInfo<dynamic> entry) =>
        properties.add(entry.info.propertySymbol));

    _propertyList[refClassName] = properties;

    return properties;
  }

  ///
  /// Duplicates the [Entity] and any recursive entities to a new [Entity].
  ///
  dynamic duplicate({List<Symbol> ignoredSymbols}) =>
      _duplicateImpl(<_ClonedEntityEntry>[], ignoredSymbols);

  ///
  /// Duplicates the [Entity] and any recusrive entities to a new [Entity].
  ///
  void duplicateFrom(Entity otherEntity, {List<Symbol> ignoredSymbols}) {
    Entity clone = otherEntity.duplicate(ignoredSymbols: ignoredSymbols);

    _scan._proxies.forEach((_DormProxyPropertyInfo<dynamic> proxyInfo) {
      if ((ignoredSymbols == null) ||
          !ignoredSymbols.contains(proxyInfo.info.propertySymbol))
        this[proxyInfo.info.propertySymbol] =
            clone[proxyInfo.info.propertySymbol];
    });
  }

  ///
  /// Converts raw [Map] data into an [Entity], including the full cyclic chain.
  ///
  /// The [Serializer] is used to perform special conversions if needed, i.e. to create a [DateTime] from an [int]
  /// value which contains the millisecondsSinceEpoch value.
  ///
  @override
  void readExternal(Map<String, dynamic> data,
      Serializer<dynamic, Map<String, dynamic>> serializer) {
    for (int i = 0, len = _scan._proxies.length; i < len; i++) {
      _DormProxyPropertyInfo<dynamic> E = _scan._proxies.elementAt(i);

      final DormProxy<dynamic> proxy = E.proxy..hasDelta = true;
      final dynamic entryValue = data[E.info.property];

      if (entryValue is Map<String, dynamic>)
        proxy.setInitialValue(serializer.convertIn(
            Entity, FACTORY.spawnSingle(entryValue, serializer, proxy: proxy)));
      else if (entryValue is Iterable<Map<String, dynamic>>)
        proxy.setInitialValue(serializer.convertIn(
            E.info.type, FACTORY.spawn(entryValue, serializer, proxy: proxy)));
      else
        proxy.setInitialValue(serializer.convertIn(E.info.type, entryValue));
    }
  }

  ///
  /// Converts the [Entity] into raw [Map] data, including the full cyclic chain.
  ///
  /// The [Serializer] is used to perform special conversions if needed, i.e. to create an [int] value from a [DateTime] value
  /// value which contains the millisecondsSinceEpoch value.
  ///
  @override
  void writeExternal(Map<String, dynamic> data,
          Serializer<dynamic, Map<String, dynamic>> serializer) =>
      _writeExternalImpl(data, serializer);

  ///
  /// Converts the [Entity] into a JSON representation.
  ///
  Map<String, dynamic> toJson(
      {Map<String, Map<String, dynamic>> convertedEntities}) {
    final Map<String, dynamic> jsonMap = <String, dynamic>{};

    try {
      writeExternal(jsonMap, _serializerWorkaround);
    } catch (e, s) {
      print('$e: $s');
    }

    return jsonMap;
  }

  //---------------------------------
  //
  // Private methods
  //
  //---------------------------------

  int hash_combineAll<T>(Iterable<T> objects) => objects == null
      ? objects.hashCode
      : objects.fold(0, (int h, T i) => hash_combine(h, i.hashCode));

  int hash_combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));

    return hash ^ (hash >> 6);
  }

  int hash_finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);

    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  Entity _duplicateImpl(
      List<_ClonedEntityEntry> clonedEntities, List<Symbol> ignoredSymbols) {
    final _ClonedEntityEntry clonedEntity = clonedEntities.firstWhere(
        (_ClonedEntityEntry cloneEntry) => (cloneEntry.original == this),
        orElse: () => null);

    if (clonedEntity != null) return clonedEntity.clone;

    final Entity clone = _scan._root._entityCtor();

    clonedEntities.add(new _ClonedEntityEntry(this, clone));

    clone._scan._proxies.forEach((_DormProxyPropertyInfo<dynamic> entry) {
      if ((ignoredSymbols == null) ||
          !ignoredSymbols.contains(entry.info.propertySymbol)) {
        if (entry.info.metadataCache.isId)
          entry.proxy.setInitialValue(this[entry.proxy._propertySymbol]);
        else {
          dynamic value = this[entry.proxy._propertySymbol];

          if (value is List) {
            final listClone = value.toList();

            for (int i = 0, len = value.length; i < len; i++) {
              final listEntry = value[i];

              if (listEntry is Entity) {
                final Entity listEntryCast = listEntry;

                listClone[i] = listEntryCast._duplicateImpl(
                    clonedEntities, ignoredSymbols);
              }
            }

            entry.proxy.setInitialValue(
                _serializerWorkaround.convertIn(entry.info.type, listClone));
          } else if (value is Entity) {
            final Entity entryCast = value;

            entry.proxy.setInitialValue(
                entryCast._duplicateImpl(clonedEntities, ignoredSymbols));
          } else
            entry.proxy.setInitialValue(value);
        }
      }
    });

    return clone;
  }

  void _writeExternalImpl(Map<String, dynamic> data,
      Serializer<dynamic, Map<String, dynamic>> serializer) {
    data[SerializationType.ENTITY_TYPE] = _scan._root.refClassName;
    data[SerializationType.UID] = _uid;
    if (serializer.asDetached) data[SerializationType.DETACHED] = true;

    if (ASSEMBLER.usePointers) serializer.convertedEntities[this] = data;

    final int len = _scan._proxies.length;

    for (int i = 0; i < len; i++)
      _writeExternalProxy(_scan._proxies[i], data, serializer);
  }

  void _writeExternalProxy(
      _DormProxyPropertyInfo<dynamic> entry,
      Map<String, dynamic> data,
      Serializer<dynamic, Map<String, dynamic>> serializer) {
    List<dynamic> subList, dataList;
    Entity S;

    if (entry.proxy.value is Entity) {
      if (!entry.info.metadataCache.isTransient) {
        S = entry.proxy.value;

        data[entry.info.property] = <String, dynamic>{};

        S._writeExternalImpl(
            data[entry.info.property] as Map<String, dynamic>, serializer);
      }
    } else if (entry.proxy.value is List) {
      if (!entry.info.metadataCache.isTransient) {
        subList = serializer.convertOut(entry.info.type, entry.proxy.value);
        dataList = <dynamic>[];

        subList.forEach((dynamic listEntry) {
          if (listEntry is Entity) {
            Map<String, dynamic> data = <String, dynamic>{};

            listEntry._writeExternalImpl(data, serializer);

            dataList.add(data);
          } else
            dataList
                .add(serializer.convertOut(entry.info.type, entry.proxy.value));
        });

        data[entry.info.property] = dataList;
      }
    } else if (!entry.info.metadataCache.isTransient)
      data[entry.info.property] =
          serializer.convertOut(entry.info.type, entry.proxy.value);
  }
}

class _ClonedEntityEntry {
  final Entity original;
  final Entity clone;

  _ClonedEntityEntry(this.original, this.clone);
}
