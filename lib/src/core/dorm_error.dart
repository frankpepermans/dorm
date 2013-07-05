part of dorm;

class DormError implements Error {
  
  final String message;

  DormError(this.message);

  String toString() {
    return message;
  }
}