# 🗄️ Supabase — Schéma de base de données

## 📁 Contenu

```
supabase/
├── migrations/
│   └── 20260606000001_initial_medical_schema.sql   # Migration initiale (22 tables + RLS)
└── seeds/                                           # Données de seed (à venir)
```

## 🚀 Comment appliquer la migration sur Supabase

### Méthode A — Via le Dashboard Supabase (recommandée, 30 secondes)

1. Allez sur https://supabase.com/dashboard/project/exalunvbrpaxlcqjayjk
2. Cliquez sur **`SQL Editor`** dans le menu de gauche (icône `</>`)
3. Cliquez sur **`+ New query`**
4. Ouvrez le fichier `migrations/20260606000001_initial_medical_schema.sql`
5. **Copiez tout le contenu** (Ctrl+A puis Ctrl+C)
6. **Collez** dans l'éditeur Supabase
7. Cliquez sur le bouton vert **`Run`** (ou Ctrl+Enter)
8. ✅ Attendez le message **"Success. No rows returned"**

Vérifiez ensuite dans **`Table Editor`** que les 22 tables apparaissent.

### Méthode B — Via Supabase CLI (avancé)

```bash
# Prérequis: npm install -g supabase
supabase login
supabase link --project-ref exalunvbrpaxlcqjayjk
supabase db push
```

## 📊 Tables créées (22 au total)

### 👥 Utilisateurs & patients
- `profiles` — Utilisateurs auth (doctor / staff / patient)
- `patients` — Patients du cabinet (avec recherche full-text)
- `medical_history` — Antécédents (médicaux, chirurgicaux, allergies, familiaux)

### 📅 Activité clinique
- `appointments` — Rendez-vous
- `consultations` — Consultations réalisées (avec mesures orthopédiques : EVA, flexion, etc.)
- `prescriptions` + `prescription_items` — Ordonnances
- `surgeries` — Chirurgies (avec implants, anesthésie, CRO)
- `imaging` — Imagerie médicale
- `lab_results` — Résultats biologie

### 💰 Facturation & CNAM
- `quotes` + `quote_lines` — Devis
- `invoices` — Factures
- `payments` — Encaissements (espèces, carte, CNAM, Konnect, Flouci…)
- `cnam_pec` — Prises en charge CNAM
- `cnam_acts_catalog` — Catalogue des 24 actes orthopédiques CNAM (avec barème TND)

### 🏋️ Rééducation
- `rehab_programs` + `rehab_exercises` + `rehab_sessions`

### 💬 Communication
- `message_threads` + `messages` — Messagerie sécurisée patient/cabinet

### 📝 Documents & audit
- `documents` — Certificats, arrêts de travail, lettres
- `audit_log` — Traçabilité de tous les accès au dossier

## 🔒 Sécurité — Row Level Security (RLS)

Toutes les tables sensibles ont RLS activé. Trois rôles utilisateur :

| Rôle | Accès aux dossiers patients | Accès facturation | Accès agenda |
|---|---|---|---|
| `doctor` (Dr Belhareth) | ✅ Lecture/écriture tous patients | ✅ Total | ✅ Total |
| `staff` (secrétaire) | ✅ Lecture/écriture admin | ✅ Total | ✅ Total |
| `patient` | ✅ Son dossier uniquement (lecture) | ✅ Ses factures uniquement | ✅ Ses RDV uniquement |

### Fonctions helpers RLS
- `public.is_doctor()` — vrai si l'utilisateur connecté est médecin
- `public.is_staff()` — vrai si médecin ou secrétaire
- `public.is_patient_of(patient_id)` — vrai si le patient connecté est ce patient

### Profile auto-créé
Un trigger `on_auth_user_created` crée automatiquement une entrée `profiles` à chaque inscription dans `auth.users`. Le rôle par défaut est `patient`.

Pour créer un compte **médecin** ou **secrétaire**, le rôle doit être passé dans les `raw_user_meta_data` lors de l'inscription, ou modifié manuellement par un admin.

## 🌱 Données de seed pré-remplies

Le catalogue **`cnam_acts_catalog`** est rempli avec 24 actes orthopédiques conformes au décret CNAM du 11 juin 2007 :

- PTH / PTG / PUC (prothèses)
- Hallux Valgus (percutané, chevron, DMMO)
- LCA, ménisque, Achille
- Arthroscopie cheville, LLE
- Canal carpien, canal cubital
- Coiffe, Latarjet, acromioplastie
- TTA + MPFL, doigt à ressaut
- Consultations, infiltrations

## ⚙️ Prochaine étape — Connecter Lovable

Une fois la migration appliquée :

1. Dans Lovable, ouvrez votre projet **CABINET SAMI BELHARETH**
2. Cliquez sur l'icône **Supabase** (ou tapez `/supabase`)
3. Choisissez **`Connect to Supabase`**
4. Sélectionnez le projet `exalunvbrpaxlcqjayjk`
5. Lovable récupère les clés automatiquement (chiffrées dans son secret manager)
6. ✅ Lovable voit toutes vos tables et peut générer l'UI dessus

## ⚠️ Important — Stockage médical

L'**imagerie DICOM** et les gros PDF doivent être stockés dans **Supabase Storage** (pas dans la base). Le fichier de migration n'inclut pas la configuration Storage — à faire séparément :

- Bucket `patient-imaging` (privé, accès via signed URLs)
- Bucket `documents` (privé)
- Bucket `prescriptions` (privé)
