library dorm.code_transform.meta_transformer;

import 'dart:async';

import 'package:barback/barback.dart';

class MetaTransformer extends Transformer {
    
  MetaTransformer.asPlugin();
    
  String get allowedExtensions => ".dart";
  
  @override
  Future<dynamic> apply(Transform transform) {
    return transform.primaryInput.readAsString().then(
      (String codeBody) {
        final RegExp classNameExp = new RegExp(r"class ([^<]+)[^]* extends ([^ {]+)[^{]+");
        final List<_PropertyDefinition> definitions = _extractAllMetatags(codeBody);
        
        final List<String> refMeta = _scanMeta('Ref', codeBody);
                  
        if (refMeta != null) {
          final List<String> metadef = <String>[];
          final List<String> proxydef = <String>[];
          final Match declMatch = classNameExp.firstMatch(codeBody);
          final String className = declMatch.group(1);
          final String superClassName = declMatch.group(2);
          final String ref = refMeta.first;
          final String header = codeBody.substring(0, codeBody.indexOf('class $className'));
          final bool isImmutable = (_scanMeta('Immutable', header) != null);
          
          if (definitions.isNotEmpty) definitions.forEach(
            (_PropertyDefinition D) {
              metadef.add(D.toCodeBody(className));
              
              proxydef.add('_${D.nameStr.substring(2, D.nameStr.length - 1)}');
              
              final String T = D.typeStr.trim(), N = D.nameStr.replaceAll("'", '').trim(), S = D.symbolStr.trim(), UN = S.substring(0, S.length - 7);
              final String R = '([^\\s]+)[^\\s]*\\s${N};';

              if (D._tags['Lazy'] != null)  
                codeBody = codeBody.replaceFirstMapped(new RegExp(R), (Match M) => 'final DormProxy<${M.group(1)}> _${N} = new DormProxy<${M.group(1)}>(${UN}, ${S}); ${M.group(1)} get $N => _${N}.getLazyValue(this); set ${N}(${M.group(1)} value) => _${N}.value = notifyPropertyChange(${D.symbolStr}, _${N}.value, value);');
              else
                codeBody = codeBody.replaceFirstMapped(new RegExp(R), (Match M) => 'final DormProxy<${M.group(1)}> _${N} = new DormProxy<${M.group(1)}>(${UN}, ${S}); ${M.group(1)} get $N => _${N}.value; set ${N}(${M.group(1)} value) => _${N}.value = notifyPropertyChange(${D.symbolStr}, _${N}.value, value);');
            }
          );
          
          proxydef.sort((String P1, String P2) => P1.compareTo(P2));
          
          final String scanLine = "Entity.ASSEMBLER.scan(R, C, <Map<String, dynamic>>[]${metadef.join('')}, ${isImmutable ? 'false' : 'true'});";
          final String proxyLine = 'Entity.ASSEMBLER.registerProxies(this, <DormProxy>[${proxydef.join(',')}]);';
          final String repl = 'static void DO_SCAN([String R, Function C]) { if (R == null) R = ${ref}; if (C == null) C = () => new ${className}(); ${superClassName}.DO_SCAN(R, C); ${scanLine} } ${className}() : super() { $proxyLine }';
          final String newBody = codeBody.replaceFirst('${className}() : super();', repl);

          transform.addOutput(
            new Asset.fromString(
                transform.primaryInput.id, 
                newBody
            )
          );
        }
      }
    );
  }
  
  List<_PropertyDefinition> _extractAllMetatags(String codeBody) {
    final RegExp exp = new RegExp(r"@[^;]+\)");
    final List<String> tags = const <String>['NotNullable', 'DefaultValue', 'Transient', 'Id', 'Immutable', 'Lazy', 'LabelField', 'Silent', 'Transform', 'Annotation'];
    final List<_PropertyDefinition> definitions = <_PropertyDefinition>[];
    
    exp.allMatches(codeBody).forEach(
      (Match M) {
        final String allMeta = M.group(0);
        
        if (allMeta.isNotEmpty) {
          final _PropertyDefinition D = _scanProperty(allMeta);
          
          if (D != null) {
            tags.forEach(
              (String T) {
                D.addMeta(T, _scanMeta(T, allMeta));
              }
            );
            
            definitions.add(D);
          }
        }
      }    
    );
    
    return definitions;
  }
  
  _PropertyDefinition _scanProperty(String metaBody) {
    final RegExp exp = new RegExp(r"@Property\(([^\)]+)\)");
    final Match M = exp.firstMatch(metaBody);
    
    if (M == null) return null;
    
    final String G = M.group(1);
    final List<String> args = G.split(',');
    
    if (args.length != 4) return null;
    
    return new _PropertyDefinition(args[0], args[1], args[2], args[3]);
  }
  
  List<String> _scanMeta(String metaName, String codeBody) {
    final RegExp exp = new RegExp(r"@" + metaName + r"\(([^\)]*)\)");
    final Match M = exp.firstMatch(codeBody);
    
    if (M == null) return null;
    
    final List<String> values = <String>[];
    final String G = M.group(1);
    
    G.split(',').forEach(
      (String V) => values.add(V.trim())
    );
    
    return values;
  }
}

class _PropertyDefinition {
  
  final String symbolStr, nameStr, typeStr, typeStaticStr;
  final Map<String, List<String>> _tags = <String, List<String>>{};
  
  _PropertyDefinition(this.symbolStr, this.nameStr, this.typeStr, this.typeStaticStr);
  
  void addMeta(String tag, List<String> values) {
    if (values != null) _tags[tag] = values;
  }
  
  String toCodeBody(String className) {
    final List<String> decls = <String>[];
    
    _tags.forEach(
      (String T, List<String> V) => decls.add('const ${T}(${V.join(', ')})')
    );
    
    return "..add(const {'symbol':${className}.${symbolStr},'name':${nameStr},'type':${typeStr},'typeStaticStr':${typeStaticStr},'metatags':const [${decls.join(', ')}]})";
  }
}