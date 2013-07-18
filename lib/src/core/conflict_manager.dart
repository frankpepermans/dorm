part of dorm;

class ConflictManager {
  
  //-----------------------------------
  //
  // Static properties
  //
  //-----------------------------------
  
  static final ConflictManager ACCEPT_SERVER = new ConflictManager._acceptServer();
  static final ConflictManager ACCEPT_CLIENT = new ConflictManager._acceptClient();
  
  //-----------------------------------
  //
  // Public properties
  //
  //-----------------------------------
  
  final int type;
  
  //-----------------------------------
  //
  // Factories
  //
  //-----------------------------------
  
  factory ConflictManager._acceptServer() {
    return const ConflictManager._construct(1);
  }
  
  factory ConflictManager._acceptClient() {
    return const ConflictManager._construct(2);
  }
  
  //-----------------------------------
  //
  // Constructor
  //
  //-----------------------------------

  const ConflictManager._construct(this.type);
  
}