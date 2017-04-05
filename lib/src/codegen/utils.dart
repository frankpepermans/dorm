import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

bool isDartCoreReturnType(PropertyAccessorElement property) => property.returnType.element.library.name.compareTo('dart.core') == 0;

bool isDartCollectionReturnType(PropertyAccessorElement property) => property.returnType.element.library.name.compareTo('dart.collection') == 0;

bool isList(PropertyAccessorElement property) => isDartCoreReturnType(property) && property.returnType.name.compareTo('Iterable') == 0;

List<PropertyAccessorElement> getAlphabetizedProperties(ClassElement element) {
  final List<PropertyAccessorElement> properties = element.accessors
      .where((PropertyAccessorElement property) => property.isPublic)
      .toList(growable: false)
    ..sort((PropertyAccessorElement pA, PropertyAccessorElement pB) => pA.displayName.compareTo(pB.displayName));

  return properties;
}

List<PropertyAccessorElement> getRecursiveAlphabetizedProperties(ClassElement element, {List<PropertyAccessorElement> properties}) {
  properties ??= <PropertyAccessorElement>[];

  properties.addAll(element.accessors
      .where((PropertyAccessorElement property) => property.isPublic)
      .toList(growable: false)
    ..sort((PropertyAccessorElement pA, PropertyAccessorElement pB) => pA.displayName.compareTo(pB.displayName)));

  element.allSupertypes
      .where((InterfaceType interfaceType) => interfaceType.displayName.compareTo('Object') != 0 && interfaceType.displayName.compareTo('Entity') != 0 && interfaceType.displayName.compareTo('Externalizable') != 0)
      .forEach((InterfaceType interfaceType) => getRecursiveAlphabetizedProperties(interfaceType.element, properties: properties));

  return properties.toSet().toList();
}

List<Set<String>> getImports(ClassElement element) {
  final List<ClassElement> hierarchy = new List<ClassElement>()
    ..add(element)
    ..addAll(element.allSupertypes.map((InterfaceType type) => type.element));
  final Set<String> hierarchyImports = new Set<String>();
  final Set<String> packageImports = new Set<String>();

  hierarchy.forEach((ClassElement element) {
    new RegExp(r'''import ['"]{1}([^'"]+)['"]{1};''')
        .allMatches(element.enclosingElement.source.contents.data)
        .forEach((Match match) {
      if (!match.group(1).startsWith('package:')) {
        final List<String> parts = match.group(1).split('.')
          ..removeLast()
          ..add('g.dart');
        hierarchyImports.add('''import '${parts.join('.')}';''');
      } else {
        packageImports.add(match.group(0));
      }
    });
  });

  return <Set<String>>[hierarchyImports, packageImports];
}

bool isCustomObject(ClassElement element, String type) {
  return type != 'String' && type != 'num' && type != 'int' && type != 'double' && type != 'DateTime' && type != 'bool' && type != 'Object' && type != 'dynamic';
  /*final RegExp regExp = new RegExp(r'''['"]{1}([\w]+).g.dart['"]{1}''');
  final List<Set<String>> imports = getImports(element);
  final Set<String> allImports = new Set<String>()
    ..addAll(imports.first)
    ..addAll(imports.last);

  return allImports.firstWhere((String importLine) => regExp.firstMatch(importLine)?.group(1)?.toLowerCase() == type.toLowerCase(), orElse: () => null) != null;*/
}