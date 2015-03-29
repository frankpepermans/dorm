library dorm_js;

import 'dart:async';
import 'dart:js';

import 'dorm.dart';

export 'dorm.dart';

final SerializerJson<EntityJs, Map<String, dynamic>> serializerJson = new SerializerJson<EntityJs, Map<String, dynamic>>();
final SerializerJs<EntityJs, JsObject> serializerJs = new SerializerJs<EntityJs, JsObject>();
final DormManager manager = new DormManager();
final Map<Entity, StreamSubscription> listeners = <Entity, StreamSubscription>{};

final OnConflictFunction onConflictAcceptClient = (EntityJs serverEntity, Entity clientEntity) => ConflictManager.AcceptClient;
final OnConflictFunction onConflictAcceptServer = (EntityJs serverEntity, Entity clientEntity) => ConflictManager.AcceptServer;

void delegate(String jsContext, String jsMethod, String dartMethod) {
  switch (dartMethod) {
    case 'deserialize':       context[jsContext][jsMethod] = deserialize;       break;
    case 'inspect':           context[jsContext][jsMethod] = inspect;           break;
    case 'commit':            context[jsContext][jsMethod] = commit;            break;
    case 'validate':          context[jsContext][jsMethod] = validate;          break;
    case 'flush':             context[jsContext][jsMethod] = flush;             break;
    case 'createNewEntity':   context[jsContext][jsMethod] = createNewEntity;   break;
    case 'setLazyHandler':    context[jsContext][jsMethod] = setLazyHandler;    break;
    case 'fetchLazyProperty': context[jsContext][jsMethod] = fetchLazyProperty; break;
    case 'revert':            context[jsContext][jsMethod] = revert;            break;
  }
  
  print('[Info] Dart "$dartMethod" => JavaScript "$jsContext.$jsMethod"');
}

/**
 * Deserializes an incoming String in JSON format and immediately creates object instances in the Javascript VM.
 *
 * The incoming JavaScript object [pTag] must be an object with a 'serializedData' property.
 * 
 *     var jsObject = { 'serializedData': jsonAsString };
 *
 * As a second argument, pass the JavaScript method that will act as a [callback] when the data is deserialized.
 * 
 *     function jsCallback(jsEntities) {...
 * 
 * Also set the [favourClient] flag,
 * 
 * if set to [true], recurring objects will NOT update from the server, the client state is kept as is.
 * if set to [false], client data is overwritten to match the incoming server data.
 * 
 * The invoke from JavaScript would become:
 * 
 *     dart.deserialize( { 'serializedData': jsonAsString }, jsCallback, true );
 */
void deserialize(JsObject pTag, JsFunction callback, bool favourClient) {
  final String serializedData = pTag['serializedData'];
  final String collectionRefClassName = pTag['collectionType'];
  final Iterable<Map<String, dynamic>> dataIn = serializerJson.incoming(serializedData);
  final OnConflictFunction conflictHandler = favourClient ? onConflictAcceptClient : onConflictAcceptServer;
  
  Stopwatch s1 = new Stopwatch()..start();
  
  final List<EntityJs> dataLocal = Entity.FACTORY.spawn(dataIn, serializerJson, conflictHandler, forType: collectionRefClassName);
  
  s1.stop();
  
  print('dart objectify ${s1.elapsedMilliseconds}ms');
  
  s1 = new Stopwatch()..start();
  
  final JsObject dataOut = serializerJs.outgoing(dataLocal);
  
  print('js objectify ${s1.elapsedMilliseconds}ms');
  
  callback.apply(<JsObject>[dataOut]);
}

JsObject revert(JsObject pTag) {
  final EntityJs entity = serializerJs.fetchEntity(pTag);
  
  entity.revertChanges();
  
  return serializerJs.outgoing(<EntityJs>[entity]);
}

String inspect(JsObject pTag) {
  final EntityJs entity = serializerJs.fetchEntity(pTag);
  final Map<String, Map<String, dynamic>> result = <String, Map<String, dynamic>>{};
  
  result['info'] = {'type': entity.refClassName};
  
  entity.getPropertyList().forEach(
    (Symbol S) {
      final String property = S.toString().split('"')[1];
      final Map<String, dynamic> map = result[property] = <String, dynamic>{};
    
      MetadataExternalized M = entity.getMetadata(S);
      
      map['expected_type'] =          M.expectedType;
      map['is_id'] =                  M.isId;
      map['is_label_field'] =         M.isLabelField;
      map['is_lazy_loaded'] =         M.isLazy;
      map['is_mutable'] =             M.isMutable;
      map['is_nullable'] =            M.isNullable;
      map['is_silent'] =              M.isSilent;
      map['is_transient'] =           M.isTransient;
      
      map['generic_annotations'] =    <String, dynamic>{};
      
      if (M.transformFrom != null) map['transformation'] = '${M.transformFrom} => ${M.transformTo}';
      
      if (M.genericAnnotations != null) M.genericAnnotations.forEach(
        (String K, dynamic V) => map['generic_annotations'][K] = V
      );
    }
  );
  
  return serializerJson.outgoing(result);
}

String flush() {
  final DormManagerCommitStructure DC = manager.drain();
  final List<Map<String, dynamic>> L = <Map<String, dynamic>>[];
  Map<String, dynamic> DS, wrapper, idents;
  
  DC.dataToCommit.forEach(
    (EntityJs E) {
      DS = E.getDirtyStates(ignoresUnsavedStatus: true);
      
      if (DS.isNotEmpty) {
        wrapper = <String, dynamic>{};
        idents = <String, dynamic>{};
        
        E.getIdentityFields().forEach(
          (Symbol S) => idents[E.getPropertyByField(S)] = E[S]
        );
        
        wrapper['refClassName'] = E.refClassName;
        wrapper['identities'] = idents;
        wrapper['properties'] = DS;
        
        L.add(wrapper);
        
        manager.queue(E);
      }
    }
  );
  
  return serializerJson.outgoing(L);
}

void setLazyHandler(String symbolDefinition, JsFunction handler) {
  final Symbol sym = new Symbol(symbolDefinition);
  final EntityLazyHandler ELH = new EntityLazyHandler(
      sym,
      (EntityJs E, Symbol S) {
        try {
          final Completer C = new Completer();
          final JsObject promise = handler.apply([E.toJsObject()]);
          final JsFunction jsResponse = new JsFunction.withThis((_, dynamic response) { C.complete(response); });
          final JsFunction jsError = new JsFunction.withThis((_, dynamic error) { print(error); C.complete(null); });
          
          promise.callMethod('then', [jsResponse, jsError]);
          
          return C.future; 
        } catch (error) {
          print(error);
        }
      }
  );
  
  Entity.FACTORY.addLazyHandler(ELH);
}

String fetchLazyProperty(JsObject pTag, String symbolDefinition, JsFunction callback) {
  final Symbol sym = new Symbol(symbolDefinition);
  Iterable<EntityJs> incoming;
  
  try {
    incoming = serializerJs.incoming(pTag);
    
    final dynamic lazyCallee = incoming.first[sym];
    
    if (lazyCallee is Future) {
      lazyCallee.whenComplete(
        () => callback.apply(<dynamic>[serializerJs.outgoing(<EntityJs>[incoming.first])]) 
      );
    }
  } catch(error) {
    return error.toString();
  }
  
  return null;
}

String validate(JsObject pTag) {
  final String property = pTag['property'];
  Iterable<EntityJs> incoming;
  
  try {
    incoming = serializerJs.incoming(pTag);
    
    incoming.forEach(
      (EntityJs E) {
        final StreamSubscription SS = listeners[E];
        
        if (SS != null) SS.cancel();
        
        listeners[E] = E.changes.listen(
          (_) {
            if (E.isDirty()) manager.queue(E);
            else manager.unqueue(E);
          }
        );
        
        if (E.isDirty() || E.isUnsaved()) manager.queue(E);
        else manager.unqueue(E);
        
        List<MetadataValidationResult> list = E.validate();
        
        Iterable<MetadataValidationResult> R = (property != null) ? list.where(
          (MetadataValidationResult MVR) => MVR.property == property   
        ) : list;
        
        if (R.isNotEmpty) throw new ArgumentError(R.toString());
      }
    );
  } catch(error) {
    return error.toString();
  }
  
  return '';
}

JsObject createNewEntity(String refClassName) {
  final EntityJs entity = serializerJs.newEntity(refClassName);
  
  manager.queue(entity);
  
  return serializerJs.outgoing(<EntityJs>[entity]);
}

String commit(JsObject pTag) {
  final String validationResult = validate(pTag);
  
  if (validationResult.isNotEmpty) return validationResult;
  
  final Iterable<EntityJs> incoming = serializerJs.incoming(pTag);
  final String response = serializerJson.outgoing(incoming);
  
  return response.substring(2, response.length - 2).replaceAll('\\', '');
}