# 🧱 Tile Quote App - Flutter

This application allows tile contractors to generate quotes quickly by entering:
- their professional information once,
- rooms to be tiled (name, area, tile type).

Required quantities are automatically calculated based on tile characteristics (m²/box).

---

## 🔧 Technologies Used

- **Flutter + Dart** (cross-platform mobile frontend)
- **Supabase** (PostgreSQL database & authentication)
- **Supabase Edge Functions** (backend business logic)
- **Package `pdf`** (PDF quote generation)
- **Cloudflare Workers/Pages** (optional - deployment)
- **Claude.ai** (development assistant)

---

## 🧩 Main Features

1. **One-time contractor registration**
   - Last name, first name, company, phone
   - Secure storage with Supabase authentication

2. **Tile catalog management**
   - Tile types with area per box (e.g., 1.92 m²)
   - Complete CRUD via Flutter interface

3. **Quote creation**
   - Add multiple rooms (name, area)
   - Select tile type per room
   - Automatic calculation: `boxes = ceil(area / areaPerBox)`

4. **Storage and persistence**
   - Save quotes and rooms in Supabase PostgreSQL
   - Real-time synchronization

5. **PDF export**
   - Generate PDF quotes directly from the app
   - Local download via `pdf` package

---

## 🗃 Flutter Project Structure

```
app01/
├── lib/
│   ├── main.dart                    # Application entry point
│   ├── models/                      # Data models
│   │   ├── user.dart               # User model (contractor)
│   │   ├── designation.dart        # Tile type model
│   │   ├── quote.dart              # Quote model
│   │   └── room.dart               # Room to tile model
│   ├── screens/                     # Application screens
│   │   ├── auth/                   # Authentication
│   │   │   ├── login_screen.dart   # Login
│   │   │   └── register_screen.dart # Registration
│   │   ├── home_screen.dart        # Home with quote list
│   │   ├── profile_screen.dart     # Contractor profile
│   │   ├── designations_screen.dart # Catalog management
│   │   ├── quote_form_screen.dart  # Quote creation
│   │   └── quote_detail_screen.dart # Quote detail + PDF
│   ├── widgets/                     # Reusable components
│   │   ├── common/                 # Generic widgets
│   │   ├── quote_card.dart         # Quote card
│   │   ├── room_card.dart          # Room card
│   │   └── designation_selector.dart # Designation selector
│   ├── services/                    # Business services
│   │   ├── supabase_service.dart   # Supabase client
│   │   ├── auth_service.dart       # Authentication
│   │   ├── quote_service.dart      # Quote CRUD
│   │   ├── designation_service.dart # Designations CRUD
│   │   └── pdf_service.dart        # PDF generation
│   └── utils/                       # Utilities
│       ├── constants.dart          # App constants
│       ├── validators.dart         # Form validators
│       ├── extensions.dart         # Dart extensions
│       └── helpers.dart            # Helper functions
├── supabase/                        # Supabase backend
│   ├── functions/                  # Edge Functions
│   │   └── createQuote/            # Quote creation function
│   │       └── index.ts            # TypeScript business logic
│   └── migrations/                 # SQL scripts
├── workers/                         # Cloudflare Workers
│   └── supabase-proxy/             # Proxy with caching & rate limiting
├── assets/                          # Static resources
│   ├── images/                     # Images
│   └── fonts/                      # Custom fonts
├── test/                           # Unit tests
├── android/                        # Android native code
├── ios/                           # iOS native code
├── web/                           # Web configuration
├── .env.example                    # Environment variables
├── supabase_schema.sql            # PostgreSQL schema
├── pubspec.yaml                   # Dependencies configuration
└── README.md                      # Documentation
```

---

## 🚀 Installation and Setup

### Prerequisites
- Flutter SDK 3.8.1+
- Dart SDK
- Supabase account
- Firebase CLI
- Android Studio / VS Code

### Installation
1. Clone the repository
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Configure Supabase:
   ```bash
   # Install Supabase CLI
   npm install -g supabase
   
   # Initialize local project
   supabase init
   
   # Start local services
   supabase start
   
   # Create tables (execute SQL schema)
   supabase db reset
   
   # Deploy Edge Functions
   supabase functions deploy createQuote
   ```
   
4. Production configuration:
   - Create a project on [supabase.com](https://supabase.com)
   - Link local project: `supabase link --project-ref your-project-ref`
   - Deploy: `supabase db push` and `supabase functions deploy`
   - Copy variables to `.env`

### Launch
```bash
flutter run
```

---

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Web
- ⚠️ Windows (in development)
- ⚠️ macOS (in development)

---

## 🔥 Supabase Configuration

### Services Used
- **Authentication**: Secure user login
- **PostgreSQL**: Relational database
- **Edge Functions**: TypeScript backend business logic
- **Row Level Security**: Row-level security

### Database Schema
```sql
-- Main tables
users (uid, nom, prenom, entreprise, telephone)
designations (id, nom, surface_par_carton)
quotes (id, user_id, total_cartons, created_at)
rooms (id, quote_id, nom, superficie, designation_id, cartons)
```

### Available Edge Functions
- **`createQuote`**: Quote creation with automatic box calculation
  - Input: `{ userId, rooms: [{ nom, superficie, designationId }] }`
  - Output: Complete quote with total_cartons
  - Transaction management and data validation

### Environment Variables
Create a `.env` file at the root:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

---

## 🧪 Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter drive --target=test_driver/app.dart
```

---

## 📦 Build and Deployment

### Supabase Deployment
```bash
# Database and Edge Functions
supabase db push
supabase functions deploy createQuote

# Production environment variables
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_key
```

### Flutter Build
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Useful Commands
```bash
# Local Supabase tests
supabase start
supabase db reset
supabase functions serve createQuote

# Edge Function logs
supabase functions logs createQuote

# Test Edge Function
curl -X POST 'http://localhost:54321/functions/v1/createQuote' \
  -H 'Authorization: Bearer your_anon_key' \
  -H 'Content-Type: application/json' \
  -d '{"userId":"uuid","rooms":[{"nom":"Test","superficie":10,"designationId":1}]}'
```

---

## ☁️ Cloudflare Worker (Optional)

The project includes a Cloudflare Worker that acts as a proxy for Supabase with:
- **Caching TTL 60s** on GET `/designations`
- **Rate limiting 10 req/min** on POST `/createQuote` per IP
- **CORS handling** and error management

### Deployment
```bash
cd workers/supabase-proxy
npm install
wrangler auth login
wrangler deploy --env production
```

---

## 🎨 Design & UI

- **Material Design 3**
- **Adaptive theme** (light/dark)
- **Responsive interface**
- **Accessibility** standards compliant

---

## 📋 TODO / Roadmap

### Phase 1 - Core MVP
- [x] Supabase configuration + authentication
- [x] Dart models (User, Designation, Quote, Room)
- [x] Supabase services (CRUD operations)
- [x] Authentication screens (login/register)
- [x] Contractor profile screen

### Phase 2 - Main Features
- [x] Designation catalog management (CRUD)
- [x] Quote creation with room addition
- [x] Automatic box calculation
- [x] Quote list and detail
- [x] PDF quote generation

### Phase 3 - Improvements
- [ ] Edge Functions for complex calculations
- [ ] Offline mode with synchronization
- [ ] Excel/CSV export
- [ ] Multi-client management
- [ ] History and statistics
- [ ] Dark theme
- [ ] Push notifications

---

## 🤝 Contributing

1. Fork the project
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is under MIT license. See the `LICENSE` file for more details.

---

## 📞 Contact

**Developer**: [Your name]  
**Email**: [your.email@example.com]  
**Company**: [Your company name]

---

## 🙏 Acknowledgments

- **Flutter Team** for the framework
- **Supabase** for the modern backend stack
- **Claude.ai** for development assistance
- **r/FlutterDev** community for feedback