# 🔗 Guide de connexion Lovable ↔ Supabase

## 🎯 Objectif
Permettre à Lovable d'utiliser votre projet Supabase **`exalunvbrpaxlcqjayjk`** **sans jamais exposer vos clés** dans le code ou sur GitHub.

## ✅ Prérequis
- [x] Compte Lovable créé (lovable.dev)
- [x] Projet Supabase créé : `exalunvbrpaxlcqjayjk`
- [x] Migration SQL appliquée (22 tables visibles dans Supabase Table Editor)
- [x] Clés Supabase régénérées (sécurité)

---

## 📋 Étapes (5 minutes)

### Étape 1 — Ouvrir Lovable

1. Allez sur https://lovable.dev
2. Connectez-vous (avec GitHub `samibelharethapp-hue` ou Google)
3. Créez un nouveau projet :
   - Bouton **`+ New Project`**
   - Nom : **`CABINET SAMI BELHARETH`**
   - Description : `Cabinet orthopédie Salammbô — 3 espaces médecin/secrétaire/patient`

### Étape 2 — Initier la connexion Supabase dans Lovable

Dans votre projet Lovable :

1. Regardez en haut à droite, vous devriez voir une icône **Supabase** (vert)
2. Sinon, ouvrez le chat et tapez :
   ```
   Connect to Supabase
   ```
3. Lovable vous propose **`Connect Supabase`** → cliquez

### Étape 3 — Autoriser via OAuth

Une fenêtre popup s'ouvre :

1. **Authorize Lovable** sur Supabase → cliquez
2. Si demandé, connectez-vous à Supabase avec votre compte
3. ✅ Lovable a maintenant accès à votre liste de projets Supabase

### Étape 4 — Sélectionner votre projet

Dans Lovable, sélectionnez :
- Organisation : (la vôtre)
- Projet : **`exalunvbrpaxlcqjayjk`**

Confirmez. Lovable récupère **automatiquement** les clés `anon` et `service_role` et les stocke dans son **secret manager chiffré**.

### Étape 5 — Vérifier que tout est connecté

Dans Lovable, tapez dans le chat :
```
Liste les tables de la base de données Supabase
```

Lovable devrait répondre avec la liste des 22 tables (patients, consultations, appointments, etc.).

✅ **Si tu vois les 22 tables, la connexion est OK !**

---

## ⚠️ Sécurité — Ce que vous DEVEZ vérifier

### Les clés ne doivent PAS être dans le code
Demandez à Lovable :
```
Montre-moi le fichier .env ou les variables d'environnement utilisées
```

Vous devriez voir :
- `VITE_SUPABASE_URL=https://exalunvbrpaxlcqjayjk.supabase.co` ✅ (URL publique, OK)
- `VITE_SUPABASE_ANON_KEY=...` ✅ (publishable, OK)
- ⛔ **JAMAIS** de `SUPABASE_SERVICE_ROLE_KEY` côté frontend !

Si vous voyez `SUPABASE_SERVICE_ROLE_KEY` exposée côté client, dites à Lovable :
```
La service_role key NE DOIT PAS être exposée côté client.
Utilise uniquement la anon key dans le frontend.
La service_role key doit être utilisée uniquement dans les Edge Functions Supabase ou backend serveur.
```

### Vérifier que GitHub ne contient pas les clés

Quand vous synchronisez Lovable avec GitHub :
1. Vérifiez que `.env` est dans `.gitignore`
2. Vérifiez sur GitHub que vous ne voyez **AUCUN** fichier avec `ghp_`, `sb_secret_`, ou des longues chaînes ressemblant à des clés
3. Si vous voyez une clé exposée → **régénérez immédiatement** sur Supabase

---

## 🚀 Étape suivante — Coller le super-prompt

Une fois la connexion Supabase OK, ouvrez le fichier :
```
lovable/super-prompt.md
```

Copiez le bloc entre les ``` du PROMPT À COLLER DANS LOVABLE et collez-le dans le chat Lovable.

Lovable va générer l'application complète en quelques minutes.

---

## 🔧 Dépannage

### "Lovable ne voit pas mes tables"
- Vérifiez que la migration SQL a bien été exécutée dans Supabase (Table Editor doit afficher les 22 tables)
- Déconnectez-reconnectez Supabase dans Lovable
- Vérifiez que vous êtes sur le bon projet `exalunvbrpaxlcqjayjk`

### "Lovable veut créer des tables"
- Dites-lui clairement : `"NE CRÉE PAS de nouvelles tables. Utilise les 22 tables existantes du schéma actuel."`
- Re-collez la partie "BASE DE DONNÉES" du super-prompt

### "Erreurs RLS dans Lovable"
- Les RLS policies nécessitent que `auth.uid()` soit défini
- Pour tester : créez un compte test avec rôle `doctor` dans la table `profiles`
- Demandez à Lovable : `"Crée un système de seed pour avoir un compte doctor de test"`

### "Le projet Lovable est trop lent"
- Divisez la génération : commencez par la landing + auth, puis ajoutez les espaces un par un
- Utilisez les prompts itératifs (voir `super-prompt.md` section "Prompts itératifs utiles")

---

## 📊 Architecture finale (après connexion)

```
┌──────────────────────────────────────────────────────────────┐
│  Lovable                                                      │
│  - Génère React + TypeScript + Tailwind + shadcn/ui          │
│  - Connecté à Supabase via OAuth (clés en secret manager)    │
│  - Push vers GitHub (samibelharethapp-hue/CABINET-...)       │
└──────────────────────┬───────────────────────────────────────┘
                       │ HTTPS + JWT
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  Supabase (exalunvbrpaxlcqjayjk)                              │
│  - PostgreSQL avec 22 tables médicales                        │
│  - RLS activée (doctor/staff/patient)                         │
│  - Storage (6 buckets : imaging, docs, prescriptions, etc.)   │
│  - Auth (email/password + OTP)                                │
│  - Edge Functions pour génération PDF                         │
└──────────────────────────────────────────────────────────────┘
```

## 🎯 Vous êtes prêt !

Quand tout est connecté, dites-moi **"Lovable connecté à Supabase"** et je vous prépare des prompts itératifs spécifiques pour chaque module.
