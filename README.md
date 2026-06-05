# 🏥 CABINET SAMI BELHARETH — Plateforme Orthopédique

Application PWA dédiée au cabinet de chirurgie orthopédique du **Dr Sami Belhareth** (Salammbô, Tunisie).

> **3 espaces, 1 plateforme** : Médecin · Secrétaire · Patient.

---

## 🎯 Vision

Réinventer la pratique orthopédique en Tunisie avec une plateforme moderne, conforme CNAM, **complète en local ET en cloud** (toutes les fonctions disponibles dans les deux modes), accessible partout (PWA) et pensée par et pour les orthopédistes.

## 🔄 Architecture LOCAL + CLOUD (complète)

L'application fonctionne **intégralement** dans 2 modes simultanés :

### 💻 Mode LOCAL (serveur cabinet)
- Serveur Windows/Linux installé physiquement au cabinet
- Base de données PostgreSQL locale
- **Toutes les fonctions** disponibles : dossier patient, consultation, ordonnance, devis, PEC CNAM, agenda, etc.
- Aucune dépendance internet pour le travail quotidien
- Données médicales confidentielles **ne quittent jamais** le cabinet
- Backup automatique chiffré (disque externe + NAS)

### ☁️ Mode CLOUD (Supabase / VPS Tunisie)
- Réplique chiffrée de la base de données locale
- **Toutes les fonctions aussi** disponibles à distance
- Accès médecin / secrétaire depuis n'importe où (urgence, week-end, déplacement)
- Portail patient complet (RDV, ordonnances, paiement, messagerie)
- App PWA installable sur mobile

### 🔗 Synchronisation temps réel local ↔ cloud
- Toute modification locale → poussée vers cloud (chiffrée)
- Toute modification cloud → tirée vers local
- Résolution de conflit par horodatage + audit log
- Si internet coupé : travail continue en local, sync reprend au retour
- Outil : **PowerSync** ou **ElectricSQL** (réplication bidirectionnelle Postgres)

## 📂 Structure du projet

```
Cabinet-App/
├── mockups/              # Prototypes HTML interactifs (Phase 1)
│   ├── index.html        # Landing + sélection rôle
│   ├── medecin.html      # Espace Médecin
│   ├── secretaire.html   # Espace Secrétaire
│   └── patient.html      # Espace Patient
├── docs/                 # Architecture, roadmap, modèle données
│   ├── architecture.md
│   ├── roadmap.md
│   └── data-model.md
└── README.md
```

## 🚀 Pour voir les maquettes

Ouvrir `mockups/index.html` dans un navigateur (Chrome/Edge recommandé).
Aucune installation, aucune configuration — tout fonctionne en ligne via CDN.

---

## 🛠️ Stack technique cible

### Frontend (PWA Web + Mobile)
- **Next.js 14** (App Router) + **TypeScript**
- **Tailwind CSS** + **shadcn/ui** (design system)
- **Framer Motion** (animations)
- **TanStack Query** + **Zustand** (state)
- **React Hook Form** + **Zod** (validation)
- **react-pdf** + **pdfmake** (génération ordonnances/devis)
- **Cornerstone.js** (visualisation DICOM imagerie)
- **next-pwa** (installable + offline)
- **date-fns** (locale FR)

### Backend (hybride local + cloud)
- **PostgreSQL** (cloud) + **SQLite** (cache local offline)
- **Supabase** (Auth + Storage + Realtime + RLS)
- **PowerSync** ou **Replicache** (sync local↔cloud)
- Stockage chiffré **AES-256**
- **WhatsApp Business API** + **SMS Tunisie** (notifications)
- **Konnect** / **Flouci** (paiements)

### DevOps
- Hébergement : **Vercel** (frontend) + **Supabase** (backend)
- CI/CD : **GitHub Actions**
- Monitoring : **Sentry** + **PostHog**
- Backups quotidiens + chiffrement HDS-like

---

## 🔐 Conformité & Sécurité

- ✅ **Décret CNAM 11 juin 2007** — actes pris en charge orthopédie
- ✅ **Secret médical** (Code de déontologie tunisien)
- ✅ **RGPD-like** : consentement, droit à l'oubli, portabilité
- ✅ Chiffrement bout-en-bout des données médicales
- ✅ Audit log de tous les accès au dossier patient
- ✅ Authentification MFA pour médecin/secrétaire
- ✅ Backups chiffrés quotidiens, restauration testée

---

## 📊 Modules MVP (Phase 1)

| Module | Médecin | Secrétaire | Patient |
|---|---|---|---|
| **Dossier patient 360°** | ✅ | ✅ (lecture admin) | ✅ (son dossier) |
| **Consultation + ordonnance** | ✅ | — | 📥 reçoit |
| **Agenda / RDV** | ✅ | ✅ | ✅ (prise RDV) |
| **Devis & Factures CNAM** | ✅ (vise) | ✅ (gère) | ✅ (consulte) |
| **PEC CNAM automatique** | ✅ | ✅ | — |
| **Imagerie DICOM** | ✅ | — | ✅ (visualise) |
| **Bloc opératoire** | ✅ | ✅ (planning) | — |
| **Messagerie sécurisée** | ✅ | ✅ | ✅ |
| **Rééducation guidée** | ✅ (prescrit) | — | ✅ (suit) |
| **Paiements en ligne** | — | ✅ | ✅ |
| **PWA installable** | ✅ | ✅ | ✅ |
| **Mode hors-ligne** | ✅ | ✅ | ✅ |

---

## 🗓️ Roadmap (vue 30/60/90 jours)

### 📅 J1-30 — Fondations
- [x] Maquettes visuelles 3 espaces (✅ fait)
- [ ] Architecture technique validée
- [ ] Modèle de données médical
- [ ] Setup repo + Supabase + CI/CD
- [ ] Auth + rôles (médecin/secrétaire/patient)
- [ ] Création patient + dossier de base

### 📅 J31-60 — Modules cœur
- [ ] Consultation + ordonnance + génération PDF
- [ ] Agenda / RDV + notifications
- [ ] Templates documents (import .doc → templates dynamiques)
- [ ] Imagerie (upload + visualisation simple)
- [ ] Caisse & encaissements

### 📅 J61-90 — Spécifique orthopédie
- [ ] Protocoles par pathologie (Achille, Hallux V., LCA, PTG, PTH...)
- [ ] PEC CNAM pré-remplis + workflow validation
- [ ] Devis chirurgicaux + barème CNAM
- [ ] Portail patient (RDV en ligne, ordonnances, messagerie)
- [ ] Rééducation guidée (vidéos protocoles)
- [ ] PWA + mode offline

### 🚀 Au-delà (V2+)
- IA d'aide à la décision (suggestions protocole)
- DICOM viewer professionnel (Cornerstone)
- Multi-praticiens (extension à d'autres orthopédistes)
- App mobile native (React Native si besoin)
- Téléconsultation vidéo intégrée
- Statistiques avancées (épidémio cabinet)

---

## 📞 Contact projet

**CABINET SAMI BELHARETH**
Salammbô, Le Kram 2025 · Tunisie
Spécialité : Chirurgie orthopédique et traumatologique
