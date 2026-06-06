# 🚀 Super-prompt Lovable — CABINET SAMI BELHARETH

> Copiez-collez ce prompt **dans son intégralité** dans Lovable après avoir connecté Supabase.

---

## 📋 PROMPT À COLLER DANS LOVABLE

```
Tu vas construire CABINET SAMI BELHARETH, une plateforme web PWA pour la gestion d'un cabinet de chirurgie orthopédique et traumatologique à Salammbô (Tunisie), pour le Dr Sami Belhareth.

═══════════════════════════════════════════════════════════
CONTEXTE MÉDICAL & MÉTIER
═══════════════════════════════════════════════════════════

Le cabinet traite des pathologies orthopédiques :
- Prothèses : PTH (hanche), PTG (genou), PUC
- Ligamentoplasties : LCA, LLE
- Hallux Valgus (percutané, MICA, DMMO, chevron)
- Tendons : suture Achille, coiffe rotateurs
- Mains : canal carpien, canal cubital, doigt à ressaut
- Rachis : lombosciatique, NCB, infiltrations
- Algodystrophie, fractures, plaies main, ongle incarné

Le cabinet travaille avec la CNAM tunisienne (Caisse Nationale d'Assurance Maladie).
Les devis et factures sont en dinars tunisiens (TND).
La langue de l'application est le FRANÇAIS.

═══════════════════════════════════════════════════════════
BASE DE DONNÉES (DÉJÀ EN PLACE — NE PAS RECRÉER)
═══════════════════════════════════════════════════════════

J'ai DÉJÀ créé le schéma Supabase complet avec 22 tables.
Tu dois UTILISER ces tables existantes, NE PAS en créer de nouvelles, NE PAS modifier le schéma.

Tables principales disponibles :
- profiles (utilisateurs : doctor/staff/patient)
- patients, medical_history
- appointments, consultations
- prescriptions + prescription_items
- surgeries, imaging, lab_results
- quotes + quote_lines, invoices, payments
- cnam_pec, cnam_acts_catalog (24 actes pré-remplis)
- rehab_programs + rehab_exercises + rehab_sessions
- message_threads + messages
- documents, audit_log

Row Level Security est activée. Trois fonctions helpers existent :
- public.is_doctor()
- public.is_staff()
- public.is_patient_of(patient_id)

Storage buckets disponibles :
- patient-imaging (privé)
- documents (privé)
- prescriptions (privé)
- quotes-invoices (privé)
- rehab-videos (privé)
- avatars (public)

═══════════════════════════════════════════════════════════
ARCHITECTURE — 3 ESPACES UTILISATEURS
═══════════════════════════════════════════════════════════

L'application a TROIS espaces distincts selon le rôle :

1. ESPACE MÉDECIN (rôle: doctor)
   - Sidebar gauche avec navigation
   - Tableau de bord : KPIs, agenda du jour, alertes
   - Liste patients avec recherche et filtres
   - Fiche patient 360° (synthèse, antécédents, consultations, imagerie, ordonnances)
   - Module consultation avec aperçu ordonnance en temps réel
   - Module bloc opératoire (chirurgies à venir)
   - Bibliothèque de protocoles par pathologie

2. ESPACE SECRÉTAIRE (rôle: staff)
   - Sidebar gauche (couleur violet/purple)
   - Tableau de bord : RDV du jour, salle d'attente live, tâches urgentes
   - Agenda multi-vues (jour/semaine/mois)
   - Workflow de prise de RDV en 4 étapes
   - Module caisse (encaissements espèces/carte/CNAM)
   - Gestion PEC CNAM avec catalogue d'actes
   - Devis et factures avec aperçu PDF

3. ESPACE PATIENT (rôle: patient)
   - PWA installable, mobile-first
   - Topbar + bottom nav mobile
   - Accueil avec humeur du jour
   - Prise de RDV en ligne avec créneaux disponibles
   - Mon dossier médical (consultable seulement)
   - Programme de rééducation avec vidéos d'exercices
   - Paiements en ligne (Konnect, Flouci, carte)
   - Messagerie sécurisée chiffrée avec le cabinet

═══════════════════════════════════════════════════════════
DESIGN SYSTEM — STYLE TOP MODERNE
═══════════════════════════════════════════════════════════

PALETTE PRINCIPALE :
- Médecin : Teal médical (#0F766E à #155E75) — gradients teal→cyan
- Secrétaire : Violet/Purple (#7E22CE à #581C87)
- Patient : Emerald (#047857 à #065F46)
- Backgrounds : Slate/Zinc avec dégradés doux et meshes
- Cards : blanc cassé avec glassmorphism (backdrop-blur)
- Accents : amber pour alertes, rose pour urgences

TYPOGRAPHIE :
- Corps : Inter (sans-serif moderne)
- Titres : Plus Jakarta Sans avec letter-spacing -0.02em
- Tailles : font-display pour titres importants, sizing généreux

COMPOSANTS UI :
- Boutons avec shadow colorées (shadow-teal-500/20, etc.)
- Cards avec hover lift (-translate-y-1 + shadow-xl)
- Animations fade-up à l'entrée des pages
- Icônes Lucide partout (stethoscope, syringe, bone, heart-pulse, etc.)
- Pills/badges arrondis avec couleurs sémantiques
- Tableaux modernes avec hover rows
- Sidebar collapsible avec items actifs en gradient

PRINCIPES :
- Mobile-first et responsive
- Animations fluides (Framer Motion ou CSS transitions)
- Glassmorphism pour les overlays
- Generous whitespace
- Confort de lecture (contraste WCAG AA)
- Loading states avec skeletons
- Toast notifications pour confirmations

═══════════════════════════════════════════════════════════
FONCTIONNALITÉS PRIORITAIRES (MVP)
═══════════════════════════════════════════════════════════

PRIORITÉ 1 — Authentification
- Login avec email/password (Supabase Auth)
- Inscription patient (formulaire simple)
- Création comptes doctor/staff (admin uniquement)
- Récupération mot de passe
- Le rôle est dans profiles.role, redirige vers le bon espace après login

PRIORITÉ 2 — Patients (espace médecin/secrétaire)
- Liste patients avec recherche full-text (utilise search_vector déjà en place)
- Création patient (formulaire avec CNAM, antécédents, allergies)
- Fiche patient 360°
- Modification, archivage (soft delete via deleted_at)

PRIORITÉ 3 — Consultation
- Démarrer consultation depuis fiche patient
- Formulaire avec EVA douleur, mesures (flexion, extension), observations
- Ajout médicaments depuis catalogue
- Génération PDF ordonnance avec en-tête cabinet
- Sauvegarde dans table consultations + prescriptions + prescription_items

PRIORITÉ 4 — Agenda
- Calendrier vue jour/semaine/mois (FullCalendar ou react-big-calendar)
- Création RDV avec patient existant ou nouveau
- Types : consultation, contrôle, pré-op, urgence
- Drag-and-drop pour déplacer
- Confirmation/annulation

PRIORITÉ 5 — Devis & CNAM
- Création devis depuis pathologie + catalogue actes CNAM
- Lignes de devis avec calcul automatique total
- Génération PDF avec barème
- Workflow PEC CNAM : pending → submitted → approved
- Statuts visuels

PRIORITÉ 6 — Portail patient
- Connexion patient via email/OTP
- Voir ses prochains RDV
- Prendre RDV en ligne avec créneaux libres
- Télécharger ses ordonnances PDF
- Voir l'historique consultations
- Messagerie avec le cabinet

═══════════════════════════════════════════════════════════
RÈGLES TECHNIQUES STRICTES
═══════════════════════════════════════════════════════════

1. Utilise EXCLUSIVEMENT les tables existantes du schéma Supabase
2. Respecte la RLS — les requêtes doivent fonctionner avec auth.uid()
3. Tous les textes en FRANÇAIS (pas d'anglais visible utilisateur)
4. Dates au format français (date-fns avec locale fr)
5. Devises en TND (Dinars Tunisiens) avec 3 décimales si nécessaire
6. Téléphones tunisiens : format "XX XXX XXX" (8 chiffres)
7. Numéros CNAM : champ libre 6-12 caractères alphanumériques
8. Mode PWA installable (manifest.json + service worker)
9. Responsive mobile parfait pour l'espace patient
10. Validation Zod sur tous les formulaires
11. Toast notifications pour feedback utilisateur
12. Loading states partout
13. Accessibilité WCAG AA (contraste, labels, navigation clavier)

═══════════════════════════════════════════════════════════
PAGE D'ACCUEIL (LANDING) — Avant connexion
═══════════════════════════════════════════════════════════

- Hero impactant avec gradient teal
- Titre : "Votre cabinet, réinventé."
- Sous-titre : "Une plateforme unifiée pour vos consultations, vos chirurgies orthopédiques, votre secrétariat et vos patients. Conforme CNAM, pensée par et pour les orthopédistes."
- 3 cartes pour les 3 espaces (Médecin / Secrétaire / Patient)
- Section features (8 fonctionnalités avec icônes)
- Trust badges (CNAM ✓, AES-256 ✓, PWA offline ✓)
- Footer avec coordonnées (Salammbô, Tunisie)

═══════════════════════════════════════════════════════════
COMMENCE PAR
═══════════════════════════════════════════════════════════

1. Configure les variables d'environnement Supabase (déjà connecté via OAuth)
2. Crée la structure de base : Next.js + Tailwind + shadcn/ui
3. Implémente la page d'accueil (landing)
4. Implémente le système d'authentification avec routing par rôle
5. Implémente l'espace médecin en commençant par dashboard + liste patients
6. Ensuite l'espace secrétaire (agenda + caisse)
7. Enfin l'espace patient (accueil + RDV + dossier)

Ne crée PAS de tables — utilise les 22 tables existantes.
Ne modifie PAS le schéma — il est conforme CNAM et tu n'as pas le contexte médical.
Demande-moi si quelque chose n'est pas clair dans le schéma existant.

GO ! Commence par la page d'accueil et l'authentification.
```

---

## 💡 Conseils pour utiliser ce prompt dans Lovable

### Avant de coller
1. ✅ Vérifie que **Supabase est connecté** dans Lovable (icône Supabase verte)
2. ✅ Vérifie que **les 22 tables apparaissent** dans Lovable (côté Supabase)
3. ✅ Sois dans un **nouveau projet Lovable** vide (pas de code existant)

### Après le premier rendu
Une fois que Lovable a généré le projet, tu peux demander des ajustements ciblés :

- **"Améliore le design de la fiche patient avec un layout 3 colonnes"**
- **"Ajoute une vue calendrier semaine pour l'agenda"**
- **"Crée un wizard 4 étapes pour la prise de RDV"**
- **"Ajoute la génération PDF des ordonnances avec pdfmake"**
- **"Implémente la recherche full-text sur patients en utilisant search_vector"**

### Prompts itératifs utiles
```
Améliore l'espace médecin :
- Ajoute le dashboard avec 4 KPIs (consultations jour, chirurgies semaine, PEC en attente, total patients mois)
- Liste des RDV du jour avec statuts colorés
- Carte "Chirurgies à venir" en gradient teal
- Carte "Alertes" avec problèmes urgents
```

```
Pour la consultation :
- Slider EVA douleur 0-10 avec valeur affichée
- Sliders flexion/extension en degrés
- Textarea pour observations avec dictée vocale (Web Speech API)
- Aperçu ordonnance live à droite (preview PDF)
- Bouton "Suggestion IA" qui propose médicaments selon la pathologie
```

```
Pour l'espace patient :
- Mode PWA installable (next-pwa)
- Bottom nav mobile avec 5 onglets
- Vue accueil avec humeur du jour (3 emojis)
- Programme rééducation avec vidéos en aspect ratio 16:9
- Messagerie style WhatsApp avec bulles
```

## 🎨 Inspiration design

Si Lovable demande des références visuelles, mentionne :
- Linear (sidebar, micro-interactions)
- Notion (typo, cards)
- Doctolib (workflow RDV)
- Apple Health (espace patient)
- Stripe Dashboard (statistiques, tableaux)

## 🔒 Rappels sécurité

- N'autorise JAMAIS Lovable à push des clés Supabase sur GitHub
- Vérifie que les clés sont dans le **secret manager Lovable**, pas dans le code
- Avant de déployer en production : audit des RLS policies
- Active la 2FA sur Supabase et GitHub
