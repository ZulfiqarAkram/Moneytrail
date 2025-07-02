# 💰 MoneyTrail

<div align="center">
  <img src="assets/app-logo.png" alt="MoneyTrail Logo" width="120" height="120">
  
  **Track your finances with ease**
  
  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
  [![SQLite](https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white)](https://sqlite.org)
  
  ![Version](https://img.shields.io/badge/version-1.0.0-green)
  ![Platform](https://img.shields.io/badge/platform-Android-brightgreen)
</div>

## 📱 About MoneyTrail

MoneyTrail is a comprehensive personal finance tracking application built with Flutter. It helps you manage your income and expenses with beautiful visualizations, detailed categorization, and insightful analytics - all stored locally on your device for complete privacy.

### ✨ Key Features

- 📊 **Beautiful Dashboard**: Overview with total income, expenses, and balance
- 📈 **Visual Analytics**: Interactive pie charts and 12-month bar charts
- 🏷️ **Smart Categories**: Pre-built categories with custom color coding
- 💱 **Multi-Currency Support**: 9 different currency symbols
- 📅 **Advanced Filtering**: Filter by month, year, or view all-time data
- 🎨 **Modern UI**: Material 3 design with custom brand colors
- 💾 **Local Storage**: All data stored securely on your device
- 🔄 **Category Management**: Enable/disable categories, smart deletion prevention
- 📱 **Mobile Optimized**: Designed specifically for Android devices

## 🏗️ App Architecture

### 📂 Project Structure
```
lib/
├── config/
│   └── app_config.dart          # App configuration & branding
├── models/
│   ├── category.dart            # Category data model
│   └── transaction.dart         # Transaction data model
├── screens/
│   ├── splash_screen.dart       # Custom splash screen
│   ├── dashboard_screen.dart    # Main app interface
│   ├── add_entry_screen.dart    # Add transactions
│   └── category_manager_screen.dart # Manage categories
└── services/
    └── database_helper.dart     # SQLite database operations
```

### 🎨 Design System

**Brand Colors:**
- Primary: `#149446` (Green)
- Secondary: `#202127` (Dark Gray)

**Features:**
- Material 3 Design Language
- Custom splash screen with brand gradient
- Consistent color theming throughout
- Responsive layouts for different screen sizes

## 🚀 Installation & Setup

### Prerequisites
- Flutter SDK (>=3.8.1)
- Android Studio or VS Code
- Android device or emulator

### Steps
1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/money_trail.git
   cd money_trail
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate app icons**
   ```bash
   dart run flutter_launcher_icons
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📊 App Features Breakdown

### 🏠 Overview Tab
- **Summary Cards**: Total Income, Total Expense, Current Balance
- **12-Month Chart**: Visual representation of financial trends
- **Welcome Message**: Personalized greeting with app branding

### 💸 Expenses Tab
- **Pie Chart**: Category-wise expense breakdown
- **Transaction List**: Detailed expense history with filtering
- **Quick Add**: Floating action button for new expenses

### 💰 Income Tab
- **Pie Chart**: Income source visualization
- **Transaction List**: All income transactions with details
- **Quick Add**: Floating action button for new income

### ⚙️ Settings Tab
- **Currency Selection**: 9 currency options (USD, EUR, GBP, etc.)
- **Category Management**: Access to category settings
- **App Information**: Version, developer details, contact info

### 🏷️ Category Management
- **Default Categories**: 12 pre-built categories (4 income, 8 expense)
- **Smart Controls**: Enable/disable instead of deletion
- **Data Protection**: Prevents deletion of categories with transactions
- **Visual Indicators**: Clear status indicators for disabled categories

## 🗄️ Database Schema

### Categories Table
```sql
CREATE TABLE categories(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    colorValue INTEGER NOT NULL DEFAULT 0xFF2196F3,
    isEnabled INTEGER NOT NULL DEFAULT 1
);
```

### Transactions Table
```sql
CREATE TABLE transactions(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL,
    amount REAL NOT NULL,
    categoryId INTEGER NOT NULL,
    date INTEGER NOT NULL,
    note TEXT,
    FOREIGN KEY (categoryId) REFERENCES categories (id)
);
```

## 🛠️ Technologies Used

- **Framework**: Flutter 3.8.1+
- **Language**: Dart
- **Database**: SQLite (sqflite package)
- **Charts**: FL Chart library
- **Local Storage**: SharedPreferences
- **State Management**: StatefulWidget with setState
- **UI Framework**: Material 3 Design
- **Icons**: Material Icons + Custom App Icon

### 📦 Key Dependencies
```yaml
dependencies:
  sqflite: ^2.3.3+1          # Local database
  fl_chart: ^0.69.0          # Charts & graphs
  intl: ^0.19.0              # Date formatting
  shared_preferences: ^2.2.3  # Settings storage
  url_launcher: ^6.2.4       # Contact features

dev_dependencies:
  flutter_launcher_icons: ^0.13.1  # Custom app icons
```

## 📈 Future Enhancements

- 📤 **Export/Import**: CSV data backup functionality
- 🔔 **Notifications**: Spending reminders and budget alerts
- 📊 **Advanced Analytics**: Monthly/yearly spending insights
- 🎯 **Budget Planning**: Set and track spending budgets
- 📱 **Cross-Platform**: iOS version development
- ☁️ **Cloud Sync**: Optional cloud backup (maintaining privacy)

## 👨‍💻 Developer Information

**Developer**: Zulfiqar Akram  
**Email**: [zulfiqar1152@hotmail.com](mailto:zulfiqar1152@hotmail.com)  
**WhatsApp**: [+92 344 8127902](https://wa.me/923448127902)  
**Version**: 1.0.0  

### 🤝 Contributing
Contributions, issues, and feature requests are welcome! Feel free to check the issues page or contact the developer directly.

### 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### 🙏 Acknowledgments
- Flutter team for the amazing framework
- Material Design team for the design system
- FL Chart library for beautiful data visualizations
- SQLite for reliable local storage

---

<div align="center">
  <p><strong>MoneyTrail - Your Personal Finance Companion</strong></p>
  <p>Built with ❤️ using Flutter</p>
</div>
