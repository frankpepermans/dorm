part of dorm;

class SerializerAmf<T extends Entity, U extends ByteData> extends SerializerBase {
  
  //-----------------------------------
  //
  // Public properties
  //
  //-----------------------------------
  
  final ReadExternalHandler _parseHandler;
  final EntitySpawnMethod _spawnHandler;
  final Transformer _transformer;
  
  //-----------------------------------
  //
  // Constructor
  //
  //-----------------------------------
  
  SerializerAmf._contruct(this._spawnHandler, this._parseHandler, this._transformer);
  
  //-----------------------------------
  //
  // Factories
  //
  //-----------------------------------
  
  factory SerializerAmf(EntitySpawnMethod spawnHandler, ReadExternalHandler parseHandler, Transformer transformer) => 
      new SerializerAmf._contruct(spawnHandler, parseHandler, transformer);
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  Iterable<T> incoming(U data) => new AMF3Input(data, _spawnHandler, _parseHandler, _transformer).readObject().first['body']['viewItems'].values;
  
  U outgoing(dynamic data) {
    return null;
  }
  
  dynamic convertIn(Type forType, dynamic inValue) {
    final _InternalConvertor convertor = _convertors[forType];
    
    return (convertor == null) ? inValue : convertor.incoming(inValue);
  }
  
  dynamic convertOut(Type forType, dynamic outValue) {
    final _InternalConvertor convertor = _convertors[forType];
    
    return (convertor == null) ? outValue : convertor.outgoing(outValue);
  }
}