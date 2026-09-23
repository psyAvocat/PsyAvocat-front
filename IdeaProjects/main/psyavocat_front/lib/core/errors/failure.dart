/// Représentation standard d'un échec pour la couche UI.
class Failure {
  final String message;
  final int? statusCode;

  const Failure(this.message, [this.statusCode]);

  @override
  String toString() => message;
}
