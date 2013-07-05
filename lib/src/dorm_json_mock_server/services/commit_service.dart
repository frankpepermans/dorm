part of dorm_json_mock_server;

class CommitService extends BaseService {
  
  final JsonDatabase dbo = new JsonDatabase();
  
  CommitService() : super();
  
  String flush(List<String> dataToCommit, List<String> dataToDelete) {
    dbo.resetCache();
    
    dataToCommit.forEach(
        (String commitEntry) {
          Map<String, dynamic> commitEntryMap = parse(commitEntry);
          String type = commitEntryMap['?t'];
          String entityName = dbo.getEntityNameFromDefinitionsByType(type);
          String pkField = dbo.getPrimaryKeyField(entityName, false);
          String pkColumnName = dbo.getPrimaryKeyField(entityName, true);
          String tableName = dbo.getTableNameFromDefinitionsByType(type);
          int pkValue = commitEntryMap[pkField];
          
          Map<String, dynamic> table = dbo.getTable(tableName);
          List<Map<String, dynamic>> tableRows = table['rows'];
          
          if (pkValue == 0) {
            
          } else {
            tableRows.forEach(
                (Map<String, dynamic> tableRow) {
                  if (tableRow[pkColumnName] == pkValue) {
                    commitEntryMap.forEach(
                        (String property, dynamic value) {
                          String tableColumn = dbo.getTableColumnForProperty(entityName, property);

                          if (tableColumn != null) {
                            if (value is Map) {
                              tableRow[tableColumn] = value[property];
                            } else {
                              tableRow[tableColumn] = value;
                            }
                          }
                        }
                    );
                  }
                }
            );
          }
          
          File tableFile = new File('../bin/dbo/dbo_${tableName}.json');
          
          tableFile.writeAsStringSync(stringify(table), mode:FileMode.WRITE, encoding:Encoding.UTF_8);
        }
    );
    
    return stringify([]);
  }
  
}