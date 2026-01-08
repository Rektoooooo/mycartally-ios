# MyCarTally - iOS App

A smart car expense tracking app built with SwiftUI. Track fuel consumption, expenses, maintenance reminders, and more with AI-powered receipt scanning.

## Features

- **AI Receipt Scanner** - Snap photos of receipts and automatically extract fuel prices, quantities, and totals using OCR
- **Fuel Tracking** - Log every fill-up with automatic consumption calculations (L/100km)
- **Expense Management** - Track all car-related costs: fuel, maintenance, insurance, parking
- **Smart Reminders** - Never miss oil changes, services, or inspections
- **Multiple Vehicles** - Manage expenses for all your cars in one place
- **Statistics & Analytics** - Beautiful charts showing spending patterns and trends
- **CSV/PDF Export** - Export your data for tax or personal records
- **Widget Support** - Quick glance at your car stats from the home screen
- **Privacy First** - All data stays on your device with SwiftData

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Tech Stack

- **SwiftUI** - Modern declarative UI framework
- **SwiftData** - Apple's native persistence framework
- **Vision** - OCR for receipt scanning
- **Charts** - Native Swift Charts for analytics
- **WidgetKit** - Home screen widgets

## Project Structure

```
CarTracker/
├── App/
│   ├── CarTrackerApp.swift    # App entry point
│   ├── AppState.swift         # Global app state
│   ├── ProManager.swift       # Pro features manager
│   └── UserSettings.swift     # User preferences
├── Models/
│   ├── Car.swift              # Vehicle model
│   ├── FuelEntry.swift        # Fuel log entries
│   ├── Expense.swift          # Expense records
│   └── Reminder.swift         # Maintenance reminders
├── Views/
│   ├── Dashboard/             # Main dashboard
│   ├── Cars/                  # Vehicle management
│   ├── Log/                   # Add entries (fuel, expenses)
│   │   └── Receipt/           # Receipt capture & OCR
│   ├── Statistics/            # Charts and analytics
│   ├── Reminders/             # Reminder management
│   ├── Settings/              # App settings
│   └── Onboarding/            # First-launch experience
├── Services/
│   ├── CalculationService.swift   # Fuel efficiency calculations
│   ├── NotificationService.swift  # Local notifications
│   ├── ReceiptOCRService.swift    # Receipt text extraction
│   ├── CSVExportService.swift     # CSV export
│   ├── PDFExportService.swift     # PDF export
│   └── WidgetDataService.swift    # Widget data provider
└── Assets.xcassets/           # Images and colors
```

## Getting Started

1. Clone the repository
2. Open `CarTracker.xcodeproj` in Xcode
3. Select your development team in Signing & Capabilities
4. Build and run on a simulator or device

## License

MIT
