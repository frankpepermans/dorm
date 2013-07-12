part of dorm;

class DormError extends Error {
  
  final String message;

  DormError(this.message);

  String toString() {
    return message;
  }
}