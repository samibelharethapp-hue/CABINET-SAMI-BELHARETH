# Roadmap — CABINET SAMI BELHARETH

## Phase 0 — Validation visuelle (✅ TERMINÉE)

- [x] Analyse des ~200 documents existants du cabinet
- [x] Identification des 3 espaces (médecin, secrétaire, patient)
- [x] Architecture technique cadrée
- [x] Maquettes interactives HTML/Tailwind
- [x] Document d'architecture
- [x] Roadmap MVP

**Livrable** : 4 fichiers HTML interactifs dans `mockups/`

---

## Phase 1 — MVP (≈ 8-10 semaines)

### Sprint 1-2 (2 semaines) — Fondations
**Objectif** : projet démarré, auth fonctionnelle, dossier patient minimal

- [ ] Setup repo Git + Next.js 14 + TypeScript + Tailwind + shadcn
- [ ] Configuration Supabase (projet, DB, Auth, Storage)
- [ ] Modèle de données complet (voir `data-model.md`)
- [ ] Migrations SQL + RLS policies
- [ ] Pages auth : login, inscription patient, MFA médecin
- [ ] Layout 3 espaces avec sidebar + topbar
- [ ] CRUD patient basique (création, lecture, modification)

**Livrable** : authentification fonctionnelle + création patient en base

### Sprint 3-4 (2 semaines) — Consultation & Ordonnance
**Objectif** : le Dr peut faire une consultation et générer une ordonnance

- [ ] Fiche patient 360° (synthèse, antécédents, allergies, traitements)
- [ ] Démarrage consultation depuis fiche
- [ ] Formulaire consultation (motif, examen, EVA, observations)
- [ ] Catalogue de médicaments tunisien (base)
- [ ] Génération PDF ordonnance avec en-tête cabinet
- [ ] Templates ordonnance par pathologie (import depuis `.doc` existants)
- [ ] Historique consultations + ordonnances dans la fiche

**Livrable** : une consultation complète peut être réalisée et l'ordonnance imprimée

### Sprint 5-6 (2 semaines) — Agenda & RDV
**Objectif** : agenda fonctionnel, RDV pris en ligne par patients

- [ ] Vue agenda jour / semaine / mois (médecin + secrétaire)
- [ ] CRUD RDV (création, déplacement drag-and-drop, annulation)
- [ ] Types de RDV (consultation, contrôle, urgence, pré-op)
- [ ] Prise RDV par patient (portail patient)
- [ ] Salle d'attente live (secrétaire)
- [ ] Rappels SMS/WhatsApp 24h avant (via Infobip ou Twilio)
- [ ] Confirmations automatiques

**Livrable** : agenda opérationnel, patients peuvent prendre RDV en ligne

### Sprint 7-8 (2 semaines) — Devis, Factures & CNAM
**Objectif** : facturation et CNAM automatisés

- [ ] Catalogue actes orthopédiques avec cotation CNAM
- [ ] Génération devis chirurgicaux (PTH, PTG, LCA, Hallux V., etc.)
- [ ] Templates devis depuis `.doc` existants
- [ ] Formulaires PEC CNAM pré-remplis (décret 11/06/2007)
- [ ] Workflow validation PEC (à traiter → en cours → validé)
- [ ] Module caisse (encaissements, modes paiement)
- [ ] Factures + reçus

**Livrable** : devis et PEC CNAM générés en 1 clic

### Sprint 9-10 (2 semaines) — Imagerie, Portail patient & PWA
**Objectif** : MVP livrable

- [ ] Upload + visualisation imagerie (JPG/PNG/PDF d'abord, DICOM en V2)
- [ ] Portail patient : accueil, RDV, dossier, ordonnances
- [ ] Téléchargement documents par patient
- [ ] Messagerie chiffrée patient ↔ cabinet
- [ ] Mode hors-ligne (PWA + service worker)
- [ ] Sync local ↔ cloud (PowerSync)
- [ ] Tests E2E des parcours critiques
- [ ] Déploiement Vercel + Supabase production

**Livrable** : 🚀 MVP en production, utilisable au cabinet

---

## Phase 2 — Spécialisation orthopédie (≈ 6-8 semaines)

### Protocoles par pathologie
- [ ] Achille (rupture, tendinopathie)
- [ ] Hallux Valgus (percutané, MICA, DMMO)
- [ ] LCA (DT4, KJ)
- [ ] PTG / PTH
- [ ] Algodystrophie (SDRC)
- [ ] Lombosciatique / NCB
- [ ] Canal carpien
- [ ] Coiffe des rotateurs / Latarjet

Pour chaque protocole :
- Ordonnance type
- Demande examens
- Bilan pré-op
- Hospitalisation
- Suites post-op (pansement, antalgiques)
- Rééducation par phases
- Sortie

### Bloc opératoire
- [ ] Planning bloc
- [ ] Checklist pré-op
- [ ] Compte rendu opératoire (CRO) avec templates
- [ ] Gestion matériel/implants par chirurgie

### Rééducation guidée patient
- [ ] Bibliothèque exercices vidéo
- [ ] Programmes par chirurgie (PTG, LCA, Achille...)
- [ ] Suivi progression (cases checkées, EVA quotidienne)
- [ ] Communication kiné ↔ médecin ↔ patient

---

## Phase 3 — Intelligence & Optimisation (≈ 4-6 semaines)

### IA d'aide à la décision
- [ ] Suggestions protocole selon pathologie + profil patient
- [ ] Détection allergies/interactions médicamenteuses
- [ ] Pré-remplissage automatique (CR, PEC) depuis dossier
- [ ] Résumé automatique de consultation

### DICOM professionnel
- [ ] Viewer Cornerstone.js (multi-plans, MPR)
- [ ] Mesures et annotations
- [ ] Comparaison séries (avant/après chirurgie)

### Analytics
- [ ] Dashboard activité (consultations, chirurgies, revenus)
- [ ] Statistiques par pathologie
- [ ] Taux de no-show, conversion devis → chirurgie
- [ ] Reporting CNAM trimestriel

---

## Phase 4 — Extension (V2+)

- Multi-praticiens (cabinet groupé)
- Téléconsultation vidéo
- App mobile native si nécessaire
- Marketplace : kinés, radio, pharmacies partenaires
- Export interopérable (HL7 / FHIR)
- API publique pour confrères

---

## Hypothèses & risques

| Hypothèse | Risque | Mitigation |
|---|---|---|
| Connexion internet stable au cabinet | Coupure réseau | Mode offline PWA complet |
| Patients ont smartphones | Patients âgés peu numériques | Secrétaire prend RDV pour eux |
| CNAM API disponible | Pas d'API officielle | PDF + soumission manuelle |
| Dr accepte de migrer | Résistance au changement | Migration progressive, conserver `.doc` en parallèle pendant 3 mois |
| Sécurité jugée suffisante | Audit RGPD requis | Audit indépendant avant V1 |

---

## Métriques de succès

| Métrique | Cible V1 | Cible V2 |
|---|---|---|
| Temps de consultation | -20% | -35% |
| Génération ordonnance | < 30s | < 10s |
| No-show RDV | -40% (rappels auto) | -60% |
| PEC CNAM acceptées du 1er coup | > 80% | > 95% |
| Satisfaction patient (NPS) | > 50 | > 70 |
| Adoption portail patient | 30% des patients | 70% |
