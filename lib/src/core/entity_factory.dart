part of dorm;

class EntityFactory<T> {
  
  EntityManager manager;
  final OnConflictFunction onConflict;
  
  EntityFactory(this.onConflict) {
    manager = new EntityManager();
  }
  
  List<T> spawn(List<Map<String, dynamic>> rawData) {
    List<T> results = <T>[];
    
    rawData.forEach(
        (Map<String, dynamic> rawDataEntry) => results.add(
            manager._spawn(rawDataEntry, onConflict)
        )  
    );
    
    return results;
  }
  
}