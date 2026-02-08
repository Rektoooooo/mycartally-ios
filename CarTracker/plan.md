# CarTracker - App Plan

## Vision
A beautiful, privacy-focused car expense tracker and service reminder app for EU car owners. Simple enough for everyday use, powerful enough to track everything about your vehicle's lifetime.

---

## App Structure

### Tab Navigation (5 tabs)
1. **Dashboard** - Quick overview of all cars and upcoming events
2. **My Cars** - Manage vehicles/Users/sebastiankucera/Documents/GitHub/mycartally-ios/CarTracker/plan.md
3. **Log** - Add fuel/expenses/service records
4. **Statistics** - Charts and cost breakdowns
5. **Settings** - Preferences, sync, export

---

## Core Features (MVP)

### 1. Car Management
- Add car with details:
  - Make, Model, Year, Variant
  - License plate (EU format validation)
  - VIN number (17-char validation)
  - Fuel type: Petrol (E5/E10), Diesel, LPG, CNG, Hybrid, Electric
  - Purchase date & price
  - Current odometer
  - Photo (from camera/library)
- Car profile card with key info at a glance
- Archive cars (don't delete, keep history)

### 2. Fuel Log
- Quick-add fuel entry:
  - Date (defaults to today)
  - Odometer reading
  - Liters filled
  - Price per liter
  - Total cost (auto-calculated or manual)
  - Full tank toggle
  - Station name (optional, with location)
  - Receipt photo (optional)
- Fuel consumption calculation (L/100km)
- Track fuel type per fill-up (for flex-fuel/hybrids)

### 3. Expense Tracking
Categories:
- **Maintenance** (oil change, filters, brakes, tires, etc.)
- **Repairs** (unexpected fixes)
- **Insurance** (liability, comprehensive, GAP)
- **Taxes** (road tax, registration)
- **Inspection** (TÜV/STK/MOT/ITV/APK)
- **Parking** (permits, tickets)
- **Tolls** (vignettes, highway tolls)
- **Cleaning** (car wash, detailing)
- **Accessories** (mats, phone holder, etc.)
- **Other**

Each expense entry:
- Date
- Category + subcategory
- Cost
- Odometer (optional)
- Notes
- Receipt photo
- Service provider/location

### 4. Service Reminders
EU-focused reminder types:
- **Technical Inspection** (TÜV/STK/MOT/ITV/CT/APK)
  - Auto-detect interval by country (1-2 years)
  - Expiry date tracking
- **Emissions Test** (where separate from inspection)
- **Insurance Renewal**
- **Road Tax Due**
- **Oil Change** (by km or months)
- **Tire Change** (summer/winter, by date)
- **Timing Belt** (by km)
- **Brake Fluid** (every 2 years typically)
- **Coolant** (every 3-5 years)
- **Air Filter / Cabin Filter**
- **Spark Plugs**
- **Battery** (age tracking)
- **Warranty Expiry**
- **Environmental Sticker** (German Umweltplakette, etc.)
- **Vignette Expiry** (highway tolls)
- **Custom Reminders** (user-defined)

Reminder settings:
- Notify X days before due
- Notify at X km before due
- Repeat interval (one-time or recurring)
- Mark as completed (moves to history)

### 5. Dashboard
- Current car quick-switch
- Next upcoming reminder (prominent)
- This month's spending
- Fuel economy trend (last 5 fills)
- Quick action buttons:
  - Add Fuel
  - Add Expense
  - Record Service

### 6. Statistics (Basic)
- Cost per month bar chart
- Cost breakdown by category (pie chart)
- Fuel consumption trend line
- Total cost of ownership to date
- Average cost per km

---

## Premium Features

### 1. Multi-Car Support
- Free: 1 car
- Premium: Unlimited cars
- Compare costs between vehicles
- Fleet overview for families

### 2. PDF Export (Car History Report)
For selling your car - generates professional PDF:
- Vehicle details & photo
- Complete service history
- All maintenance records
- Fuel history summary
- Odometer readings log
- Total cost invested
- Inspection/MOT history
- Branded, shareable document

### 3. iCloud Sync
- Seamless sync across iPhone/iPad
- Automatic backup
- No account required (Apple ID)
- Encryption for privacy

### 4. Widgets
**Home Screen Widgets:**
- Small: Next reminder countdown
- Medium: Car + next 2 reminders + monthly cost
- Large: Multiple cars overview

**Lock Screen Widgets:**
- Next service due
- Days until inspection
- Monthly spending
- Last fuel consumption

### 5. Apple Watch App
- View next reminders
- Quick fuel log (liters + cost)
- Complications for next service date

### 6. Advanced Statistics
- Year-over-year comparison
- Fuel price trends
- Cost projection (annual estimate)
- Depreciation tracking
- Export to CSV/Excel

### 7. Shortcuts & Siri
- "Log fuel" shortcut
- "When is my inspection due?" Siri query
- CarPlay quick actions (future)

---

## Additional Innovative Features

### 1. Smart Fuel Predictions
- Track fuel prices at favorite stations
- Suggest optimal fill-up based on consumption
- Low fuel reminder based on average consumption

### 2. Service Interval Intelligence
- Pre-built service schedules by car make/model
- Adjust recommendations based on driving style (city vs highway)
- Manufacturer recommended intervals database

### 3. Odometer Photo Recognition (Premium)
- Take photo of odometer
- OCR extracts mileage automatically
- Prevents manual entry errors

### 4. Document Storage
- Store digital copies:
  - Registration document
  - Insurance card
  - Inspection certificate
  - Service book pages
- Quick access in wallet-style view

### 5. Fuel Station Integration
- Save favorite stations
- Optional: Fuel price comparison (via API)
- Map view of logged stations

### 6. Trip Tracking (Simple)
- Log trips for expense purposes
- Business vs personal separation
- Calculate trip costs (fuel + tolls)

### 7. Multi-Currency Support
- For users traveling in EU
- Currency conversion for foreign expenses
- Base currency setting

### 8. Expense Splitting
- Split costs between drivers
- Useful for shared/family cars

### 9. Tire Management
- Track tire sets (summer/winter/all-season)
- Mileage per tire set
- Rotation reminders
- Tread depth logging

### 10. Data Import
- Import from other apps (CSV)
- Bulk entry mode for historical data

---

## Technical Architecture

### Data Layer
- **SwiftData** for local persistence
- **CloudKit** for iCloud sync (premium)
- Models:
  - Car
  - FuelEntry
  - Expense
  - Reminder
  - Document
  - TireSet

### UI Framework
- **SwiftUI** (iOS 17+)
- Support for Dynamic Type
- Dark/Light mode
- Accessibility (VoiceOver)

### Target Platforms
- iPhone (primary)
- iPad (adaptive layout)
- Apple Watch (companion)
- Widgets (WidgetKit)

### Minimum iOS Version
- iOS 17.0 (for SwiftData, new widgets)

### Localization
Priority languages:
1. English
2. German
3. Czech
4. Polish
5. French
6. Spanish
7. Italian
8. Dutch

---

## Monetization Strategy

### Free Tier
- 1 car
- All logging features
- Basic statistics
- Reminders (up to 5 active)
- Local storage only

### Premium (One-time Purchase or Subscription)
Option A: **One-time $9.99**
- Unlimited cars
- PDF export
- iCloud sync
- All widgets
- Unlimited reminders
- Advanced statistics
- Document storage
- Priority support

Option B: **Subscription $2.99/month or $19.99/year**
- Same as above
- Future premium features included
- Family sharing (up to 6)

### Recommendation
Start with **one-time purchase** for user trust, easier sell in EU market where subscription fatigue is high.

---

## UI/UX Guidelines

### Design Principles
1. **Quick Entry** - Log fuel in under 10 seconds
2. **Glanceable** - Dashboard shows what matters now
3. **Non-intrusive** - Smart notifications, not spam
4. **Beautiful** - Car-focused aesthetic, quality feel
5. **Privacy-first** - No tracking, no accounts required

### Visual Style
- Clean, modern iOS design
- SF Symbols throughout
- Subtle car-themed accents
- High-contrast for outdoor use
- Haptic feedback for actions

### Key UX Patterns
- Pull-to-refresh on lists
- Swipe actions (edit/delete)
- Long-press for quick actions
- Shake to undo
- Search across all entries

---

## Development Phases

### Phase 1: Foundation (MVP)
- [ ] Data models (SwiftData)
- [ ] Car management (add/edit/view)
- [ ] Fuel logging
- [ ] Expense tracking (basic categories)
- [ ] Reminder system (basic)
- [ ] Dashboard view
- [ ] Basic statistics

### Phase 2: Polish & Reminders
- [ ] Complete reminder types
- [ ] Notification scheduling
- [ ] Receipt photo storage
- [ ] Improved statistics charts
- [ ] Onboarding flow
- [ ] Settings screen

### Phase 3: Premium Features
- [ ] iCloud sync
- [ ] Multi-car support
- [ ] PDF export
- [ ] Home screen widgets
- [ ] Lock screen widgets

### Phase 4: Advanced
- [ ] Apple Watch app
- [ ] Siri shortcuts
- [ ] Document storage
- [ ] Advanced statistics
- [ ] Data import/export

### Phase 5: Enhancements
- [ ] Odometer OCR
- [ ] Tire management
- [ ] Trip tracking
- [ ] Localization
- [ ] CarPlay (future)

---

## File Structure (Proposed)

```
CarTracker/
├── App/
│   ├── CarTrackerApp.swift
│   └── AppState.swift
├── Models/
│   ├── Car.swift
│   ├── FuelEntry.swift
│   ├── Expense.swift
│   ├── Reminder.swift
│   ├── Document.swift
│   └── TireSet.swift
├── Views/
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   ├── QuickActionsView.swift
│   │   └── UpcomingRemindersCard.swift
│   ├── Cars/
│   │   ├── CarsListView.swift
│   │   ├── CarDetailView.swift
│   │   └── AddCarView.swift
│   ├── Log/
│   │   ├── LogView.swift
│   │   ├── AddFuelView.swift
│   │   └── AddExpenseView.swift
│   ├── Statistics/
│   │   ├── StatisticsView.swift
│   │   ├── CostChartView.swift
│   │   └── FuelChartView.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── ExportView.swift
│   └── Components/
│       ├── CarCard.swift
│       ├── ReminderRow.swift
│       └── StatCard.swift
├── Services/
│   ├── NotificationService.swift
│   ├── PDFExportService.swift
│   ├── CloudSyncService.swift
│   └── CalculationService.swift
├── Extensions/
│   ├── Date+Extensions.swift
│   └── NumberFormatter+Extensions.swift
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.strings
└── Widgets/
    ├── CarTrackerWidget.swift
    └── LockScreenWidget.swift
```

---

## Success Metrics

### User Engagement
- Daily/Weekly active users
- Entries logged per user per month
- Reminder completion rate
- Premium conversion rate

### Quality
- App Store rating > 4.5
- Crash-free rate > 99.5%
- Widget adoption rate

### Revenue
- Premium conversion: target 5-10%
- Customer lifetime value
- Refund rate < 5%

---

## Competitive Advantages

1. **EU-focused** - Built for European inspection systems, fuel types, regulations
2. **Privacy-first** - No accounts, no tracking, your data stays yours
3. **Beautiful design** - Not just functional, delightful to use
4. **Fair pricing** - One-time purchase option, no subscription required
5. **Native quality** - Pure Swift/SwiftUI, fast, battery efficient
6. **Offline-first** - Works without internet, syncs when available

---

## Notes

- App name alternatives: CarLog, AutoTracker, MileageBook, CarCare, VehicleVault
- Consider App Clips for quick fuel logging
- Future: Android version consideration
- Future: Web dashboard for detailed reports
