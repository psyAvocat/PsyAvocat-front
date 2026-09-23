/// Exception de base pour l'application Flutter PsyAvocat.
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Impossible de contacter le serveur. Vérifiez votre connexion Internet.']);
}

class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Le délai de réponse du serveur a expiré. Veuillez réessayer.']);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Session expirée ou non autorisée. Veuillez vous reconnecter.', super.statusCode = 401]);
}

class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'Vous n\'avez pas les droits nécessaires pour accéder à cette ressource.', super.statusCode = 403]);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'La ressource demandée est introuvable.', super.statusCode = 404]);
}

class ValidationException extends AppException {
  final Map<String, dynamic>? errors;
  const ValidationException(super.message, [this.errors, super.statusCode = 400]);
}

class ServerException extends AppException {
  const ServerException([super.message = 'Une erreur interne est survenue sur le serveur.', super.statusCode = 500]);
}

class AuthException extends AppException {
  const AuthException(super.message);
}
