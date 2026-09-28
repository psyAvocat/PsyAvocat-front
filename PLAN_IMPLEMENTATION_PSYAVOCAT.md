# PLAN D'IMPLÉMENTATION FRONTEND & ANALYSE D'ARCHITECTURE — PSYAVOCAT

**Document de référence pour le développement de l'application mobile Flutter et son interconnexion avec l'API Spring Boot.**

---

## 1. État des lieux des deux projets

### 1.1 Backend Spring Boot (`PsyAvocat`)
* **Socle technique** : Java 17+, Spring Boot 3, Gradle, Spring Security, MySQL, Firebase Admin SDK.
* **Sécurité & Authentification** :
  * Filtrage via `FirebaseAuthenticationFilter` qui intercepte l'en-tête HTTP standard `Authorization: Bearer <idToken>`.
  * Pas de gestion interne de mot de passe côté Spring Security : Firebase gère les identités, les sessions et l'émission des tokens JWT.
  * Endpoint de validation de session : `GET /me` (retourne le `firebaseUid`, l'`email`, le rôle, l'identité et le statut du profil métier).
* **Endpoints métier déjà implémentés et exposés** :
  1. **Orientation & Diagnostic** (`OrientationController`) :
     * `GET /api/orientation/questionnaires` : Liste des questionnaires d'orientation disponibles.
     * `POST /api/orientation/evaluer` : Soumission des réponses du justiciable et calcul algorithmique du résultat de recommandation.
     * `GET /api/orientation/mes-resultats` : Historique des évaluations d'orientation de l'utilisateur.
  2. **Professionnels** (`ProfessionnelController`) :
     * `GET /api/professionnels?type=AVOCAT|PSYCHOLOGUE&ville=...&specialiteId=...&modeConsultation=...` : Recherche multicritère et filtrage.
     * `GET /api/professionnels/{id}` : Fiche détaillée complète (nom, barreau/spécialité, bio, tarifs, avis, coordonnées).
  3. **Disponibilités & Calendrier** (`DisponibiliteController`) :
     * `GET /api/disponibilites/professionnel/{professionnelId}` : Créneaux horaires libres pour la réservation.
  4. **Prise de Rendez-vous** (`RendezVousController`) :
     * `POST /api/rendez-vous/avocat` : Réservation d'un rendez-vous juridique.
     * `POST /api/rendez-vous/psychologue` : Réservation d'un rendez-vous de suivi psychologique.
     * `GET /api/rendez-vous` : Liste des rendez-vous de l'utilisateur connecté (`getMyRendezVous`).
     * `PATCH /api/rendez-vous/{id}/annuler` : Annulation d'un rendez-vous existant.
  5. **Profils Utilisateurs** (`ProfilController`) :
     * `GET /api/profil` : Récupération du profil courant.
     * `POST /api/profil/justiciable` : Création du profil justiciable pour le patient/client.
     * `PUT /api/profil` : Mise à jour des informations personnelles.
  6. **Autres modules prêts pour extensions futures** : `DossierController`, `MessagerieController`, `ReferentielController` (spécialités), `SeanceController`.

### 1.2 Frontend Flutter (`psyavocat_front`)
* **Socle technique** : Flutter SDK ^3.12.2, Dart.
* **Dépendances déjà installées dans `pubspec.yaml`** :
  * Gestion d'état : `flutter_riverpod: ^3.4.3`
  * Routage déclaratif : `go_router: ^17.5.0`
  * Client HTTP : `dio: ^5.11.1`
  * Authentification & Notifications : `firebase_core: ^4.15.0`, `firebase_auth: ^6.7.0`, `firebase_messaging: ^16.7.0`
  * Typographie & Formats : `google_fonts: ^8.2.1`, `intl: ^0.20.3`
* **Dépendance additionnelle recommandée** :
  * `flutter_svg: ^2.0.17` (indispensable pour afficher le logo vectoriel SVG de PsyAvocat et les icônes haute fidélité sans pixellisation).
* **État actuel du code source** :
  * Le design system de base (`lib/core/theme/`) est déjà bien amorcé avec les couleurs officielles de l'univers Psychologue (`#45088E`), de l'univers Avocat (`#0C2659`), et du dégradé de transition (`#0C2659` ↔ `#45088E`).
  * Les dossiers de fonctionnalités (`lib/features/*`) contiennent pour l'instant des squelettes ou des écrans temporaires sans les maquettes cibles (aucun écran d'onboarding, pas de questionnaire d'orientation, pas de fiche pro détaillée, pas de floating navbar).
  * Aucun dossier `assets/` n'a été créé ni référencé dans `pubspec.yaml`.

---

## 2. Structure préconisée du projet Flutter & Gestion des Assets

### 2.1 Arborescence des Assets (`assets/`)
Nous devons créer et déclarer le dossier `assets/` à la racine de `psyavocat_front` pour stocker les visuels du design system :

```text
psyavocat_front/
├── assets/
│   ├── logos/
│   │   ├── logo_psyavocat.png         # Logo officiel bicolore (Balance + Profil)
│   │   └── logo_psyavocat_white.png   # Variante blanche pour fonds sombres/dégradés
│   ├── images/
│   │   ├── onboarding_lawyer.png      # Photo de l'avocat (Slide 2 onboarding)
│   │   ├── onboarding_psy.png         # Photo de la femme sereine (Slide 3 onboarding)
│   │   ├── avatar_default_lawyer.png  # Photo de Maître Sangaré / profils avocats
│   │   └── avatar_default_psy.png     # Photo profils psychologues
│   └── icons/
│       ├── ic_balance.png             # Icône balance juridique
│       ├── ic_brain.png               # Icône cerveau / soutien psychologique
│       ├── ic_calendar_clock.png      # Icône agenda + horloge du bouton central
│       └── ic_google.png              # Logo Google pour social login
```

**Pourquoi ce choix ?**
1. **Zéro placeholder** : L'expérience utilisateur est immédiatement immersive et fidèle aux maquettes.
2. **Indépendance réseau** : Les éléments clés de l'onboarding et de la marque sont embarqués localement, évitant tout écran blanc ou chargement intempestif au lancement.
3. **Organisation claire** : Séparation stricte entre les éléments de marque (`logos`), les médias contextuels (`images`) et les éléments d'interface (`icons`).

### 2.2 Arborescence du code (`lib/`) : Architecture « Feature-First »

Nous appliquons une architecture modulaire orientée fonctionnalités (*Feature-Driven*) avec Riverpod :

```text
lib/
├── core/
│   ├── config/              # AppConfig (URL API 10.0.2.2 / localhost), AppRouter
│   ├── network/             # DioClient, AuthInterceptor (injection Bearer token), ApiError
│   ├── theme/               # AppColors, AppTheme, AppTypography, AppUniverse, FloatingNavbarTheme
│   ├── utils/               # Formateurs de prix FCFA, validateurs de formulaire
│   └── widgets/             # Composants partagés (AppButton, AppTextField, GradientBackground, LoadingOverlay)
│
├── features/
│   ├── onboarding/          # Carrousel 3 étapes avec dégradé & bouton Suivant
│   ├── auth/                # Login (arche violette, Google login), Register, Mot de passe oublié
│   ├── selection_univers/   # Écran "Quel professionnel recherchez-vous ?" (Choix Avocat / Psychologue)
│   ├── orientation/         # Diagnostic intake (3 étapes, questions, barre de progression dynamique, récapitulatif avec coches, matching loader)
│   ├── navigation/          # ShellRoute avec la Navbar Flottante (Floating Capsule Bar) et son bouton central surélevé
│   ├── home/                # Recommandations ("Nos avocats pour vous", filtres rapides, bannières)
│   ├── professionnels/      # Recherche, listing, fiche détaillée (Présentation, Avis, Tarifs FCFA, Contact)
│   ├── rendez_vous/         # Tunnel de réservation (jours, créneaux horaires, visio/présentiel, confirmation) & liste "Mes rendez-vous" (À venir/Passés/Annulés)
│   ├── contenus/            # Blog, articles et conseils juridiques / santé mentale
│   └── profile/             # Écran Mon profil (Justiciable, informations personnelles, déconnexion)
│
└── main.dart
```

**Pourquoi ce choix architectural ?**
* **Scalabilité maximale** : Chaque fonctionnalité regroupe ses écrans, ses contrôleurs Riverpod et ses modèles, facilitant le travail d'équipe et la maintenance.
* **Isolation des univers** : Le changement de thème dynamique (Avocat vs Psychologue) est piloté par un `universeProvider` Riverpod accessible globalement sans prop-drilling.

---

## 3. Charte graphique & Système de Design Multi-Univers

### 3.1 Les codes couleurs officiels

| Univers / Rôle | Couleur Primaire | Nuance Claire (Surfaces) | Nuance Bordure | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **Univers Juridique (Avocat)** | `#0C2659` (Bleu Nuit) | `#EFF4FB` | `#B5CEF0` | Boutons d'action, barres de progression, indicateurs d'onglets, pastille centrale |
| **Univers Santé (Psychologue)** | `#45088E` (Violet Profond) | `#F7F1FD` | `#D6BEF5` | Boutons d'action, barres de progression, indicateurs d'onglets, pastille centrale |
| **Phase Découverte / Onboarding** | `Gradient #0C2659 ➔ #45088E` | `#FAFAFB` | `#E4E6EB` | Écran d'accueil, boutons de l'onboarding, arche de login, identité PsyAvocat |

* **Typographie** : Police sans-serif moderne (*Plus Jakarta Sans* ou *Outfit*), assurant lisibilité et modernité.
  * Titres : Noir doux `#383636` (Semi-Bold / Bold), pas de noir pur pour un confort oculaire optimal.
  * Sous-titres et métadonnées : Gris neutre `#676464`.
  * Placeholders de saisie : `#989494`.
* **Surfaces & Cartes** :
  * Fond général de l'application : Blanc cassé moderne `#FAFAFB`.
  * Cartes de contenu : Blanc pur `#FFFFFF`, bordure subtile `#E4E6EB`, rayon d'arrondi `16px` à `20px`.
  * Ombres : `BoxShadow(color: Color(0x0F000000), blurRadius: 18, offset: Offset(0, 4))`.
* **Composants signatures** :
  * **Champs de formulaire** : Contours arrondis (12px), icône de visibilité sur mot de passe, fond blanc pur.
  * **Bouton Pilule** : Hauteur 54px, arrondi complet (pill shape 28px), texte blanc bold, dégradé ou couleur unie selon l'univers.
  * **Navbar Flottante (Floating Capsule)** : Positionnée en bas avec une marge de 16px, bords très arrondis (32px), fond blanc avec ombre douce, 5 onglets avec labels lisibles, et bouton central "Rendez-vous" surélevé dans une pastille circulaire de l'univers actif.

---

## 4. Stratégie de communication avec le Backend Spring Boot

```text
┌────────────────────────────────┐
│      APPLICATION FLUTTER       │
│  (State: Riverpod / UI: GoRouter)
└───────────────┬────────────────┘
                │ 1. Inscription / Connexion (Email/Password ou Google)
                ▼
┌────────────────────────────────┐
│     FIREBASE AUTHENTICATION    │
│    (Émet un Firebase ID Token) │
└───────────────┬────────────────┘
                │ 2. idToken (JWT) récupéré côté Flutter
                ▼
┌────────────────────────────────────────────────────────┐
│             DIO HTTP CLIENT (Flutter)                 │
│  Intercepteur automatique : Bearer <idToken>          │
│  Base URL : 10.0.2.2:8080/api (Android) ou localhost  │
└───────────────┬────────────────────────────────────────┘
                │ 3. Requêtes REST protégées
                ▼
┌────────────────────────────────────────────────────────┐
│             BACKEND SPRING BOOT                        │
│  - FirebaseAuthenticationFilter valide le JWT          │
│  - GET /me vérifie le compte & rôle                   │
│  - Contrôleurs métier (Orientation, Pros, RDV...)     │
│  - Persistance dans MySQL                              │
└────────────────────────────────────────────────────────┘
```

### Détail des flux de données :
1. **Gestion de session** :
   * Au démarrage de l'app, Flutter vérifie `FirebaseAuth.instance.authStateChanges()`.
   * Dès qu'un token est disponible, un appel à `GET /me` synchronise l'ID utilisateur backend (`userId`) et le rôle (`JUSTICIABLE`).
2. **Tunnel d'orientation** :
   * Flutter récupère les questions via `GET /api/orientation/questionnaires`.
   * L'utilisateur répond étape par étape (sauvegarde dans l'état Riverpod local).
   * L'écran de récapitulatif affiche les choix validés avec coches vertes.
   * Clic sur "Confirmer" ➔ `POST /api/orientation/evaluer` avec la charge utile `SoumissionQuestionnaireRequest`.
   * Le backend retourne le `ResultatOrientationDTO` contenant la liste des profils recommandés.
3. **Exploration & Fiche Professionnel** :
   * `GET /api/professionnels` avec filtres (`type`, `ville`, `specialiteId`).
   * `GET /api/professionnels/{id}` pour afficher la fiche de Maître Sangaré ou Claire Dubois (Présentation, Avis, Tarifs FCFA, Langues).
4. **Prise de Rendez-vous** :
   * `GET /api/disponibilites/professionnel/{id}` pour afficher le ruban de dates et les badges horaires libres.
   * `POST /api/rendez-vous/avocat` ou `/psychologue` avec date/heure et motif.
   * `GET /api/rendez-vous` pour alimenter l'onglet "Mes rendez-vous" (À venir / Passés / Annulés).

---

## 5. Parcours Utilisateur & Ordre d'affichage des interfaces (Flow complet)

Le flux de navigation respecte rigoureusement la chronologie logique de l'expérience utilisateur :

```text
[1. Splash Screen] ──▶ [2. Onboarding 3 Slides] ──▶ [3. Connexion / Inscription]
                                                              │
                                                              ▼
                                                   [4. Choix de l'Univers]
                                                   (⚖️ Avocat vs 🧠 Psychologue)
                                                              │
                                                              ▼
                                               [5. Questionnaire Diagnostic]
                                               (Étape 1 ➔ Étape 2 ➔ Étape 3)
                                                              │
                                                              ▼
                                               [6. Récapitulatif Réponses]
                                                              │
                                                              ▼
                                               [7. Matching Algorithmique]
                                                              │
                                                              ▼
                                               [8. Shell Principal (Floating Navbar)]
                                               ├── Onglet 1 : Accueil & Recommandations
                                               ├── Onglet 2 : Recherche Professionnels
                                               ├── Onglet 3 (Centre) : Prendre RDV
                                               ├── Onglet 4 : Mes Rendez-vous & Dossiers
                                               └── Onglet 5 : Mon Profil Justiciable
                                                              │
                                                              ▼
                                               [9. Fiche Détaillée & Booking]
```

### Description détaillée de chaque étape :

1. **Écran 1 : Splash Screen Natif**
   * Affiché pendant le bootstrap Firebase et la vérification de session (1 à 2 secondes).
   * Logo officiel PsyAvocat centré sur fond blanc épuré.

2. **Écran 2 : Carrousel d'Onboarding (3 Slides avec dégradé)**
   * *Slide 1* : Logo PsyAvocat + slogan *"Votre solution juridique et psychologique"* (Point 1 actif).
   * *Slide 2* : *"Trouvez un avocat à votre écoute"* + photo avocat + bouton *"Suivant"* (Point 2 actif).
   * *Slide 3* : *"Trouver le psychologue qui vous comprend"* + photo + bouton *"Commencer"* (Point 3 actif).
   * Style : Dégradé signature Violet ↔ Bleu Nuit sur les boutons.

3. **Écran 3 : Authentification (Connexion / Inscription)**
   * Arche supérieure violette avec logo PsyAvocat intégré.
   * Formulaire : Email/Téléphone, Mot de passe avec toggle masquage.
   * Liens : *"Mot de passe oublié ?"*, bouton *"Se connecter"* en dégradé, authentification via Google, lien *"S'inscrire"*.

4. **Écran 4 : Sélection de la Catégorie / Univers**
   * Titre : *"Quel professionnel recherchez-vous ?"*.
   * Deux grandes cartes interactives avec icônes et chevrons :
     * **Avocat** (Conseil juridique et accompagnement) ➔ Active le thème **Bleu Nuit**.
     * **Psychologue** (Écoute et soutien psychologique) ➔ Active le thème **Violet**.

5. **Écran 5 : Questionnaire d'orientation (Diagnostic Intake)**
   * En-tête : Bouton retour `<`, bouton *"Ignorer"*.
   * Barre de progression par segments (adoptant la couleur de l'univers choisi).
   * Questions successives :
     * Étape 1 : *"Quel est votre problème principal ?"*
     * Étape 2 : *"Qui est principalement concerné par votre problème ?"*
     * Étape 3 : *"Quelle situation correspond le mieux à votre problème ?"*
   * Options radio dans des cartes à bordures douces et bouton *"Suivant"*.

6. **Écran 6 : Récapitulatif des Réponses**
   * Carte centrale résumant les choix de l'utilisateur avec coches vertes de validation.
   * Boutons : *"Reprendre"* pour modifier les réponses, ou *"Valider"* pour lancer la recherche.

7. **Écran 7 : Écran de Transition / Matching Algorithmique**
   * Micro-animation élégante de calcul ("Recherche des meilleurs profils correspondants...").

8. **Écran 8 : Accueil & Résultats (« Nos avocats pour vous » / « Nos psychologues pour vous »)**
   * Navigation intégrée avec la **Navbar Flottante** (5 onglets).
   * Liste des cartes de profils recommandés (ex: *Maître Sangaré*, *Droit du travail*, *Bamako*).

9. **Écran 9 : Fiche Détaillée du Professionnel**
   * Grande photo de couverture immersive.
   * Nom, barreau, statut "En ligne", note et nombre d'avis.
   * Onglets segmentés : *Présentation*, *Avis*, *Dispo.*.
   * Section "À propos" et "Consultation & Tarifs" avec montants en FCFA.
   * Bouton d'action principal : *"Prendre rendez-vous"*.

10. **Écran 10 : Prise de Rendez-vous (Booking)**
    * Ruban horizontal de dates (Lundi, Mardi...) + mini-calendrier mensuel.
    * Sélection du créneau horaire (09:00, 10:00, 11:30...).
    * Bouton *"Confirmer le rendez-vous"* ➔ Redirection vers la liste des rendez-vous.

11. **Écran 11 : Gestion des Rendez-vous (« Mes rendez-vous »)**
    * Onglets : *À venir*, *Passés*, *Annulés*.
    * Cartes avec badges date, heure, nom du professionnel, type (Visioconférence / Cabinet), statut (*Confirmé*, *En attente*).

12. **Écran 12 : Espace Contenus & Articles**
    * Barre de recherche avec filtres de catégories (*Conseils juridiques*, *Santé mentale*, *Vie pratique*).
    * Cartes d'articles avec temps de lecture estimé.

13. **Écran 13 : Espace Mon Profil (Justiciable)**
    * Photo avatar, statut *"Justiciable"*, menu complet (Mes informations, Mes préférences, Sécurité, Déconnexion).

---

## 6. Plan d'Implémentation Étape par Étape

* [ ] **Phase 1 : Socle, Assets & Design System Multi-Univers**
  * Créer le dossier `assets/` (logos, photos, icônes) et mettre à jour `pubspec.yaml` (incluant `flutter_svg`).
  * Finaliser `app_theme.dart` et `universe_provider.dart` pour le basculement dynamique du thème.
  * Créer les composants réutilisables haut de gamme (boutons pill avec dégradé, champs stylisés, floating navbar).

* [ ] **Phase 2 : Onboarding, Authentification & Choix d'Univers**
  * Implémenter le carrousel d'onboarding 3 slides avec dégradé.
  * Reconstruire l'écran de connexion fidèle à la maquette (arche violette, Google login).
  * Implémenter l'écran de choix de catégorie (*Avocat* vs *Psychologue*) avec mutation du thème actif.

* [ ] **Phase 3 : Questionnaire de Diagnostic & Algorithme de Matching**
  * Implémenter le flux de questions avec barre de progression dynamique.
  * Construire l'écran de récapitulatif avec les coches vertes et l'animation de matching.
  * Relier au contrôleur Spring Boot `POST /api/orientation/evaluer`.

* [ ] **Phase 4 : Navigation Principale & Écrans Métier**
  * Mettre en place le `ShellRoute` avec la navbar flottante moderne à 5 onglets et bouton surélevé.
  * Implémenter l'écran d'accueil avec les profils recommandés.
  * Implémenter la fiche détaillée du professionnel avec présentation et tarifs FCFA.
  * Implémenter le sélecteur de dates/heures et la confirmation de rendez-vous reliés à `DisponibiliteController` et `RendezVousController`.
  * Implémenter l'écran "Mes rendez-vous" (À venir / Passés / Annulés).
  * Implémenter les écrans "Contenus et articles" et "Mon Profil".

* [ ] **Phase 5 : Validation & Finitions Graphiques**
  * Tests d'intégration et contrôle de la cohérence visuelle sur toutes les résolutions.
