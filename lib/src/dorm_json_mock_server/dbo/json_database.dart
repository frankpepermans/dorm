part of dorm_json_mock_server;

class JsonDatabase {
  
  void resetCache() {
    _cache = new Map<String, Map<String, dynamic>>();
  }
  
  Map<String, Map<String, dynamic>> _cache;
  
  List<Definition> getDefinitions() {
    Directory dir = new Directory('../bin/entities');
    Definition definition;
    
    List<Definition> definitions = <Definition>[];
    
    List<FileSystemEntity> list = getDefinitionFiles(dir);
    
    list.forEach(
        (File file) {
          definition = new Definition();
          
          List<String> tmp = file.path.replaceAll(new RegExp('[^a-zA-Z0-9_]+'), '.').split('.');
          
          tmp.removeLast();
          
          String partA = tmp.removeLast();
          
          definition.type = '${tmp.removeLast()}.$partA';
          definition.definition = parse(
              file.readAsStringSync(encoding: Encoding.UTF_8)  
          );
          
          definitions.add(definition);
        }
    );
    
    return definitions;
  }
  
  List<Map<String, dynamic>> ormEntityLoad(String entityName, {int entityId, Function whereHandler}) {
    List<Definition> definitions = getDefinitions();
    List<Map<String, dynamic>> list = <Map<String, dynamic>>[];
    List<RowEntityMap> rowEntityMapList = <RowEntityMap>[];
    Definition result = definitions.where(
        (Definition definition) => (definition.definition['name'] == entityName)    
    ).first;
    String pk = getPrimaryKeyField(entityName, false);
    RowEntityMap rowEntityMap;
    
    Map<String, dynamic> tmpResult = result.definition;
    
    while (tmpResult.containsKey('extends')) {
      tmpResult = definitions.where(
          (Definition definition) => (definition.definition['name'] == tmpResult['extends'])    
      ).first.definition;
      
      result.definition['properties'].addAll(tmpResult['properties']);
    }
    
    List<Map<String, dynamic>> tableRows = getTableRows(result.definition['table']);
    
    String tableColumnName = result.definition['properties'].where(
        (Map<String, dynamic> property) => (property['identity'] == true)    
    ).first['column'];
    
    tableRows.forEach(
        (Map<String, dynamic> row) {
          if (
            (
              (entityId == null) ||
              (entityId == row[tableColumnName])    
            ) &&
            (
              (whereHandler == null) ||  
              whereHandler(row)
            )
          ) {
            Map<String, dynamic> entityMap = getFromCache(entityName, row[tableColumnName], null);
            
            if (entityMap != null) {
              Map<String, dynamic> duplicateMap = new Map<String, dynamic>();
              
              duplicateMap['?t'] = entityMap['?t'];
              duplicateMap[pk] = entityMap[pk];
              duplicateMap['?p'] = true;
              
              list.add(duplicateMap);
            } else {
              entityMap = new Map<String, dynamic>();
              
              entityMap['?t'] = result.type;
              entityMap[pk] = row[tableColumnName];
              
              rowEntityMap = new RowEntityMap();
              
              rowEntityMap.row = row;
              rowEntityMap.entityMap = entityMap;
              
              rowEntityMapList.add(rowEntityMap);
              
              list.add(entityMap);
              
              insertIntoCache(entityName, row[tableColumnName], entityMap);
            }
          }
        }
    );
    
    rowEntityMapList.forEach(
        (RowEntityMap entry) {
          if (!entry.entityMap.containsKey('?p')) {
            List<Map<String, dynamic>> properties = result.definition['properties'];
            
            properties.forEach(
                (Map<String, dynamic> propery) {
                  String lookupName = propery['name'];
                  
                  if (propery.containsKey('column')) {
                    Iterable<Definition> typeMatches = definitions.where(
                        (Definition def) => (def.definition['name'] == propery['type'])                
                    );
                    
                    String lookupColumn = propery['column'];
                    
                    if (typeMatches.length > 0) {
                      String lookupType = propery['type'];
                      Map<String, dynamic> typeEntityMatch = typeMatches.first.definition;
                      int lookupId = entry.row[lookupColumn];
                      
                      List<Map<String, dynamic>> result = ormEntityLoad(lookupType, entityId:lookupId);
                      
                      if (result.length > 0) {
                        entry.entityMap[lookupName] = result.first;
                      } else {
                        entry.entityMap[lookupName] = null;
                      }
                    } else {
                      entry.entityMap[lookupName] = entry.row[lookupColumn];
                    }
                  } else if (propery.containsKey('fk-column')) {
                    entry.entityMap[lookupName] = ormEntityLoad(
                        propery['singular-type'],
                        whereHandler: (Map<String, dynamic> fkRow) => (fkRow[propery['fk-column']] == entry.row[tableColumnName])
                    );
                  }
                }
            );
          }
        }    
    );
    
    return list;
  }
  
  void insertIntoCache(String entityName, int entityId, Map<String, dynamic> data) {
    final String key = '${entityName}?${entityId}';
    
    if (data != null) {
      _cache[key] = data;
    }
  }
  
  Map<String, dynamic> getFromCache(String entityName, int entityId, Map<String, dynamic> data) {
    final String key = '${entityName}?${entityId}';
    
    if (_cache.containsKey(key)) {
      return _cache[key];
    }
    
    return null;
  }
  
  Map<String, dynamic> getTable(String tableName) {
    Completer completer = new Completer();
    File tableFile = new File('../bin/dbo/dbo_${tableName}.json');
    
    return parse(tableFile.readAsStringSync(encoding: Encoding.UTF_8));
  }
  
  List<Map<String, dynamic>> getTableRows(String tableName) {
    return getTable(tableName)['rows'];
  }
  
  List<File> getDefinitionFiles(Directory dir) {
    List<File> files = dir.listSync(recursive: false);
    
    return files;
  }
  
  bool comparePk(Map<String, dynamic> data, String entityName, int entityId) {
    return (data[getPrimaryKeyField(entityName, false)] == entityId);
  }
  
  String getPrimaryKeyField(String entityName, bool getColumnName) {
    List<Definition> definitions = getDefinitions();
    Definition result = definitions.where(
        (Definition definition) => (definition.definition['name'] == entityName)    
    ).first;
    String identityFieldName;
    
    Map<String, dynamic> tmpResult = result.definition;
    
    while (tmpResult.containsKey('extends')) {
      tmpResult = definitions.where(
          (Definition definition) => (definition.definition['name'] == tmpResult['extends'])    
      ).first.definition;
      
      result.definition['properties'].addAll(tmpResult['properties']);
    }
    
    result.definition['properties'].forEach(
        (Map<String, dynamic> property) {
          if (
              property.containsKey('identity') &&
              (property['identity'] == true)
          ) {
            identityFieldName = getColumnName ? property['column'] : property['name'];
          }
        }
    );
    
    return identityFieldName;
  }
  
  String getTableColumnForProperty(String entityName, String entityProperty) {
    List<Definition> definitions = getDefinitions();
    Definition result = definitions.where(
        (Definition definition) => (definition.definition['name'] == entityName)    
    ).first;
    String identityFieldName;
    
    Map<String, dynamic> tmpResult = result.definition;
    
    while (tmpResult.containsKey('extends')) {
      tmpResult = definitions.where(
          (Definition definition) => (definition.definition['name'] == tmpResult['extends'])    
      ).first.definition;
      
      result.definition['properties'].addAll(tmpResult['properties']);
    }
    
    result.definition['properties'].forEach(
        (Map<String, dynamic> property) {
          if (property['name'] == entityProperty) {
            identityFieldName = property['column'];
          }
        }
    );
    
    return identityFieldName;
  }
  
  String getEntityNameFromDefinitionsByType(String definitionType) {
    List<Definition> definitions = getDefinitions();
    Definition result = definitions.where(
        (Definition definition) => (definition.type == definitionType)    
    ).first;
    
    return result.definition['name'];
  }
  
  String getTableNameFromDefinitionsByType(String definitionType) {
    List<Definition> definitions = getDefinitions();
    Definition result = definitions.where(
        (Definition definition) => (definition.type == definitionType)    
    ).first;
    
    return result.definition['table'];
  }
}

class Definition {
  
  String type;
  Map<String, dynamic> definition;
  
}

class RowEntityMap {
  
  Map<String, dynamic> row;
  Map<String, dynamic> entityMap;
  
}