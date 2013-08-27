part of dorm;

class DormError extends Error {
  
  final String message;

  const DormError(this.message);

  String toString() => message;
}