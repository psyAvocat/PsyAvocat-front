# PsyAvocat — application mobile (Flutter)

## Lancer l'application

Démarrer d'abord le backend Spring Boot (port 8080), puis :

| Appareil                         | Commande                                         |
|----------------------------------|--------------------------------------------------|
| Émulateur Android, Web, desktop  | `flutter run`                                    |
| Téléphone sur le même Wi-Fi      | `flutter run --dart-define=ip=192.168.1.20`      |
| Téléphone en USB                 | `adb reverse tcp:8080 tcp:8080` puis `flutter run --dart-define=ip=localhost` |
| Autre port que 8080              | ajouter `--dart-define=port=9090`                |

`ip` est l'adresse IPv4 du PC qui lance Spring Boot (`ipconfig` sous Windows).
L'adresse utilisée est affichée dans la console au démarrage.

Si le téléphone n'atteint pas le serveur :

- le téléphone et le PC sont sur le même réseau Wi-Fi ;
- le pare-feu Windows autorise les connexions entrantes sur le port 8080 ;
- `http://<ip>:8080/health` s'ouvre dans le navigateur du téléphone.

## Tests

```bash
flutter analyze
flutter test
```
