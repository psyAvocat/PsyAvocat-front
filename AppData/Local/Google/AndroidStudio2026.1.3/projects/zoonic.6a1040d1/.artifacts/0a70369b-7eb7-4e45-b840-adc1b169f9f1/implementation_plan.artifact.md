# Plan d'implémentation : Modernisation du Backend Zoonic

Ce projet vise à transformer le flux de téléchargement synchrone actuel en un flux asynchrone robuste en deux phases (Analyse puis Job).

## User Review Required

> [!IMPORTANT]
> L'utilisation d'un stockage en mémoire (`ConcurrentHashMap`) signifie que si le serveur redémarre, les téléchargements en cours seront perdus. Pour une V1, c'est acceptable, mais à terme, une base de données sera nécessaire.

> [!WARNING]
> L'augmentation du timeout à 900s (15 min) est nécessaire pour les longues vidéos, mais le mode asynchrone évite de bloquer les threads du serveur Tomcat.

## Proposed Changes

### Configuration

#### [MODIFY] [application.properties](file:///C:/Users/Kalandew12/StudioProjects/Zoonic/src/main/resources/application.properties)
- Ajout de `zoonic.media.max-duration-seconds=7200`.
- Ajout de `zoonic.download.max-concurrent-jobs=3`.
- Ajout de `tools.concurrent-fragments=4`.

#### [NEW] [AsyncConfig.java](file:///C:/Users/Kalandew12/StudioProjects/Zoonic/src/main/java/com/app/zoonic/config/AsyncConfig.java)
- Configuration de `@EnableAsync` et définition d'un `TaskExecutor` personnalisé pour contrôler la concurrence.

---

### Modèles et DTOs

#### [NEW] [MediaInfo.java](file:///C:/Users/Kalandew12/StudioProjects/Zoonic/src/main/java/com/app/zoonic/model/MediaInfo.java)
- Record contenant : id, title, durationSeconds, thumbnailUrl, platform, audioAvailable, playlist.

#### [NEW] [DownloadStatus.java](file:///C:/Users/Kalandew12/StudioProjects/Zoonic/src/main/java/com/app/zoonic/model/DownloadStatus.java)
- Enum : PENDING, DOWNLOADING, CONVERTING, COMPLETED, FAILED.

#### [NEW] [DownloadJob.java](file:///C:/Users/Kalandew12/StudioProjects/Zoonic/src/main/java/com/app/zoonic/model/DownloadJob.java)
- Classe mutable (ou record avec updates) pour suivre la progression, le statut et le chemin du fichier final.

#### [NEW] [MediaAnalysisResponse.java](file:///C:/Users/Kalandew12/StudioProjects/Zoonic/src/main/java/com/app/zoonic/dto/MediaAnalysisResponse.java)
- Record : eligible, reason, mediaInfo.

---

### Services

#### [NEW] [MediaEligibilityService.java](file:///C:/Users/Kalandew12/StudioProjects/Zoonic/src/main/java/com/app/zoonic/service/MediaEligibilityService.java)
- Logique de validation métier (durée, format, plateforme).

#### [NEW] [MediaAnalysisService.java](file:///C:/Users/Kalandew12/StudioProjects/Zoonic/src/main/java/com/app/zoonic/service/MediaAnalysisService.java)
- Exécution de `yt-dlp --dump-json` et parsing du résultat via Jackson.

#### [NEW] [DownloadJobService.java](file:///C:/Users/Kalandew12/StudioProjects/Zoonic/src/main/java/com/app/zoonic/service/DownloadJobService.java)
- Gestion de la map des jobs et méthode `@Async` pour piloter `MediaExtractionService`.

#### [MODIFY] [MediaExtractionService.java](file:///C:/Users/Kalandew12/StudioProjects/Zoonic/src/main/java/com/app/zoonic/service/MediaExtractionService.java)
- Mise à jour pour parser la progression (Regex sur stdout) et mettre à jour le job.

---

### Controllers

#### [NEW] [MediaController.java](file:///C:/Users/Kalandew12/StudioProjects/Zoonic/src/main/java/com/app/zoonic/controller/MediaController.java)
- Endpoint `POST /api/media/analyze`.

#### [MODIFY] [DownloadController.java](file:///C:/Users/Kalandew12/StudioProjects/Zoonic/src/main/java/com/app/zoonic/controller/DownloadController.java)
- Endpoint `POST /api/downloads` (crée un job).
- Endpoint `GET /api/downloads/{jobId}` (statut).
- Endpoint `GET /api/downloads/{jobId}/file` (récupération).

## Verification Plan

### Automated Tests
- `./gradlew assemble` pour vérifier la compilation.
- Tests unitaires sur `MediaEligibilityService` pour les limites de durée.

### Manual Verification
- Appel `/api/media/analyze` avec une vidéo YouTube standard -> vérifier les métadonnées.
- Appel `/api/media/analyze` avec une vidéo > 2h -> vérifier `eligible=false`.
- Appel `/api/downloads` -> récupérer le `jobId`.
- Appel répété sur `/api/downloads/{jobId}` -> voir la progression passer de 0 à 100%.
- Appel `/api/downloads/{jobId}/file` -> vérifier que le MP3 est valide.
