# Architecture technique — CABINET SAMI BELHARETH

## Vue d'ensemble

```
┌──────────────────────────────────────────────────────────────────┐
│                       PWA (Next.js + React)                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ Espace Médecin  │  │ Espace Secrétaire│  │ Espace Patient  │  │
│  │  (rôle: doctor) │  │  (rôle: staff)  │  │  (rôle: patient)│  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└──────────────────────┬───────────────────────┬──────────────────┘
                       │                       │
                       │  HTTPS + JWT          │
                       ▼                       ▼
┌──────────────────────────────────────────────────────────────────┐
│                    Couche API (Supabase)                         │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Row Level Security (RLS) — Isolation par rôle           │   │
│  └──────────────────────────────────────────────────────────┘   │
│  Auth · Postgres · Storage chiffré · Realtime · Edge functions  │
└──────────────────────┬───────────────────────┬──────────────────┘
                       │                       │
                       ▼                       ▼
       ┌─────────────────────────┐  ┌──────────────────────────┐
       │  PostgreSQL (cloud)     │  │  SQLite local (cache)    │
       │  Données chiffrées      │  │  Offline-first via       │
       │  Backup quotidien       │  │  PowerSync / Replicache  │
       └─────────────────────────┘  └──────────────────────────┘
```

## Choix d'architecture clés

### 1. LOCAL + CLOUD — Application complète dans les deux modes
Contrairement à un simple cache offline, le cabinet dispose **d'une vraie installation locale autonome** ET **d'une réplique cloud complète** :

- **Serveur local cabinet** : PostgreSQL installé sur PC/serveur dédié au cabinet
  - 100% des fonctions disponibles sans internet
  - Données patients ne quittent pas physiquement le cabinet
  - Backup local (disque externe) quotidien
- **Cloud (Supabase / VPS Tunisie)** : réplique chiffrée
  - 100% des fonctions disponibles aussi
  - Accès distant pour médecin (urgences, week-end)
  - Portail patient (RDV, ordonnances, messagerie)
- **Sync bidirectionnelle** : PowerSync ou ElectricSQL
  - Réplication Postgres logique en temps réel
  - Conflits résolus par `updated_at` + audit log
  - Reprise automatique après coupure réseau

### 2. Multi-tenant par rôle
- 3 rôles principaux : `doctor`, `staff`, `patient`
- Row Level Security (RLS) PostgreSQL : chaque rôle voit uniquement ce qu'il doit voir
- Le patient ne voit JAMAIS les données d'un autre patient
- Le médecin voit tous les patients du cabinet
- La secrétaire voit les données administratives mais pas les notes cliniques sensibles

### 3. PWA (Progressive Web App)
- Installable sur PC (Chrome/Edge) et mobile (iOS/Android)
- Service Worker pour mode offline
- Notifications push (RDV, ordonnances)
- Une seule codebase pour Web + Mobile

### 4. Chiffrement
- **In-transit** : TLS 1.3
- **At-rest cloud** : AES-256 (Supabase Storage)
- **At-rest local** : chiffrement SQLite via SQLCipher
- **End-to-end** : messagerie patient-médecin

## Stack détaillée

### Frontend
| Couche | Technologie | Rôle |
|---|---|---|
| Framework | Next.js 14 | App Router, RSC, ISR |
| Langage | TypeScript 5 | Typage strict médical |
| UI | Tailwind CSS 3 + shadcn/ui | Design system |
| Animations | Framer Motion | Transitions |
| Forms | React Hook Form + Zod | Validation |
| State | Zustand + TanStack Query | Client + server state |
| PDF | react-pdf + pdfmake | Ordonnances, devis |
| DICOM | Cornerstone.js | Imagerie médicale |
| Dates | date-fns | i18n fr-FR |
| PWA | next-pwa + Workbox | Offline + push |
| Tests | Vitest + Playwright | Unit + E2E |

### Backend
| Couche | Technologie | Rôle |
|---|---|---|
| BaaS | Supabase | Auth, DB, Storage, Realtime |
| DB | PostgreSQL 15 | Données métier |
| Auth | Supabase Auth (JWT) | Rôles + MFA |
| Storage | Supabase Storage | Imagerie + documents |
| Fonctions | Supabase Edge Functions (Deno) | Génération PDF, webhooks |
| Cache local | SQLite (SQLCipher) | Offline |
| Sync | PowerSync ou Replicache | Bidirectionnel |
| Files PDF | UploadThing ou S3 | Stockage économique |

### Intégrations
| Service | Usage |
|---|---|
| WhatsApp Business API | Rappels RDV, ordonnances |
| Infobip / Twilio | SMS Tunisie |
| Konnect / Flouci | Paiements mobile Tunisie |
| CNAM API (si dispo) | Vérification droits + soumission PEC |
| OpenAI / Anthropic | Aide à la décision IA (suggestions protocoles) |
| Cloudinary | Optimisation images |

## Modèle de données simplifié

```
┌──────────────┐         ┌─────────────────┐         ┌──────────────┐
│   profiles   │────────▶│    patients     │────────▶│ consultations│
│ (auth users) │  1:N    │                 │  1:N    │              │
└──────────────┘         └─────────────────┘         └──────┬───────┘
                                  │                          │
                                  │ 1:N                      │ 1:N
                                  ▼                          ▼
                         ┌─────────────────┐         ┌──────────────┐
                         │   appointments  │         │ prescriptions│
                         │     (RDV)       │         │              │
                         └─────────────────┘         └──────────────┘
                                  │
                                  │ 1:N
                                  ▼
                         ┌─────────────────┐         ┌──────────────┐
                         │    surgeries    │────────▶│   devis      │
                         │  (chirurgies)   │  1:N    │   factures   │
                         └─────────────────┘         └──────────────┘
                                  │
                                  │ 1:N
                                  ▼
                         ┌─────────────────┐         ┌──────────────┐
                         │   cnam_pec      │         │   imaging    │
                         │   (PEC CNAM)    │         │  (radio/IRM) │
                         └─────────────────┘         └──────────────┘
```

Voir `data-model.md` pour le schéma SQL complet.

## Sécurité — Détails

### Authentification
- **Médecin/Secrétaire** : email + mot de passe + MFA (TOTP obligatoire)
- **Patient** : numéro téléphone + OTP SMS, ou email + password
- Sessions JWT 1h, refresh token 30j
- Logout auto après inactivité (30 min médecin, 60 min patient)

### Autorisation (RLS PostgreSQL)
```sql
-- Exemple : un patient ne voit que ses propres données
CREATE POLICY "Patient sees own data only"
ON patients FOR SELECT
USING (auth.uid() = profile_id);

-- Exemple : médecin voit tous ses patients
CREATE POLICY "Doctor sees all cabinet patients"
ON patients FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role IN ('doctor', 'staff')
  )
);
```

### Audit log
Toute lecture / écriture sur le dossier patient est tracée :
```sql
CREATE TABLE audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id),
  action text NOT NULL, -- 'read', 'write', 'delete'
  resource_type text NOT NULL, -- 'patient', 'consultation', etc.
  resource_id uuid NOT NULL,
  ip_address inet,
  user_agent text,
  created_at timestamptz DEFAULT now()
);
```

### Conformité CNAM
- Codes actes conformes au **décret 11 juin 2007**
- Génération automatique des formulaires PEC selon templates officiels
- Stockage des accusés de réception CNAM
- Reporting trimestriel automatisé

## Performance

- **TTI** (Time to Interactive) : < 2s sur 4G
- **API p95** : < 200ms
- **Sync local** : optimiste, latence perçue = 0
- **Imagerie DICOM** : streaming progressif

## Évolutivité

- Multi-praticiens (extension à d'autres orthopédistes)
- API publique pour partenaires (kinés, radio)
- Téléconsultation vidéo intégrée (Daily.co ou Twilio)
- App mobile native si besoin (React Native + Expo)
