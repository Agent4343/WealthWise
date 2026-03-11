# WealthWise

**The Financial Education App Canada Never Had**

A Canadian iOS application that delivers structured financial education paired with an AI-powered weekly guidance engine — giving users personalized, actionable financial direction every Monday morning.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| iOS App | SwiftUI (iOS 16+), StoreKit 2 |
| Backend | Node.js + Express (Railway) |
| Database | Supabase (PostgreSQL + Auth) |
| AI Engine | Anthropic Claude API |
| Email | Resend |
| Push Notifications | Apple Push Notification Service (APNs) |

---

## Repository Structure

```
WealthWise/
├── backend/                    # Node.js API server (Railway)
│   ├── src/
│   │   ├── app.js              # Express app configuration
│   │   ├── config/
│   │   │   └── supabase.js     # Supabase client
│   │   ├── middleware/
│   │   │   └── auth.js         # JWT verification, tier enforcement
│   │   ├── routes/
│   │   │   ├── auth.js         # POST /auth/sync
│   │   │   ├── profile.js      # GET/PUT /profile
│   │   │   ├── briefs.js       # GET /briefs, GET /briefs/:id
│   │   │   └── webhooks.js     # POST /webhooks/appstore (StoreKit 2)
│   │   ├── services/
│   │   │   ├── aiEngine.js     # Claude API weekly brief generation
│   │   │   ├── emailService.js # Resend HTML email delivery
│   │   │   ├── pushNotifications.js  # APNs HTTP/2 push
│   │   │   └── apnsJwt.js      # APNs JWT token generation
│   │   └── jobs/
│   │       └── weeklyBrief.js  # Sunday 23:00 EST cron job
│   ├── db/
│   │   └── schema.sql          # Supabase database schema
│   ├── tests/
│   │   ├── api.test.js         # API endpoint tests
│   │   └── services.test.js    # Service unit tests
│   ├── server.js               # Entry point
│   ├── package.json
│   └── .env.example
│
└── ios/                        # SwiftUI iOS App
    ├── WealthWise.xcodeproj/
    └── WealthWise/
        ├── App/
        │   └── WealthWiseApp.swift      # App entry + Main tab navigation
        ├── Models/
        │   ├── User.swift               # AppUser, FinancialProfile, enums
        │   ├── WeeklyBrief.swift        # Brief models
        │   ├── Chapter.swift            # School content models
        │   └── Subscription.swift       # StoreKit 2 product models
        ├── Networking/
        │   ├── APIService.swift         # REST API client
        │   ├── AuthManager.swift        # Keychain + session management
        │   └── Config.swift             # Environment configuration
        ├── Auth/
        │   ├── AuthViewModel.swift
        │   ├── SignInView.swift
        │   └── OnboardingView.swift
        ├── School/
        │   ├── SchoolViewModel.swift
        │   └── SchoolViews.swift        # Chapter list, Lesson, Quiz views
        ├── Dashboard/
        │   ├── DashboardViewModel.swift
        │   ├── DashboardView.swift
        │   └── ProfileSetupView.swift
        ├── Planner/
        │   ├── PlannerViewModel.swift
        │   └── PlannerViews.swift       # 5 financial calculators
        ├── Briefs/
        │   ├── BriefsViewModel.swift
        │   └── BriefsViews.swift
        ├── Paywall/
        │   ├── SubscriptionViewModel.swift
        │   └── PaywallView.swift
        ├── Settings/
        │   └── SettingsView.swift
        ├── Utilities/
        │   ├── CurrencyFormatter.swift
        │   ├── CompoundInterestCalculator.swift
        │   └── TaxCalculator.swift
        └── Resources/
            └── Data/
                └── chapters.json        # Bundled school content
```

---

## Backend Setup

### Prerequisites
- Node.js 18+
- Supabase project
- Anthropic API key
- Resend account (email)
- Apple Developer account (APNs)

### Installation

```bash
cd backend
npm install
cp .env.example .env
# Fill in your environment variables in .env
```

### Environment Variables

See `backend/.env.example` for all required variables.

### Running Locally

```bash
cd backend
npm run dev   # Development with nodemon
npm start     # Production
```

### Running Tests

```bash
cd backend
npm test
```

### Database Setup

1. Open your Supabase project dashboard
2. Navigate to the SQL editor
3. Run the contents of `backend/db/schema.sql`

This creates:
- `app_users` — mirrors Supabase auth with subscription metadata
- `financial_profiles` — user financial data for AI personalization
- `user_reports` — generated Weekly Brief reports
- `calculator_saves` — saved calculator results (Basic/Premium)

### API Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `GET /health` | GET | None | Health check |
| `POST /auth/sync` | POST | Bearer | Sync auth user to app_users |
| `GET /profile` | GET | Bearer + Basic | Get financial profile |
| `PUT /profile` | PUT | Bearer + Basic | Create/update profile |
| `GET /briefs` | GET | Bearer + Premium | List Weekly Briefs (paginated) |
| `GET /briefs/:id` | GET | Bearer + Premium | Get single Weekly Brief |
| `POST /webhooks/appstore` | POST | None | Apple StoreKit 2 notifications |

### Railway Deployment

1. Connect your GitHub repository to Railway
2. Set all environment variables from `.env.example`
3. Deploy — Railway auto-detects Node.js
4. The weekly brief cron job runs automatically in production

---

## iOS App Setup

### Prerequisites
- Xcode 15.4+
- iOS 16.0+ deployment target
- Apple Developer account

### Dependencies (Swift Package Manager)

Add these packages in Xcode → File → Add Package Dependencies:

| Package | URL | Version |
|---------|-----|---------|
| Supabase Swift | `https://github.com/supabase/supabase-swift` | 2.x |

### Configuration

In your scheme's environment variables or `Info.plist`:
- `WEALTHWISE_API_URL` — your Railway API URL (e.g. `https://api.wealthwise.app`)
- `SUPABASE_URL` — your Supabase project URL
- `SUPABASE_ANON_KEY` — your Supabase anon key

### StoreKit 2 Setup

1. Create subscription products in App Store Connect:
   - `com.wealthwise.basic.monthly` — $9.99/month
   - `com.wealthwise.basic.annual` — $79.99/year
   - `com.wealthwise.premium.monthly` — $24.99/month
   - `com.wealthwise.premium.annual` — $199.99/year

2. Add a StoreKit configuration file for local testing

---

## Subscription Tiers

| Feature | Free | Basic ($9.99/mo) | Premium ($24.99/mo) |
|---------|------|-----------------|---------------------|
| School Chapters 1–3 | ✅ | ✅ | ✅ |
| All 7 School Chapters | ❌ | ✅ | ✅ |
| Financial Calculators (save) | ❌ | ✅ | ✅ |
| Personal Dashboard | ❌ | ✅ | ✅ |
| RRSP + TFSA Tracker | ❌ | ✅ | ✅ |
| Monday AI Weekly Brief | ❌ | ❌ | ✅ |
| Personalized Market Context | ❌ | ❌ | ✅ |

---

## AI Weekly Brief Engine

Every Sunday at 23:00 EST, a Railway cron job:

1. Fetches all Premium subscribers from Supabase
2. Retrieves current Canadian market context via Claude web search (Bank of Canada rate, TSX, inflation, CAD/USD)
3. Generates a personalized 5-section Weekly Brief for each user using Claude `claude-sonnet-4-5`
4. Stores the brief in Supabase
5. Sends a push notification via APNs
6. Delivers a formatted HTML email via Resend

**Cost:** ~$0.006 per user per week at current Claude pricing. 150 Premium users ≈ $0.90/week.

**Regulatory:** All output is framed as educational guidance under OSC regulations. The prompt explicitly prohibits specific security recommendations.

---

## Legal & Regulatory Disclaimer

WealthWise provides **financial education content only**. Nothing in this app constitutes personalized financial, investment, or tax advice under OSC regulations. All Weekly Brief content includes the required disclaimer. Users are always advised to consult a Certified Financial Planner (CFP) for personalized advice.

---

## License

Proprietary — © 2026 The Money School Inc. All rights reserved.