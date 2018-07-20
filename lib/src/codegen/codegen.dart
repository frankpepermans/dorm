import 'dart:async';

import 'package:build/build.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import 'utils.dart' as utils;

class CodeGenerator extends Generator {
  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final ClassElement element = library.allElements.firstWhere(
        (Element element) =>
            element.location.components.first.contains(buildStep.inputId.path),
        orElse: () => null) as ClassElement;

    if (element == null) return null;

    final ElementAnnotation opticsAnnotation = element.metadata.firstWhere(
        (ElementAnnotation annotation) =>
            annotation.element.name.compareTo('dorm') == 0,
        orElse: () => null);

    if (opticsAnnotation != null) {
      if (!element.isAbstract)
        throw new ArgumentError(
            'The optics annotation can only be used on abstract classes');

      final StringBuffer buffer = new StringBuffer();

      final List<Set<String>> imports = utils.getImports(element);

      buffer.writeln();

      List<String> packagesAsList = imports.last.toList(growable: true)..sort();

      if (element.supertype.element.librarySource.shortName
              .compareTo('dorm.dart') !=
          0)
        packagesAsList.removeWhere((String entry) =>
            entry.contains(element.supertype.element.librarySource.shortName));

      packagesAsList = packagesAsList.map((String entry) {
        if (entry.compareTo('''import 'package:dorm/dorm.dart';''') != 0 &&
            entry.compareTo(
                    '''import 'package:taurus_shared/src/domain/modules/building_block.dart';''') !=
                0 &&
            entry.compareTo(
                    '''import 'package:taurus_shared/taurus_shared.dart';''') !=
                0 &&
            entry.compareTo(
                    '''import 'package:taurus_search/taurus_search.dart';''') !=
                0 &&
            entry.compareTo('''import 'package:ng2_state/ng2_state.dart';''') !=
                0 &&
            entry.compareTo(
                    '''import 'package:ng2_form_components/ng2_form_components.dart';''') !=
                0) return entry.replaceFirst('.dart', '.g.dart');

        return entry;
      }).toList(growable: false);

      buffer.writeln(packagesAsList.join(''));
      buffer.writeln();
      buffer.writeln(
          '''import '${element.enclosingElement.displayName}' as sup;''');

      final List<String> lA = new RegExp(r'abstract class ([^{]+)')
          .firstMatch(element.source.contents.data)
          .group(1)
          .split('implements');
      String superType = lA.last.split(',').first;

      /*if (superType.compareTo('Entity') != 0)
          buffer.writeln('''import '${element.supertype.element.librarySource.shortName.split('.dart').first}.g.dart';''');*/

      final List<String> hierarchyAsList = imports.first.toList(growable: false)
        ..sort();

      buffer.writeln(hierarchyAsList.join(''));

      ///
      final String className = element.displayName;
      final String ident = 'i' +
          element.library.identifier
              .split('.dart')
              .first
              .replaceAll(new RegExp(r'[^a-zA-Z\d]+'), '_');
      final Iterable<String> genericClassTypes = utils
          .getAlphabetizedProperties(element)
          .where((PropertyAccessorElement property) =>
              property.returnType.element?.kind?.displayName
                  ?.compareTo('type parameter') ==
              0)
          .map((PropertyAccessorElement property) =>
              property.returnType.displayName);

      final String dA = lA.first;
      final List<String> gA =
          dA.split('abstract class $className').last.split('>')
            ..removeLast()
            ..add('');
      final String genericTypesDecl =
          (gA.length > 1 ? gA.join('>') : '').split(className).last;

      String genericTypes = '';
      String exendsPart = '';

      if (genericClassTypes.isNotEmpty)
        genericTypes = '<${genericClassTypes.join(', ')}>';

      exendsPart = 'extends $superType with sup.$className$genericTypes';

      String impl = (lA.length > 1)
          ? lA.last
              .replaceAll(className, 'sup.$className')
              .replaceAll('$superType, ', '')
              .replaceAll(', $superType', '')
              .replaceAll('$superType', '')
          : '';

      if (impl.trim().isNotEmpty)
        buffer.writeln(
            'class $className$genericTypesDecl $exendsPart implements $impl{');
      else
        buffer.writeln('class $className$genericTypesDecl $exendsPart {');

      ///
      buffer.writeln('/// refClassName');
      buffer.writeln('''@override String get refClassName => '$ident';''');
      buffer.writeln('/// Public properties');

      utils
          .getAlphabetizedProperties(element)
          .forEach((PropertyAccessorElement property) {
        buffer.writeln('/// ${property.displayName}');
        //buffer.writeln('''@Property(${property.displayName.toUpperCase()}_SYMBOL, '${property.displayName}', ${property.returnType.name}, '${property.displayName}')''');
        buffer.writeln(
            '''static const String ${property.displayName.toUpperCase()} = '${property.displayName}';''');
        buffer.writeln(
            '''static const Symbol ${property.displayName.toUpperCase()}_SYMBOL = #${ident}_${property.displayName};''');
        buffer.writeln();
        buffer.writeln(
            'final DormProxy<${property.returnType.displayName}> _${property.displayName} = new DormProxy<${property.returnType.displayName}>(${property.displayName.toUpperCase()}, ${property.displayName.toUpperCase()}_SYMBOL);');
        buffer.writeln(
            '@override ${property.returnType.displayName} get ${property.displayName} => _${property.displayName}.value;');
        buffer.writeln(
            'set ${property.displayName}(${property.returnType.displayName} value) { _${property.displayName}.value = value; }');
      });

      ///

      ///
      buffer.writeln('/// DO_SCAN');
      buffer.writeln(
          'static void DO_SCAN$genericTypesDecl([String _R, Entity _C()]) {');
      buffer.writeln('''_R ??= '$ident';''');
      buffer.writeln('''_C ??= () => new $className$genericTypes();''');
      if (superType.compareTo('Entity') != 0)
        buffer.writeln('''$superType.DO_SCAN(_R, _C);''');
      buffer.writeln('''Entity.ASSEMBLER.scan(_R, _C, const <PropertyData>[''');

      utils
          .getAlphabetizedProperties(element)
          .forEach((PropertyAccessorElement property) {
        buffer.writeln('''const PropertyData(''');
        buffer.writeln(
            '''symbol: $className.${property.displayName.toUpperCase()}_SYMBOL,''');
        buffer.writeln('''name: '${property.displayName}',''');

        if (genericClassTypes.contains(property.returnType.name))
          buffer.writeln('''type: dynamic,''');
        else
          buffer.writeln('''type: ${property.returnType.name},''');

        buffer.writeln('''metatags: const <dynamic>[''');

        property.metadata.forEach((ElementAnnotation annotation) {
          final String metaName =
              annotation.element.enclosingElement.displayName;

          if (metaName.compareTo('Id') == 0)
            buffer.writeln(
                '''const $metaName(${annotation.constantValue.getField('insertValue').toString().split('(').last.split(')').first}),''');
          else if (metaName.compareTo('DefaultValue') == 0)
            buffer.writeln(
                '''const $metaName(${annotation.constantValue.getField('value').toString().split('(').last.split(')').first}),''');
          else
            buffer.writeln('''const $metaName(),''');
        });

        buffer.writeln(''']),''');
      });

      buffer.writeln(''']);}''');

      buffer.writeln('/// Constructor');

      final String allProxies = utils
          .getAlphabetizedProperties(element)
          .map((PropertyAccessorElement property) => '_${property.displayName}')
          .join(', ');
      final String listCtrs = utils
          .getRecursiveAlphabetizedProperties(element)
          .map((PropertyAccessorElement accessor) {
        if (accessor.returnType.element is ClassElement) {
          ClassElement elmCast = accessor.returnType.element;

          /// _finish(_combine(_combine(0, a.hashCode), b.hashCode));
          final InterfaceType iterableType = elmCast.allSupertypes.firstWhere(
              (InterfaceType type) =>
                  type.element.library.isDartCore && type.name == 'Iterable',
              orElse: () => null);

          if (iterableType != null) {
            return 'this.${accessor.displayName} = new ${accessor.returnType.displayName}();';
          }
        }

        return '';
      }).join('');

      buffer.writeln(
          '$className() {Entity.ASSEMBLER.registerProxies(this, <DormProxy<dynamic>>[$allProxies]);$listCtrs}');

      buffer.writeln('/// Internal constructor');
      buffer.writeln(
          'static $className$genericTypes construct$genericTypesDecl() => new $className$genericTypes();');

      utils
          .getAlphabetizedProperties(element)
          .forEach((PropertyAccessorElement property) {
        String uCased =
            '${property.displayName.substring(0, 1).toUpperCase()}${property.displayName.substring(1)}';
        buffer.writeln('/// with$uCased');
        buffer.writeln(
            '$className$genericTypes with$uCased(${property.returnType.displayName} value) => duplicate(ignoredSymbols: const <Symbol>[$className.${property.displayName.toUpperCase()}_SYMBOL])..${property.displayName}=value;');
      });

      buffer.writeln(
          '/// Duplicates the [$className] and any recursive entities to a new [$className]');
      buffer.writeln(
          '@override $className$genericTypes duplicate({List<Symbol> ignoredSymbols}) => super.duplicate(ignoredSymbols: ignoredSymbols) as $className$genericTypes;');

      buffer.writeln('@override bool operator ==(Object other) => ');

      buffer.writeln(
          'other is $className$genericTypes && other.hashCode == this.hashCode;');

      buffer.writeln('@override int get hashCode => ');

      String stepper = '0';

      utils
          .getRecursiveAlphabetizedProperties(element)
          .forEach((PropertyAccessorElement accessor) {
        if (accessor.returnType.element is ClassElement) {
          ClassElement elmCast = accessor.returnType.element;
          String current;

          /// _finish(_combine(_combine(0, a.hashCode), b.hashCode));
          final InterfaceType iterableType = elmCast.allSupertypes.firstWhere(
              (InterfaceType type) =>
                  type.element.library.isDartCore && type.name == 'Iterable',
              orElse: () => null);

          if (iterableType != null) {
            current = 'hash_combineAll(this.${accessor.displayName})';
          } else {
            current = 'this.${accessor.displayName}.hashCode';
          }

          stepper = 'hash_combine($stepper, $current)';
        }
      });

      buffer.writeln('hash_finish($stepper);');

      buffer.writeln('/// toString implementation for debugging purposes');
      buffer.writeln('@override String toString() =>');

      List<PropertyAccessorElement> allIds = <PropertyAccessorElement>[];
      List<PropertyAccessorElement> allLabels = <PropertyAccessorElement>[];

      utils
          .getRecursiveAlphabetizedProperties(element)
          .forEach((PropertyAccessorElement property) {
        property.metadata.forEach((ElementAnnotation annotation) {
          final String metaName =
              annotation.element.enclosingElement.displayName;

          if (metaName.compareTo('Id') == 0)
            allIds.add(property);
          else if (metaName.compareTo('Label') == 0) allLabels.add(property);
        });
      });

      if (allLabels.isNotEmpty) {
        buffer.writeln(
            ''''${allLabels.map((PropertyAccessorElement P) => '\$${P.displayName}').join(', ')}';''');
      } else if (allIds.isNotEmpty) {
        buffer.writeln(
            ''''$className: {${allIds.map((PropertyAccessorElement P) => '${P.displayName}: \$${P.displayName}').join(', ')}}';''');
      } else {
        buffer.writeln(''''$ident';''');
      }

      buffer.write('}');

      return buffer.toString();
    }
  }

  const CodeGenerator();
}
