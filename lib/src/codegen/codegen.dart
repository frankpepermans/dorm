import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import 'utils.dart' as  utils;

class CodeGenerator extends Generator {

  @override
  Future<String> generate(Element element, _) async {
    if (element is ClassElement) {
      final ElementAnnotation opticsAnnotation = element.metadata
          .firstWhere((ElementAnnotation annotation) => annotation.element.name.compareTo('dorm') == 0, orElse: () => null);

      if (opticsAnnotation != null) {
        if (!element.isAbstract) throw new ArgumentError('The optics annotation can only be used on abstract classes');

        final StringBuffer buffer = new StringBuffer();

        final List<Set<String>> imports = utils.getImports(element);

        buffer.writeln();

        List<String> packagesAsList = imports.last.toList(growable: true)..sort();

        if (element.supertype.element.librarySource.shortName.compareTo('dorm.dart') != 0) packagesAsList.removeWhere((String entry) => entry.contains(element.supertype.element.librarySource.shortName));

        packagesAsList = packagesAsList.map((String entry) {
          if (
              entry.compareTo('''import 'package:dorm/dorm.dart';''') != 0 &&
              entry.compareTo('''import 'package:taurus_shared/src/domain/modules/building_block.dart';''') != 0 &&
              entry.compareTo('''import 'package:taurus_shared/taurus_shared.dart';''') != 0 &&
              entry.compareTo('''import 'package:taurus_search/taurus_search.dart';''') != 0 &&
              entry.compareTo('''import 'package:ng2_state/ng2_state.dart';''') != 0 &&
              entry.compareTo('''import 'package:ng2_form_components/ng2_form_components.dart';''') != 0)
            return entry.replaceFirst('.dart', '.g.dart');

          return entry;
        }).toList(growable: false);

        buffer.writeln(packagesAsList.join(''));
        buffer.writeln();
        buffer.writeln('''import '${element.enclosingElement.displayName}' as sup;''');

        final List<String> lA = new RegExp(r'abstract class ([^{]+)').firstMatch(element.source.contents.data).group(1).split('implements');
        String superType = lA.last.split(',').first;

        /*if (superType.compareTo('Entity') != 0)
          buffer.writeln('''import '${element.supertype.element.librarySource.shortName.split('.dart').first}.g.dart';''');*/


        final List<String> hierarchyAsList = imports.first.toList(growable: false)..sort();

        buffer.writeln(hierarchyAsList.join(''));

        ///
        final String className = element.displayName;
        final String ident = 'i' + element.library.identifier.split('.dart').first.replaceAll(new RegExp(r'[^a-zA-Z\d]+'), '_');
        final Iterable<String> genericClassTypes = utils.getAlphabetizedProperties(element)
            .where((PropertyAccessorElement property) => property.returnType.element?.kind?.displayName?.compareTo('type parameter') == 0)
            .map((PropertyAccessorElement property) => property.returnType.displayName);

        final String dA = lA.first;
        final List<String> gA = dA.split('abstract class $className').last.split('>')..removeLast()..add('');
        final String genericTypesDecl = (gA.length > 1 ? gA.join('>') : '').split(className).last;


        String genericTypes = '';
        String exendsPart = '';

        if (genericClassTypes.isNotEmpty) genericTypes = '<${genericClassTypes.join(', ')}>';

        exendsPart = 'extends $superType with sup.$className$genericTypes';

        String impl = (lA.length > 1) ? lA.last.replaceAll(className, 'sup.$className').replaceAll('$superType, ', '').replaceAll(', $superType', '').replaceAll('$superType', '') : '';

        if (impl.trim().isNotEmpty) buffer.writeln('class $className$genericTypesDecl $exendsPart implements $impl{');
        else buffer.writeln('class $className$genericTypesDecl $exendsPart {');

        ///
        buffer.writeln('/// refClassName');
        buffer.writeln('''@override String get refClassName => '$ident';''');
        buffer.writeln('/// Public properties');

        utils.getAlphabetizedProperties(element)
          .forEach((PropertyAccessorElement property) {
            buffer.writeln('/// ${property.displayName}');
            //buffer.writeln('''@Property(${property.displayName.toUpperCase()}_SYMBOL, '${property.displayName}', ${property.returnType.name}, '${property.displayName}')''');
            buffer.writeln('''static const String ${property.displayName.toUpperCase()} = '${property.displayName}';''');
            buffer.writeln('''static const Symbol ${property.displayName.toUpperCase()}_SYMBOL = #${ident}_${property.displayName};''');
            buffer.writeln();
            buffer.writeln('final DormProxy<${property.returnType.displayName}> _${property.displayName} = new DormProxy<${property.returnType.displayName}>(${property.displayName.toUpperCase()}, ${property.displayName.toUpperCase()}_SYMBOL);');
            buffer.writeln('@override ${property.returnType.displayName} get ${property.displayName} => _${property.displayName}.value;');
            buffer.writeln('set ${property.displayName}(${property.returnType.displayName} value) { _${property.displayName}.value = value; }');
          });

        ///

        ///
        buffer.writeln('/// DO_SCAN');
        buffer.writeln('static void DO_SCAN/*$genericTypesDecl*/([String _R, Entity _C()]) {');
        buffer.writeln('''_R ??= '$ident';''');
        buffer.writeln('''_C ??= () => new $className$genericTypes();''');
        if (superType.compareTo('Entity') != 0) buffer.writeln('''$superType.DO_SCAN(_R, _C);''');
        buffer.writeln('''Entity.ASSEMBLER.scan(_R, _C, const <PropertyData>[''');


        utils.getAlphabetizedProperties(element)
            .forEach((PropertyAccessorElement property) {
              buffer.writeln('''const PropertyData(''');
              buffer.writeln('''symbol: $className.${property.displayName.toUpperCase()}_SYMBOL,''');
              buffer.writeln('''name: '${property.displayName}',''');

              if (genericClassTypes.contains(property.returnType.name)) buffer.writeln('''type: dynamic,''');
              else buffer.writeln('''type: ${property.returnType.name},''');

              buffer.writeln('''metatags: const <dynamic>[''');

              property.metadata.forEach((ElementAnnotation annotation) {
                final String metaName = annotation.element.enclosingElement.displayName;

                if (metaName.compareTo('Id') == 0) buffer.writeln('''const $metaName(${annotation.constantValue.getField('insertValue').toString().split('(').last.split(')').first}),''');
                else if (metaName.compareTo('DefaultValue') == 0) buffer.writeln('''const $metaName(${annotation.constantValue.getField('value').toString().split('(').last.split(')').first}),''');
                else buffer.writeln('''const $metaName(),''');
              });

              buffer.writeln(''']),''');
            });

        buffer.writeln(''']);}''');

        buffer.writeln('/// Ctr');

        final String allProxies = utils.getAlphabetizedProperties(element)
            .map((PropertyAccessorElement property) => '_${property.displayName}')
            .join(', ');

        buffer.writeln('$className() : super() {Entity.ASSEMBLER.registerProxies(this, <DormProxy<dynamic>>[$allProxies]);}');
        buffer.writeln('static $className/*$genericTypes*/ construct/*$genericTypesDecl*/() => new $className$genericTypes();');

        buffer.write('}');

        return buffer.toString();
      }
    }

    return null;
  }

  const CodeGenerator();

}