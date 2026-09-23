# PSYAVOCAT — CONTEXTE DU PROJET FRONTEND

## 1. Présentation générale

**PsyAvocat** est une plateforme de mise en relation entre des utilisateurs et des professionnels du droit et de la psychologie.

La plateforme est composée de plusieurs parties :

* une **application mobile Flutter** destinée aux utilisateurs ;
* des **espaces professionnels** destinés aux avocats et psychologues ;
* un **espace d'administration** ;
* un **site public / CMS** ;
* une **API backend Spring Boot** ;
* une **base de données MySQL**.

Le backend a été développé en **Java avec Spring Boot et Gradle**.

Le présent travail concerne désormais principalement le **frontend Flutter**.

L'objectif immédiat est :

1. initialiser correctement le projet Flutter ;
2. définir son architecture ;
3. préparer sa communication avec l'API Spring Boot existante ;
4. synchroniser progressivement le frontend avec les modèles et les règles métier déjà définis côté backend ;
5. mettre en place une base suffisamment propre pour développer les fonctionnalités par la suite.

Il ne faut pas recréer dans Flutter la logique métier qui appartient au backend.

---

# 2. Architecture générale

L'architecture cible est la suivante :

```text
                    APPLICATION FLUTTER
                           |
             +-------------+-------------+
             |                           |
      Firebase Auth               Firebase FCM
             |                           |
             +-------------+-------------+
                           |
                           v
                  SPRING BOOT API
                           |
                           v
                        MySQL
```

### Firebase

Firebase est utilisé uniquement pour :

* **Firebase Authentication**
* **Firebase Cloud Messaging (FCM)**

Les services suivants ne sont pas utilisés :

* Firebase Firestore ;
* Firebase Storage.

Les données métier sont stockées dans **MySQL** via le backend Spring Boot.

Les documents métier sont également gérés côté backend et stockés dans MySQL sous forme binaire avec leurs métadonnées.

---

# 3. Rôle du frontend Flutter

L'application Flutter constitue la couche d'interface et d'interaction avec l'utilisateur.

Elle devra notamment :

* afficher les données provenant de l'API ;
* permettre à l'utilisateur de saisir et modifier des informations ;
* gérer la navigation ;
* gérer les états de chargement, de succès et d'erreur ;
* communiquer avec l'API Spring Boot ;
* gérer l'authentification Firebase ;
* transmettre au backend les informations nécessaires après authentification ;
* recevoir et afficher les notifications ;
* gérer ultérieurement les fonctionnalités temps réel avec WebSocket ;
* respecter les règles métier définies par le backend.

Le frontend ne doit pas dupliquer les règles métier complexes déjà présentes dans Spring Boot.

Par exemple, Flutter ne doit pas décider seul qu'un rendez-vous est valide simplement parce qu'un créneau semble disponible. La validation finale appartient au backend.

---

# 4. Authentification

L'authentification repose sur **Firebase Authentication**.

Le fonctionnement prévu est :

```text
Utilisateur
    |
    v
Firebase Authentication
    |
    v
Token Firebase
    |
    v
API Spring Boot
    |
    v
Vérification du token
```

Le backend devra vérifier ultérieurement les tokens Firebase.

L'utilisateur possède également une représentation métier dans MySQL.

### Important

Le frontend Flutter ne doit pas mettre en place une authentification classique indépendante avec :

* username/password gérés directement par Spring Security ;
* système de session personnalisé remplaçant Firebase.

Firebase Authentication constitue le mécanisme d'authentification utilisateur prévu pour le projet.

Le frontend devra donc être préparé pour :

* connexion ;
* inscription ;
* déconnexion ;
* récupération du token Firebase ;
* transmission du token lors des appels API nécessitant une authentification.

---

# 5. Synchronisation Flutter ↔ Spring Boot

Le frontend doit communiquer avec le backend via son **API REST**.

La responsabilité des couches est séparée :

```text
Flutter
    |
    | HTTP / REST
    v
Spring Boot
    |
    | JPA / Hibernate
    v
MySQL
```

Flutter ne communique jamais directement avec MySQL.

Flutter ne doit pas accéder directement aux données métier stockées dans la base.

Toutes les opérations métier passent par l'API Spring Boot.

---

# 6. Structure générale du frontend

Le projet Flutter devra être organisé de manière propre et évolutive.

Une architecture de départ peut être organisée autour de responsabilités telles que :

```text
lib/
├── core/
│   ├── config/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── router/
│   └── utils/
│
├── data/
│   ├── models/
│   ├── datasources/
│   └── repositories/
│
├── domain/
│   ├── entities/
│   └── repositories/
│
├── presentation/
│   ├── auth/
│   ├── home/
│   ├── patient/
│   ├── avocat/
│   ├── psychologue/
│   ├── rendez_vous/
│   ├── dossier/
│   ├── messagerie/
│   └── notifications/
│
└── main.dart
```

Cette structure pourra évoluer lorsque les fonctionnalités seront implémentées.

La priorité actuelle n'est pas de créer toutes les fonctionnalités, mais de poser une base cohérente permettant de connecter progressivement Flutter au backend.

---

# 7. Synchronisation des modèles

Le backend contient déjà les principales entités métier.

Les modèles Flutter devront correspondre aux **DTO / réponses JSON exposés par l'API**, et non être copiés aveuglément à partir des classes JPA.

Il faut donc distinguer :

```text
Entity JPA backend
        ≠
Model Flutter
```

Une entité JPA décrit la persistance côté serveur.

Un modèle Flutter représente les données reçues ou envoyées par l'application.

Le frontend ne doit donc pas supposer qu'un champ présent dans une entité JPA sera nécessairement exposé tel quel par l'API.

La structure définitive des modèles Flutter devra suivre les contrats API réellement exposés par Spring Boot.

---

# 8. Utilisateurs et professionnels

Le cœur du modèle est constitué des acteurs suivants :

* Utilisateur ;
* Patient ;
* Justiciable ;
* Professionnel ;
* Avocat ;
* Psychologue ;
* Administrateur.

### Utilisateur

Classe de base abstraite côté backend.

Attributs métier :

```text
id
nom
prenom
email
motDePasse
telephone
dateInscription
```

Le mot de passe ne doit pas être manipulé comme un mot de passe classique côté Flutter lorsque Firebase Authentication est utilisé.

Le frontend devra suivre le mécanisme d'authentification Firebase prévu.

### Patient

Hérite de :

```text
Utilisateur
```

Aucun attribut spécifique supplémentaire n'est actuellement défini.

### Justiciable

Hérite de :

```text
Utilisateur
```

Aucun attribut spécifique supplémentaire n'est actuellement défini.

### Administrateur

Hérite de :

```text
Utilisateur
```

Ses principales responsabilités métier concernent notamment :

* validation des professionnels ;
* modération ;
* activation/désactivation ;
* suspension ;
* gestion des profils.

Ces opérations seront exposées ultérieurement par l'API.

### Professionnel

Classe abstraite.

Attributs :

```text
biographie
ville
adresse
modeConsultation
statutValidation
```

### Avocat

Hérite de :

```text
Professionnel
```

Attribut :

```text
numeroBarreau
```

### Psychologue

Hérite de :

```text
Professionnel
```

Attribut :

```text
numeroAgrement
```

---

# 9. Vérification des professionnels

Lorsqu'un professionnel crée son compte, son statut initial est :

```text
PENDING
```

Les statuts prévus sont :

```text
PENDING
APPROVED
REJECTED
SUSPENDED
```

La validation est réalisée manuellement par un administrateur.

Le frontend devra être capable de représenter correctement ces différents états.

Par exemple :

```text
PENDING   → profil en attente de vérification
APPROVED  → profil validé
REJECTED  → profil rejeté
SUSPENDED → profil suspendu
```

Aucune API externe de vérification ne doit être supposée.

---

# 10. Spécialités et catégories de besoin

Deux concepts différents doivent impérativement rester séparés.

### Specialite

Représente ce que le professionnel sait traiter.

```text
id
nom
description
```

### CategorieBesoin

Représente le besoin exprimé par l'utilisateur.

```text
id
nom
description
typeProfessionnel
actif
```

Il ne faut pas fusionner :

```text
Specialite
```

et

```text
CategorieBesoin
```

dans un seul modèle.

Les relations plusieurs-à-plusieurs définies côté backend devront être représentées côté Flutter en fonction du contrat API.

---

# 11. Dossiers juridiques

Un `Dossier` représente un dossier soumis par un justiciable/client dans le cadre d'une démarche avec un avocat.

Attributs :

```text
id
titre
description
dateOuverture
statut
```

Un même dossier peut être envoyé à plusieurs avocats.

La relation est donc représentée par :

```text
SoumissionDossier
```

Attributs :

```text
id
dateSoumission
statut
reponse
tarifPropose
dateReponse
```

Cette classe constitue une donnée métier importante.

Elle permet notamment de savoir :

* quel dossier a été envoyé ;
* à quel avocat ;
* quand il a été envoyé ;
* dans quel état se trouve la soumission ;
* quelle réponse a été donnée ;
* quel tarif a éventuellement été proposé.

---

# 12. Pièces jointes et échéances

### PieceJointe

Attributs :

```text
id
nom
url
dateAjout
```

Le document réel est géré côté backend.

Le frontend devra respecter le mécanisme d'upload/download exposé par l'API.

Firebase Storage n'est pas utilisé.

### Echeance

Attributs :

```text
id
description
date
statut
```

Elle permet de suivre les échéances associées aux dossiers juridiques.

---

# 13. Rendez-vous

La prise de rendez-vous suit deux workflows différents selon le professionnel.

## Psychologue

```text
Patient
   ↓
Consulte les disponibilités
   ↓
Choisit directement un créneau
   ↓
Paiement simulé
   ↓
Rendez-vous validé
```

## Avocat

```text
Client
   ↓
Soumet son dossier à un ou plusieurs avocats
   ↓
Un avocat accepte la prise en charge
   ↓
Le client choisit un créneau
   ↓
Paiement simulé
   ↓
Rendez-vous validé
```

### Important

Il n'existe pas de workflow général :

```text
Demande de rendez-vous
        ↓
Acceptation / refus du rendez-vous
```

Le frontend ne doit donc pas introduire un système de demande/acceptation de rendez-vous qui n'existe pas dans les règles métier.

Le professionnel peut cependant annuler un rendez-vous déjà planifié.

---

# 14. Disponibilités

Les professionnels peuvent gérer leurs disponibilités.

Une disponibilité contient :

```text
id
date
heureDebut
heureFin
statut
```

Le frontend devra permettre ultérieurement :

* création ;
* modification ;
* suppression ;
* publication ;
* indisponibilité.

Les conflits de créneaux doivent être contrôlés principalement côté backend.

Le frontend peut effectuer des validations d'interface, mais la validation définitive appartient au serveur.

---

# 15. Séances et suivi psychologique

### Seance

```text
id
date
statut
```

### NoteSeance

```text
id
contenu
dateCreation
```

### FichePatient

```text
id
dateCreation
```

`FichePatient` est liée au :

* Patient ;
* Psychologue ;
* Seance.

Les règles d'accès à ces données sont particulièrement importantes et devront être contrôlées côté backend.

Le frontend ne doit jamais considérer qu'un simple affichage conditionnel constitue une protection suffisante des données.

---

# 16. Orientation psychologique

Le module d'orientation comprend :

### Questionnaire

```text
id
titre
type
actif
```

### Question

```text
id
texte
ordre
obligatoire
```

### Reponse

```text
id
libelle
valeur
poids
```

### ResultatOrientation

```text
id
dateEvaluation
score
```

Le frontend servira principalement à :

* afficher les questionnaires ;
* permettre leur remplissage ;
* envoyer les réponses ;
* afficher le résultat retourné par le backend.

Le calcul métier du résultat ne doit pas être considéré comme une responsabilité du frontend.

---

# 17. Messagerie

La plateforme possède une messagerie entre utilisateurs et professionnels.

Le modèle métier comprend :

```text
Conversation
MessageContact
```

### Conversation

```text
id
dateCreation
statut
```

### MessageContact

```text
id
objet
contenu
dateEnvoi
```

Le temps réel sera ajouté ultérieurement à l'aide de **WebSocket**.

Dans un premier temps, le frontend peut fonctionner avec les API REST prévues par le backend.

Il ne faut pas créer artificiellement un modèle `UtilisateurMessage`.

Une classe `ParticipantConversation` pourra exister côté backend si elle est nécessaire pour gérer les participants et leurs informations propres.

---

# 18. Notifications

Les notifications métier sont persistées dans MySQL via le backend.

Le modèle comprend :

```text
id
type
contenu
dateEnvoi
lienVisio
```

Firebase Cloud Messaging sera utilisé pour envoyer ultérieurement des notifications push aux appareils.

La logique peut donc être distinguée ainsi :

```text
Spring Boot
    ↓
Notification métier persistée
    ↓
Firebase Cloud Messaging
    ↓
Appareil Flutter
```

---

# 19. Paiements

Une seule classe métier :

```text
Paiement
```

Elle peut concerner :

* un rendez-vous ;
* un abonnement professionnel.

Attributs :

```text
id
montant
datePaiement
statut
methode
```

Les types de paiement prévus sont :

```text
RENDEZ_VOUS
ABONNEMENT
```

Pour un rendez-vous, le montant payé correspond à **20 % du montant du rendez-vous** dans la V1.

Le frontend devra afficher le montant réellement demandé et retourné par le backend.

Il ne faut pas créer une classe différente pour les paiements d'abonnement.

---

# 20. Abonnements et forfaits

### Forfait

```text
id
nom
description
prix
duree
actif
```

### Abonnement

```text
id
dateDebut
dateFin
statut
```

### Utilisation

```text
id
fonctionnalite
nombreUtilisations
limiteGratuite
derniereUtilisation
```

Le professionnel peut souscrire à un forfait et son abonnement possède son propre cycle de vie :

```text
souscrire
renouveler
suspendre
resilier
```

Les paiements d'abonnement sont représentés par la même classe `Paiement`.

---

# 21. Contenu et activités

### Contenu

```text
id
titre
description
contenu
type
datePublication
actif
```

Le contenu peut être :

* publié ;
* modifié ;
* archivé ;
* consulté.

### Activite

```text
id
titre
description
type
dateDebut
dateFin
actif
```

Les activités peuvent être :

* lancées ;
* terminées ;
* rejointes par les utilisateurs.

Ces fonctionnalités pourront être développées progressivement dans l'application.

---

# 22. Correspondance Backend ↔ Frontend

Le backend existant constitue la source de vérité pour les règles métier.

La synchronisation devra progressivement suivre cette logique :

```text
BACKEND
Entity / DTO
      ↓
API REST
      ↓
JSON
      ↓
FLUTTER
Model
      ↓
Repository
      ↓
Service / State Management
      ↓
UI
```

Exemple :

```text
Spring Boot
    |
    | GET /api/professionnels
    v
JSON
    |
    v
ProfessionnelModel
    |
    v
ProfessionnelRepository
    |
    v
Provider / State Management
    |
    v
Écran Flutter
```

Le frontend ne doit pas accéder directement à la base de données.

---

# 23. Gestion des erreurs côté frontend

Le frontend devra prévoir les principaux types de situations :

```text
Erreur réseau
Erreur serveur
Erreur d'authentification
Token Firebase expiré
Erreur de validation
Ressource inexistante
Accès non autorisé
Donnée indisponible
Timeout
```

Les erreurs retournées par le backend devront être converties en états compréhensibles par l'interface.

Exemple :

```text
API
 ↓
Erreur HTTP / réponse d'erreur
 ↓
Data layer
 ↓
Exception / Failure
 ↓
State management
 ↓
UI
```

L'application ne doit pas afficher directement les détails techniques internes du backend à l'utilisateur.

---

# 24. Structure des modèles Flutter

Le frontend devra progressivement disposer de modèles correspondant aux ressources exposées par l'API, notamment :

```text
Utilisateur
Patient
Justiciable
Professionnel
Avocat
Psychologue
Administrateur

Dossier
PieceJointe
Echeance
SoumissionDossier

Disponibilite
RendezVous
Seance
NoteSeance
FichePatient

Specialite
CategorieBesoin

Questionnaire
Question
Reponse
ResultatOrientation

Conversation
MessageContact
Notification
Signalement

Paiement
Forfait
Abonnement
Utilisation

Contenu
Activite
```

Cependant, ces modèles Flutter ne doivent être créés qu'en fonction des **contrats API réellement disponibles**.

Il ne faut pas supposer qu'une classe Java doit obligatoirement devenir une classe Dart identique.

---

# 25. Objectif de la tâche actuelle

La tâche actuelle concerne exclusivement la **mise en place initiale du frontend Flutter et sa préparation à la synchronisation avec le backend Spring Boot déjà créé**.

Les objectifs sont :

### Étape 1 — Initialisation

Créer le projet Flutter proprement.

### Étape 2 — Architecture

Mettre en place une structure de dossiers adaptée à l'évolution du projet.

### Étape 3 — Configuration

Préparer :

* Firebase ;
* environnement de développement ;
* URL de l'API backend ;
* gestion des environnements si nécessaire ;
* client HTTP ;
* gestion des erreurs réseau.

### Étape 4 — Authentification

Configurer Flutter avec Firebase Authentication sans remplacer ce mécanisme par une authentification Spring Security classique côté frontend.

### Étape 5 — Communication API

Préparer la communication :

```text
Flutter ↔ Spring Boot
```

avec notamment :

* requêtes HTTP ;
* headers ;
* token Firebase ;
* sérialisation JSON ;
* désérialisation JSON ;
* gestion des erreurs.

### Étape 6 — Synchronisation des modèles

Comparer les modèles nécessaires côté Flutter avec les **DTO et endpoints réellement exposés par le backend**.

### Étape 7 — Première connexion

Mettre en place une première communication fonctionnelle entre Flutter et Spring Boot afin de vérifier que :

```text
Flutter
   ↓
Firebase Auth
   ↓
Token
   ↓
Spring Boot
   ↓
API
   ↓
MySQL
```

fonctionne correctement.

---

# 26. Contraintes importantes

Les règles suivantes doivent être respectées :

* Ne pas inventer de nouvelles règles métier.
* Ne pas recréer dans Flutter la logique métier du backend.
* Ne pas connecter Flutter directement à MySQL.
* Ne pas utiliser Firestore.
* Ne pas utiliser Firebase Storage.
* Utiliser Firebase uniquement pour l'authentification et FCM.
* Respecter les workflows définis pour les rendez-vous.
* Conserver la distinction entre `Specialite` et `CategorieBesoin`.
* Conserver une seule notion de `Paiement`.
* Respecter la relation particulière `Dossier ↔ Avocat` via `SoumissionDossier`.
* Préparer le frontend pour WebSocket sans l'implémenter prématurément.
* Ne pas créer des modèles ou services uniquement parce qu'une classe existe côté Java.
* Ne pas supposer la structure exacte des réponses API sans vérifier les DTO/endpoints du backend.
* Privilégier une architecture Flutter maintenable et évolutive.

---

# 27. Structure Java actuelle du backend

Le backend utilise le package racine :

```text
com.psyavocat
```

Les entités JPA se trouvent dans :

```text
src/main/java/com/psyavocat/entity/
```

Les principales classes sont :

```text
entity/
├── Utilisateur.java
├── Patient.java
├── Justiciable.java
├── Professionnel.java
├── Avocat.java
├── Psychologue.java
├── Administrateur.java
│
├── Dossier.java
├── PieceJointe.java
├── Echeance.java
├── SoumissionDossier.java
│
├── Disponibilite.java
├── RendezVous.java
├── Seance.java
├── NoteSeance.java
├── FichePatient.java
│
├── Specialite.java
├── CategorieBesoin.java
│
├── Questionnaire.java
├── Question.java
├── Reponse.java
├── ResultatOrientation.java
│
├── Conversation.java
├── MessageContact.java
├── Notification.java
├── Signalement.java
│
├── Paiement.java
├── Forfait.java
├── Abonnement.java
├── Utilisation.java
│
├── Contenu.java
└── Activite.java
```

Ces classes constituent le modèle métier actuellement défini côté backend.

Le frontend Flutter doit maintenant être construit **en se synchronisant progressivement avec ce backend**, sans remettre en cause les choix métier déjà établis.

---

# 28. Principe directeur

Le principe à respecter pendant toute l'implémentation est :

> **Le backend porte les règles métier et la persistance. Le frontend Flutter porte l'interface, l'état local, l'expérience utilisateur et la communication avec l'API.**

Avant d'implémenter une fonctionnalité frontend, il faut donc vérifier :

```text
1. Quel est le besoin métier ?
2. Quel endpoint Spring Boot permet de le gérer ?
3. Quel DTO est envoyé/reçu ?
4. Quel modèle Dart correspond à cette réponse ?
5. Comment l'état est-il géré côté Flutter ?
6. Comment l'interface représente-t-elle les différents états ?
```

En cas d'ambiguïté entre le backend et le frontend, il faut se référer au contrat API réel ou demander une clarification plutôt que d'inventer un comportement.
