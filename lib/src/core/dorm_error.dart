part of dorm;

class DormError extends Error {
  
  final String message;

  DormError(this.message) {
    print(message);
  }

  String toString() => message;
}