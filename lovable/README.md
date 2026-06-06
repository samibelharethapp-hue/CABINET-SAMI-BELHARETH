# 🎨 Lovable — Génération de l'application

## 📁 Contenu

```
lovable/
├── README.md            # Ce fichier
├── connection-guide.md  # Comment connecter Lovable à Supabase
├── super-prompt.md      # LE prompt à coller dans Lovable pour générer l'app
└── prompts-iteratifs.md # Prompts pour améliorer module par module (à venir)
```

## 🎯 Ordre de lecture

1. **Étape 1** : Appliquer la migration SQL → voir `../supabase/README.md`
2. **Étape 2** : Connecter Lovable à Supabase → `connection-guide.md`
3. **Étape 3** : Coller le super-prompt → `super-prompt.md`
4. **Étape 4** : Itérer avec des prompts ciblés → `prompts-iteratifs.md`

## 🏥 Pourquoi Lovable + Supabase pour ce projet ?

| Avantage | Détail |
|---|---|
| ⚡ Vitesse | MVP en quelques heures vs semaines |
| 🎨 Design | Génère des UI modernes (shadcn/ui, Tailwind) |
| 🔒 Sécurité | Clés Supabase dans secret manager Lovable |
| 🔄 Sync | Auto-push vers GitHub |
| 💰 Coût | Bien moins cher qu'un développeur freelance |
| 📦 Stack | React + TypeScript + Supabase = stack moderne pro |

## ⚖️ Limites à connaître

| Limite | Workaround |
|---|---|
| Génère du code "comme un débutant senior" | Itérer avec prompts précis |
| Peut créer des tables si vous ne précisez pas | Insister : "utilise tables existantes" |
| Pas natif pour DICOM | Intégrer Cornerstone.js manuellement plus tard |
| Pas de tests auto | Ajouter tests Vitest après MVP |

## 🛠️ Stack technique générée par Lovable (typique)

- **Frontend** : React + Vite + TypeScript
- **UI** : Tailwind CSS + shadcn/ui + Radix UI
- **Routing** : React Router
- **State** : Zustand ou React Query (TanStack)
- **Forms** : React Hook Form + Zod
- **Backend** : Supabase (DB + Auth + Storage)
- **Hosting** : Vercel ou Lovable Cloud
