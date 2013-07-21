part of dorm;

abstract class IExternalizable {
  
  //-----------------------------------
  //
  // Public methods
  //
  //-----------------------------------
  
  void readExternal(Map<String, dynamic> data, Serializer serializer, OnConflictFunction onConflict);
  void writeExternal(Map<String, dynamic> data, Serializer serializer);
  
}