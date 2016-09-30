part of dorm;

class EntityCodec<S extends List<Entity>, T extends String> extends Codec<S, T> {
  
  final OnConflictFunction _onConflict;
  final Serializer<T, Map<String, dynamic>> _serializer;
  
  Map<String, Map<String, dynamic>> _convertedEntities;
  
  EntityCodec(this._onConflict, this._serializer);
  
  String get name => "json-cyclic";

  @override Converter<S, T> get encoder => new EntityEncoder<S, T>(_convertedEntities, _serializer);

  @override Converter<T, S> get decoder => new EntityDecoder<S, T>(_convertedEntities, _onConflict, _serializer);

  @override T encode(S input) {
    _convertedEntities = <String, Map<String, dynamic>>{};
    
    return encoder.convert(input);
  }

  @override S decode(T encoded) {
    _convertedEntities = <String, Map<String, dynamic>>{};
    
    return decoder.convert(encoded);
  }
}

class EntityEncoder<S extends List<Entity>, T extends String> extends Converter<S, T> {
  
  final Map<String, Map<String, dynamic>> _convertedEntities;
  final Serializer<T, Map<String, dynamic>> _serializer;
  
  EntityEncoder(this._convertedEntities, this._serializer);

  @override T convert(S entities) {
    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];
    
    entities.forEach(
      (Entity entity) => result.add(entity.toJson(convertedEntities: _convertedEntities))
    );
    
    return _serializer.outgoing(result);
  }
}

class EntityDecoder<S extends List<Entity>, T extends String> extends Converter<T, S> {
  
  final Map<String, Map<String, dynamic>> _convertedEntities;
  final OnConflictFunction _onConflict;
  final Serializer<dynamic, Map<String, dynamic>> _serializer;
  
  EntityDecoder(this._convertedEntities, this._onConflict, this._serializer);

  @override S convert(T rawData) {
    final Iterable<Map<String, dynamic>> result = _serializer.incoming(rawData);
    final EntityFactory<Entity> factory = new EntityFactory<Entity>();
    
    return factory.spawn(result, _serializer, _onConflict) as S;
  }
  
}