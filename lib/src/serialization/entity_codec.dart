part of dorm;

class EntityCodec<S extends List<Entity>, T extends String> extends Codec {
  
  final OnConflictFunction _onConflict;
  final Serializer _serializer;
  
  Map<String, Map<String, dynamic>> _convertedEntities;
  
  EntityCodec(this._onConflict, this._serializer);
  
  String get name => "json-cyclic";
  
  Converter<List<Entity>, String> get encoder => new EntityEncoder(_convertedEntities, _serializer);
  
  Converter<String, List<Entity>> get decoder => new EntityDecoder(_convertedEntities, _onConflict, _serializer);
  
  T encode(S input) {
    _convertedEntities = <String, Map<String, dynamic>>{};
    
    return encoder.convert(input) as T;
  }
  
  S decode(T encoded) {
    _convertedEntities = <String, Map<String, dynamic>>{};
    
    return decoder.convert(encoded);
  }
}

class EntityEncoder extends Converter<List<Entity>, String> {
  
  final Map<String, Map<String, dynamic>> _convertedEntities;
  final Serializer _serializer;
  
  EntityEncoder(this._convertedEntities, this._serializer);
  
  String convert(List<Entity> entities) {
    final List<String> result = new List<String>();
    
    entities.forEach(
      (Entity entity) => result.add(entity.toJson(convertedEntities: _convertedEntities))
    );
    
    return _serializer.outgoing(result);
  }
}

class EntityDecoder extends Converter<String, List<Entity>> {
  
  final Map<String, Map<String, dynamic>> _convertedEntities;
  final OnConflictFunction _onConflict;
  final Serializer _serializer;
  
  EntityDecoder(this._convertedEntities, this._onConflict, this._serializer);
  
  List<Entity> convert(String rawData) {
    final Iterable<Map<String, dynamic>> result = _serializer.incoming(rawData);
    final EntityFactory factory = new EntityFactory();
    
    return factory.spawn(result, _serializer, _onConflict) as List<Entity>;
  }
  
}