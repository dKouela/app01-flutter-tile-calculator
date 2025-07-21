# 🚀 Guide de déploiement - App Devis Carrelage

## 📋 Prérequis

- Node.js 18+
- Flutter SDK 3.8.1+
- Compte Supabase
- Compte Cloudflare (optionnel)
- CLI Supabase et Wrangler

## 🗄️ 1. Configuration Supabase

### Installation CLI
```bash
npm install -g supabase
```

### Initialisation locale
```bash
# Démarrer services locaux
supabase start

# Créer les tables (exécuter le schema SQL)
supabase db reset

# Déployer Edge Function
supabase functions deploy createQuote
```

### Production
```bash
# Créer projet sur supabase.com
# Lier le projet local
supabase link --project-ref your-project-ref

# Déployer schema et functions
supabase db push
supabase functions deploy createQuote

# Configurer secrets
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

## ☁️ 2. Cloudflare Worker (Optionnel)

### Installation
```bash
npm install -g wrangler
cd workers/supabase-proxy
npm install
```

### Configuration
```bash
# Authentification
wrangler auth login

# Créer KV Namespaces
wrangler kv:namespace create "CACHE" --env production
wrangler kv:namespace create "RATE_LIMIT" --env production

# Ajouter les IDs dans wrangler.toml

# Définir secrets
wrangler secret put SUPABASE_ANON_KEY --env production
```

### Déploiement
```bash
# Test local
wrangler dev --env development

# Déploiement production
wrangler deploy --env production
```

## 📱 3. Application Flutter

### Configuration environnement
```bash
# Créer fichier .env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
BASE_URL=https://your-worker.workers.dev  # Si Worker activé
```

### Installation dépendances
```bash
flutter pub get
```

### Build et déploiement

#### Android
```bash
# APK Release
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release
```

#### iOS
```bash
# Build iOS
flutter build ios --release

# Archive avec Xcode pour App Store
```

#### Web
```bash
# Build web
flutter build web --release

# Déployer sur Firebase Hosting, Netlify, ou Cloudflare Pages
```

## 🧪 4. Tests et validation

### Tests unitaires
```bash
# Générer mocks
dart run build_runner build

# Lancer tests
flutter test

# Couverture
flutter test --coverage
```

### Tests d'intégration
```bash
# Edge Function locale
curl -X POST 'http://localhost:54321/functions/v1/createQuote' \
  -H 'Authorization: Bearer your_anon_key' \
  -H 'Content-Type: application/json' \
  -d '{"userId":"test","rooms":[{"nom":"Test","superficie":10,"designationId":1}]}'

# Worker Cloudflare
curl -X GET 'https://your-worker.workers.dev/rest/v1/designations' \
  -H 'apikey: your_anon_key'
```

## 📊 5. Monitoring

### Supabase
- Dashboard: Requêtes, erreurs, performances
- Logs Edge Functions: `supabase functions logs createQuote`

### Cloudflare
- Analytics Worker
- Logs: `wrangler tail --env production`

### Flutter
- Crash reporting (Sentry, Firebase Crashlytics)
- Analytics (Firebase Analytics, Mixpanel)

## 🔐 6. Sécurité

### Supabase RLS
- Politiques Row Level Security activées
- Utilisateurs isolés par `auth.uid()`

### Variables d'environnement
- Secrets Supabase sécurisés
- Clés API en variables d'environnement
- Pas de secrets en dur dans le code

### Rate Limiting
- Cloudflare Worker: 10 req/min par IP
- Supabase: Limites par défaut

## 🚀 7. CI/CD (Optionnel)

### GitHub Actions
```yaml
name: Deploy App
on:
  push:
    branches: [main]

jobs:
  deploy-supabase:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: supabase db push --linked
      - run: supabase functions deploy

  deploy-worker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: wrangler deploy --env production

  build-flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build web --release
```

## 📋 8. Checklist de déploiement

### Avant déploiement
- [ ] Tests unitaires passent
- [ ] Variables d'environnement configurées
- [ ] Schema Supabase déployé
- [ ] Edge Functions déployées
- [ ] Worker Cloudflare déployé (si activé)

### Après déploiement
- [ ] App fonctionne en production
- [ ] Création devis opérationnelle
- [ ] Génération PDF fonctionne
- [ ] Rate limiting actif
- [ ] Cache designations opérationnel
- [ ] Monitoring configuré

## 🆘 9. Dépannage

### Erreurs communes
- **Supabase connection failed**: Vérifier URL et clés API
- **Edge Function timeout**: Optimiser requêtes SQL
- **PDF generation error**: Vérifier permissions assets
- **Worker rate limit**: Ajuster limites ou IP whitelist

### Logs utiles
```bash
# Supabase
supabase functions logs createQuote --follow

# Cloudflare
wrangler tail --env production

# Flutter
flutter logs
```

---

🎉 **Félicitations ! Votre app de devis carrelage est déployée !**