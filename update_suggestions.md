# 🚀 SpendWise v1.1 — Update Suggestions

While your tests run, here are actionable improvements ranked by **user impact** and **review appeal**.

---

## 🔥 High Priority (Strongly Recommended for v1.1)

### 1. **Recurring Transactions Auto-Generation** ✅ *(Implemented in v1.1)*
- RecurringTransactions table with daily, weekly, monthly, and yearly frequencies
- Auto-generation service runs on app startup & app resume with duplicate prevention
- Dedicated Recurring Transactions & Subscriptions screen to manage, pause, and delete rules
- Integrated into AddTransactionSheet, Transactions AppBar, Settings, and Data Backup/Restore
- **Why:** Users expect "set and forget" for rent, subscriptions, etc.

### 2. **Notifications & Reminders** ✅ *(Implemented in v1.1)*
- Budget limit warnings (80% and 100% category threshold alerts)
- Savings goal milestone celebrations 🎉 (50%, 80%, and 100% achieved)
- Due date reminders for Debts (due today and upcoming in 1–3 days)
- Recurring transaction auto-generation notice alerts
- In-app Notification Center Sheet with unread badge counter on AppBar
- User preferences in Settings to independently toggle budget, debt, and savings alerts
- Complete database backup & restore support for notifications and preferences
- **Why:** Keeps users engaged daily — critical for retention.

### 3. **Data Backup & Restore** ✅ *(Implemented in v1.1)*
- Export full database to JSON file with system file share
- Import/restore from backup file with Full Replace (ACID rollback) & Merge modes
- **Why:** Users will panic about losing data. This is a top-1 feature request in finance apps and a common 1-star review cause.

### 4. **Search & Filters on Transactions** ✅ *(Implemented in v1.1)*
- Global search across all transactions by note, category, amount, occasion
- Date range presets (Today, Week, Month, Year, Custom), amount range filters
- Filter by category, occasion, income/expense, plus sorting (Date, Amount)
- **Why:** As data grows, users *need* this. Table stakes for a finance app.

---

## ⭐ Medium Priority (Great for User Delight)

### 5. **Dark/Light Theme Toggle** ✅ *(Implemented in v1.1)*
- 3-way theme mode selection: System Auto, Obsidian Dark, and Warm Cream Light
- Persistent storage in database `user_settings` table (Drift schema v9) with zero-flicker startup loading
- Interactive, tactile 3-way segment selector in Settings screen with active indicators and haptic feedback
- Seamless full database export and restore support for theme preferences
- **Why:** Delivers personalization, daytime readability, and accessibility while honoring OS system appearance.

### 6. **Monthly Summary / Insights Card** ✅ *(Implemented in v1.1)*
- Month-over-month spending comparison banner ("You spent X% more/less than last month")
- Top spending category breakdown with category icon, amount, and visual proportional progress bar
- Daily average spending metric calculated over days elapsed in current month
- Budget pacing indicator / Savings rate calculation
- Interactive custom sparkline chart showing daily spending trends from Day 1 to current day with peak day highlight
- View Mode segment switcher between "Overview" and "Trend" tabs
- Embedded right below Quick Actions on Dashboard screen
- **Why:** Makes the app feel intelligent, insightful, and worth opening daily.

### 7. **Transaction Attachments (Receipt Photos)** ✅ *(Implemented in v1.1)*
- Camera & Gallery receipt capture with permanent document directory persistence
- Interactive full-screen Pinch-to-Zoom viewer with sharing support
- Transaction list item receipt badge with 1-tap lightbox view
- **Why:** Differentiator over basic expense trackers. Great for business users.

### 8. **Wishlist / Cart Items Enhancement** ✅ *(Implemented in v1.1)*
- Link CartItems to SavingsGoals ("saving for this item") with real-time deposit synchronization
- Dedicated filter chips for Active, Purchased, and All wishlist items
- Priority badges (Low, Medium, High) with distinct aesthetic pills
- Mark as purchased bottom sheet with editable final price, expense category selector, date, note, and optional linked goal auto-completion
- Unmark/reopen purchased items and full backup & restore compatibility
- **Why:** Connects the shopping wishlist to actual finances seamlessly.

---

## 💎 Low Priority (Nice-to-Have / v1.2+)

### 9. **Multi-Currency Support** ✅ *(Implemented in v1.1)*
- Comprehensive currency service supporting 17 global currencies (INR, USD, EUR, GBP, AED, SAR, JPY, CAD, AUD, etc.)
- Transparent exchange rate conversion: all internal metrics and charts stay grounded in user's base currency while tracking original foreign amounts
- Intuitive currency selection pill and custom rate adjustment dialog in Add/Edit Transaction sheet
- Occasions/Trips custom trip currency support (e.g. Dubai trip in AED, Euro vacation in EUR) with automatic currency preselection
- Foreign currency amount badges in transaction lists and trip details
- Full database schema v10 migration and multi-currency backup/restore serialization
- **Why:** Essential for travel spending, online international purchases, and foreign vacations.

### 10. **Widgets (Android Home Screen)** ✅ *(Implemented in v1.1)*
- Native Android `AppWidgetProvider` (`SpendWiseWidgetProvider`) with 3x2 / 4x2 responsive remote layout
- Quick-glance live metrics showing **Today's Spend** and **Monthly Budget Remaining**
- Real-time pacing status badge ("On Track", "Near Limit", "Over Budget", "No Budget")
- 1-tap **+ Quick Add** expense shortcut opening the app directly to `AddTransactionSheet` via deep link (`spendwise://add_transaction`)
- Native MethodChannel (`com.shabeeb.spendwise/widget`) synchronizing automatically on transaction adds, edits, deletes, and budget modifications
- Interactive simulation card (`HomeScreenWidgetCard`) in Settings with manual "Sync Now" button and collapsible step-by-step home screen placement guide

### 11. **Onboarding Tutorial Improvements** ✅ *(Implemented in v1.1)*
- Multi-slide interactive Feature Showcase Carousel in initial onboarding with slide badges, live preview indicators, and skip/start setup actions
- Replayable guided in-app tour (`AppTourSheet`) highlighting all 5 core navigation tabs with direct tab jump previews and step-by-step feature guides
- Contextual dismissible hint cards (`ContextualHintCard`) providing pro-tips on screens (e.g. Dashboard daily spending trend sparkline tip)
- Accessible anytime from Settings ("App Tour & Feature Guide") and auto-prompted for new users
- Database schema v11 upgrade tracking `hasSeenAppTour` with full backup/restore persistence

### 12. **Accessibility Improvements**
- Semantic labels for all icons and charts
- Screen reader support
- High contrast mode

---

## 🛠️ Technical / Under-the-Hood

### 13. **Crash Reporting (Firebase Crashlytics)**
- Essential for identifying issues from real users before they leave 1-star reviews

### 14. **Analytics (Firebase Analytics)**
- Track which features users actually use
- Understand drop-off points

### 15. **Performance Optimization**
- Lazy-load heavy screens (Reports, Charts)
- Paginate transaction lists for users with 1000+ entries

---

## 📋 Recommended Roadmap

| Version | Features | Timeline |
|---------|----------|----------|
| **v1.1** | Search/Filters, Notifications, Backup/Restore, Receipt Photos | 1-2 weeks |
| **v1.2** | Theme Toggle, Monthly Insights, Recurring Auto-Gen | 1-2 weeks |
| **v1.3** | Home Screen Widget, Multi-Currency, Crashlytics | 2-3 weeks |

---

> [!TIP]
> **Start with Search/Filters + Backup/Restore** — these are the #1 and #2 most requested features in finance app reviews on the Play Store, and addressing them early prevents negative reviews.

Which features would you like to build first?
