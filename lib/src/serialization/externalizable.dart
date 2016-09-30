part of dorm;

abstract class Externalizable {
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  void readExternal(Map<String, dynamic> data, Serializer<dynamic, Map<String, dynamic>> serializer, OnConflictFunction onConflict);
  void writeExternal(Map<String, dynamic> data, Serializer<dynamic, Map<String, dynamic>> serializer);
  
}