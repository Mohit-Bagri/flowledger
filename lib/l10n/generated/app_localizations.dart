import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'FlowLedger'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get appLock;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @bankAccounts.
  ///
  /// In en, this message translates to:
  /// **'Bank Accounts'**
  String get bankAccounts;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgets;

  /// No description provided for @savingsGoals.
  ///
  /// In en, this message translates to:
  /// **'Savings Goals'**
  String get savingsGoals;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @merchants.
  ///
  /// In en, this message translates to:
  /// **'Merchants'**
  String get merchants;

  /// No description provided for @recurringTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recurring Transactions'**
  String get recurringTransactions;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get cloudSync;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get freePlan;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @continue_.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth Date'**
  String get birthDate;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @updateYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get updateYourPassword;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @permanentlyDelete.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and all data'**
  String get permanentlyDelete;

  /// No description provided for @signOutOfAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get signOutOfAccount;

  /// No description provided for @currencyWarning.
  ///
  /// In en, this message translates to:
  /// **'Changing currency will update the symbol displayed throughout the app. Your transaction amounts will remain unchanged.'**
  String get currencyWarning;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @enterNewEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter new email address'**
  String get enterNewEmail;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @totalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get totalIncome;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last30Days;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @addIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get addIncome;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @editIncome.
  ///
  /// In en, this message translates to:
  /// **'Edit Income'**
  String get editIncome;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get editExpense;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchCurrencies.
  ///
  /// In en, this message translates to:
  /// **'Search currencies...'**
  String get searchCurrencies;

  /// No description provided for @selectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get selectCurrency;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @searchMerchants.
  ///
  /// In en, this message translates to:
  /// **'Search merchants...'**
  String get searchMerchants;

  /// No description provided for @searchCategories.
  ///
  /// In en, this message translates to:
  /// **'Search categories...'**
  String get searchCategories;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @noIncome.
  ///
  /// In en, this message translates to:
  /// **'No income recorded'**
  String get noIncome;

  /// No description provided for @noIncomeYet.
  ///
  /// In en, this message translates to:
  /// **'No income yet'**
  String get noIncomeYet;

  /// No description provided for @noExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses recorded'**
  String get noExpenses;

  /// No description provided for @noExpensesYet.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get noExpensesYet;

  /// No description provided for @noIncomeSourcesYet.
  ///
  /// In en, this message translates to:
  /// **'No income sources yet'**
  String get noIncomeSourcesYet;

  /// No description provided for @tapAddIncomeToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add Income\" to get started'**
  String get tapAddIncomeToStart;

  /// No description provided for @tapAddExpenseToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add your first expense'**
  String get tapAddExpenseToStart;

  /// No description provided for @tapPlusToAddIncome.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add your first income'**
  String get tapPlusToAddIncome;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @clearingData.
  ///
  /// In en, this message translates to:
  /// **'Clearing data...'**
  String get clearingData;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @unlockApp.
  ///
  /// In en, this message translates to:
  /// **'Unlock FlowLedger'**
  String get unlockApp;

  /// No description provided for @authenticateToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to unlock'**
  String get authenticateToUnlock;

  /// No description provided for @useBiometric.
  ///
  /// In en, this message translates to:
  /// **'Use Biometric'**
  String get useBiometric;

  /// No description provided for @couldNotEnableAppLock.
  ///
  /// In en, this message translates to:
  /// **'Could not enable App Lock. Please check your device settings.'**
  String get couldNotEnableAppLock;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @incomeStreams.
  ///
  /// In en, this message translates to:
  /// **'Income Streams'**
  String get incomeStreams;

  /// No description provided for @recentExpenses.
  ///
  /// In en, this message translates to:
  /// **'Recent Expenses'**
  String get recentExpenses;

  /// No description provided for @netBalance.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get netBalance;

  /// No description provided for @overspent.
  ///
  /// In en, this message translates to:
  /// **'Overspent'**
  String get overspent;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @backupToCloud.
  ///
  /// In en, this message translates to:
  /// **'Backup to Cloud'**
  String get backupToCloud;

  /// No description provided for @restoreFromCloud.
  ///
  /// In en, this message translates to:
  /// **'Restore from Cloud'**
  String get restoreFromCloud;

  /// No description provided for @uploadAndDownloadChanges.
  ///
  /// In en, this message translates to:
  /// **'Upload and download changes'**
  String get uploadAndDownloadChanges;

  /// No description provided for @uploadAllLocalData.
  ///
  /// In en, this message translates to:
  /// **'Upload all local data'**
  String get uploadAllLocalData;

  /// No description provided for @downloadAllCloudData.
  ///
  /// In en, this message translates to:
  /// **'Download all cloud data'**
  String get downloadAllCloudData;

  /// No description provided for @signOutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Sign Out?'**
  String get signOutQuestion;

  /// No description provided for @deleteAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteAccountQuestion;

  /// No description provided for @restoreFromCloudQuestion.
  ///
  /// In en, this message translates to:
  /// **'Restore from Cloud?'**
  String get restoreFromCloudQuestion;

  /// No description provided for @localDataWillBeCleared.
  ///
  /// In en, this message translates to:
  /// **'Your local data will be cleared for privacy. Sign in again to restore your data from the cloud.'**
  String get localDataWillBeCleared;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @finalConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Final Confirmation'**
  String get finalConfirmation;

  /// No description provided for @deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete Forever'**
  String get deleteForever;

  /// No description provided for @typeDeleteToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get typeDeleteToConfirm;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllData;

  /// No description provided for @allLocalDataCleared.
  ///
  /// In en, this message translates to:
  /// **'All local data has been cleared'**
  String get allLocalDataCleared;

  /// No description provided for @errorClearingData.
  ///
  /// In en, this message translates to:
  /// **'Error clearing data'**
  String get errorClearingData;

  /// No description provided for @dailyReminders.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminders'**
  String get dailyReminders;

  /// No description provided for @dailyExpenseReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Expense Reminder'**
  String get dailyExpenseReminder;

  /// No description provided for @getRemindedToLogExpenses.
  ///
  /// In en, this message translates to:
  /// **'Get reminded to log your expenses'**
  String get getRemindedToLogExpenses;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @cheekyMessages.
  ///
  /// In en, this message translates to:
  /// **'Cheeky Messages'**
  String get cheekyMessages;

  /// No description provided for @funWittyReminderMessages.
  ///
  /// In en, this message translates to:
  /// **'Fun, witty reminder messages'**
  String get funWittyReminderMessages;

  /// No description provided for @budgetAlerts.
  ///
  /// In en, this message translates to:
  /// **'Budget Alerts'**
  String get budgetAlerts;

  /// No description provided for @getNotifiedBudgetLimits.
  ///
  /// In en, this message translates to:
  /// **'Get notified when approaching budget limits'**
  String get getNotifiedBudgetLimits;

  /// No description provided for @alertThreshold.
  ///
  /// In en, this message translates to:
  /// **'Alert Threshold'**
  String get alertThreshold;

  /// No description provided for @goalProgress.
  ///
  /// In en, this message translates to:
  /// **'Goal Progress'**
  String get goalProgress;

  /// No description provided for @goalNotifications.
  ///
  /// In en, this message translates to:
  /// **'Goal Notifications'**
  String get goalNotifications;

  /// No description provided for @getNotifiedGoalMilestones.
  ///
  /// In en, this message translates to:
  /// **'Get notified about savings goal milestones'**
  String get getNotifiedGoalMilestones;

  /// No description provided for @weeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly Summary'**
  String get weeklySummary;

  /// No description provided for @getSpendingSummaryEverySunday.
  ///
  /// In en, this message translates to:
  /// **'Get a spending summary every Sunday'**
  String get getSpendingSummaryEverySunday;

  /// No description provided for @sendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Test Notification'**
  String get sendTestNotification;

  /// No description provided for @notificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission'**
  String get notificationPermission;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNow;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @enableNotificationsToStayOnTrack.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications to stay on track with your finances'**
  String get enableNotificationsToStayOnTrack;

  /// No description provided for @addMerchant.
  ///
  /// In en, this message translates to:
  /// **'Add Merchant'**
  String get addMerchant;

  /// No description provided for @editMerchant.
  ///
  /// In en, this message translates to:
  /// **'Edit Merchant'**
  String get editMerchant;

  /// No description provided for @deleteMerchant.
  ///
  /// In en, this message translates to:
  /// **'Delete Merchant'**
  String get deleteMerchant;

  /// No description provided for @popularMerchants.
  ///
  /// In en, this message translates to:
  /// **'Popular Merchants'**
  String get popularMerchants;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @customMerchants.
  ///
  /// In en, this message translates to:
  /// **'Custom Merchants'**
  String get customMerchants;

  /// No description provided for @yourMerchants.
  ///
  /// In en, this message translates to:
  /// **'Your Merchants'**
  String get yourMerchants;

  /// No description provided for @noCustomMerchantsYet.
  ///
  /// In en, this message translates to:
  /// **'No custom merchants yet'**
  String get noCustomMerchantsYet;

  /// No description provided for @merchantName.
  ///
  /// In en, this message translates to:
  /// **'Merchant name...'**
  String get merchantName;

  /// No description provided for @renameMerchantNote.
  ///
  /// In en, this message translates to:
  /// **'This will rename in your saved merchants list. Note: This only updates the suggestion list. Existing expenses store merchant names directly and will keep the original name.'**
  String get renameMerchantNote;

  /// No description provided for @deleteMerchantNote.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete from your saved merchants? Note: This only removes it from the suggestion list. Existing expenses will keep their merchant names.'**
  String get deleteMerchantNote;

  /// No description provided for @incomeCategories.
  ///
  /// In en, this message translates to:
  /// **'Income Categories'**
  String get incomeCategories;

  /// No description provided for @expenseCategories.
  ///
  /// In en, this message translates to:
  /// **'Expense Categories'**
  String get expenseCategories;

  /// No description provided for @updateCategory.
  ///
  /// In en, this message translates to:
  /// **'Update Category'**
  String get updateCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @customCategory.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customCategory;

  /// No description provided for @systemCategory.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemCategory;

  /// No description provided for @noCustomIncomeCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No custom income categories yet'**
  String get noCustomIncomeCategoriesYet;

  /// No description provided for @noCustomExpenseCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No custom expense categories yet'**
  String get noCustomExpenseCategoriesYet;

  /// No description provided for @enterCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Enter category name...'**
  String get enterCategoryName;

  /// No description provided for @categoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category deleted'**
  String get categoryDeleted;

  /// No description provided for @categoryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Category updated'**
  String get categoryUpdated;

  /// No description provided for @updateCategoryForAllIncome.
  ///
  /// In en, this message translates to:
  /// **'This will update the category for all existing income entries. Continue?'**
  String get updateCategoryForAllIncome;

  /// No description provided for @updateCategoryForAllExpense.
  ///
  /// In en, this message translates to:
  /// **'This will update the category for all existing expense entries. Continue?'**
  String get updateCategoryForAllExpense;

  /// No description provided for @deleteCategoryConfirmIncome.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this category? This will affect all income entries using this category.'**
  String get deleteCategoryConfirmIncome;

  /// No description provided for @deleteCategoryConfirmExpense.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this category? This will affect all expense entries using this category.'**
  String get deleteCategoryConfirmExpense;

  /// No description provided for @addBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Bank Account'**
  String get addBankAccount;

  /// No description provided for @editBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit Bank Account'**
  String get editBankAccount;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeleted;

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankName;

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get accountNumber;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @accountNickname.
  ///
  /// In en, this message translates to:
  /// **'Account Nickname'**
  String get accountNickname;

  /// No description provided for @lastFourDigits.
  ///
  /// In en, this message translates to:
  /// **'Last 4 Digits'**
  String get lastFourDigits;

  /// No description provided for @ifscCode.
  ///
  /// In en, this message translates to:
  /// **'IFSC Code'**
  String get ifscCode;

  /// No description provided for @selectBankType.
  ///
  /// In en, this message translates to:
  /// **'Select bank type'**
  String get selectBankType;

  /// No description provided for @enterCustomAccountType.
  ///
  /// In en, this message translates to:
  /// **'Enter custom account type'**
  String get enterCustomAccountType;

  /// No description provided for @pleaseEnterCustomAccountType.
  ///
  /// In en, this message translates to:
  /// **'Please enter a custom account type name'**
  String get pleaseEnterCustomAccountType;

  /// No description provided for @addPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Add Payment Method'**
  String get addPaymentMethod;

  /// No description provided for @editPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Edit Payment Method'**
  String get editPaymentMethod;

  /// No description provided for @paymentMethodDeleted.
  ///
  /// In en, this message translates to:
  /// **'Payment method deleted'**
  String get paymentMethodDeleted;

  /// No description provided for @cashAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Cash is already added'**
  String get cashAlreadyAdded;

  /// No description provided for @cashAdded.
  ///
  /// In en, this message translates to:
  /// **'Cash added'**
  String get cashAdded;

  /// No description provided for @upiId.
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get upiId;

  /// No description provided for @cardLastFour.
  ///
  /// In en, this message translates to:
  /// **'Last 4 digits'**
  String get cardLastFour;

  /// No description provided for @enterPaymentMethodName.
  ///
  /// In en, this message translates to:
  /// **'Enter payment method name'**
  String get enterPaymentMethodName;

  /// No description provided for @createGoal.
  ///
  /// In en, this message translates to:
  /// **'Create Goal'**
  String get createGoal;

  /// No description provided for @editGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit Goal'**
  String get editGoal;

  /// No description provided for @addMoney.
  ///
  /// In en, this message translates to:
  /// **'Add Money'**
  String get addMoney;

  /// No description provided for @withdrawMoney.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Money'**
  String get withdrawMoney;

  /// No description provided for @deleteGoalQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete Goal?'**
  String get deleteGoalQuestion;

  /// No description provided for @deleteGoal.
  ///
  /// In en, this message translates to:
  /// **'Delete Goal'**
  String get deleteGoal;

  /// No description provided for @goalName.
  ///
  /// In en, this message translates to:
  /// **'Goal Name'**
  String get goalName;

  /// No description provided for @targetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target Amount'**
  String get targetAmount;

  /// No description provided for @currentAmount.
  ///
  /// In en, this message translates to:
  /// **'Current Amount'**
  String get currentAmount;

  /// No description provided for @targetDate.
  ///
  /// In en, this message translates to:
  /// **'Target Date'**
  String get targetDate;

  /// No description provided for @goalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Goal deleted'**
  String get goalDeleted;

  /// No description provided for @goalCreated.
  ///
  /// In en, this message translates to:
  /// **'Goal created'**
  String get goalCreated;

  /// No description provided for @goalUpdated.
  ///
  /// In en, this message translates to:
  /// **'Goal updated'**
  String get goalUpdated;

  /// No description provided for @noGoalsYet.
  ///
  /// In en, this message translates to:
  /// **'No savings goals yet'**
  String get noGoalsYet;

  /// No description provided for @copyBudgets.
  ///
  /// In en, this message translates to:
  /// **'Copy Budgets'**
  String get copyBudgets;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @noBudgetSet.
  ///
  /// In en, this message translates to:
  /// **'No budget set'**
  String get noBudgetSet;

  /// No description provided for @setBudget.
  ///
  /// In en, this message translates to:
  /// **'Set Budget'**
  String get setBudget;

  /// No description provided for @monthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget'**
  String get monthlyBudget;

  /// No description provided for @enterBudgetAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter budget amount'**
  String get enterBudgetAmount;

  /// No description provided for @setBudgetZeroRemove.
  ///
  /// In en, this message translates to:
  /// **'Set to 0 or empty to remove budget for this category'**
  String get setBudgetZeroRemove;

  /// No description provided for @quickSet.
  ///
  /// In en, this message translates to:
  /// **'Quick Set'**
  String get quickSet;

  /// No description provided for @saveBudget.
  ///
  /// In en, this message translates to:
  /// **'Save Budget'**
  String get saveBudget;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @budgetSetFor.
  ///
  /// In en, this message translates to:
  /// **'Budget set for {category}'**
  String budgetSetFor(String category);

  /// No description provided for @budgetRemovedFor.
  ///
  /// In en, this message translates to:
  /// **'Budget removed for {category}'**
  String budgetRemovedFor(String category);

  /// No description provided for @copyFromPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Copy from previous month'**
  String get copyFromPreviousMonth;

  /// No description provided for @noBudgetsFound.
  ///
  /// In en, this message translates to:
  /// **'No budgets found for {month}'**
  String noBudgetsFound(String month);

  /// No description provided for @copiedBudgets.
  ///
  /// In en, this message translates to:
  /// **'Copied {count} budget(s)'**
  String copiedBudgets(int count);

  /// No description provided for @budgeted.
  ///
  /// In en, this message translates to:
  /// **'Budgeted'**
  String get budgeted;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'used'**
  String get used;

  /// No description provided for @over.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get over;

  /// No description provided for @pendingTransactions.
  ///
  /// In en, this message translates to:
  /// **'Pending Transactions'**
  String get pendingTransactions;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @recurringTransactionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Recurring transaction deleted'**
  String get recurringTransactionDeleted;

  /// No description provided for @transactionAdded.
  ///
  /// In en, this message translates to:
  /// **'Transaction added!'**
  String get transactionAdded;

  /// No description provided for @skippedForThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'Skipped for this period'**
  String get skippedForThisPeriod;

  /// No description provided for @deleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense'**
  String get deleteExpense;

  /// No description provided for @deleteIncome.
  ///
  /// In en, this message translates to:
  /// **'Delete Income'**
  String get deleteIncome;

  /// No description provided for @deleteIncomeSource.
  ///
  /// In en, this message translates to:
  /// **'Delete Income Source'**
  String get deleteIncomeSource;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurring;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @stability.
  ///
  /// In en, this message translates to:
  /// **'Stability'**
  String get stability;

  /// No description provided for @bankAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get bankAccount;

  /// No description provided for @dateReceived.
  ///
  /// In en, this message translates to:
  /// **'Date Received'**
  String get dateReceived;

  /// No description provided for @nextExpected.
  ///
  /// In en, this message translates to:
  /// **'Next Expected'**
  String get nextExpected;

  /// No description provided for @incomeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Income deleted'**
  String get incomeDeleted;

  /// No description provided for @expenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted'**
  String get expenseDeleted;

  /// No description provided for @deleteExpenseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this expense? This action cannot be undone.'**
  String get deleteExpenseConfirm;

  /// No description provided for @deleteIncomeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this income? This action cannot be undone.'**
  String get deleteIncomeConfirm;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @cameraAccess.
  ///
  /// In en, this message translates to:
  /// **'Camera Access'**
  String get cameraAccess;

  /// No description provided for @photoLibraryAccess.
  ///
  /// In en, this message translates to:
  /// **'Photo Library Access'**
  String get photoLibraryAccess;

  /// No description provided for @scanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt'**
  String get scanReceipt;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get scanning;

  /// No description provided for @analyzingReceipt.
  ///
  /// In en, this message translates to:
  /// **'Analyzing receipt...'**
  String get analyzingReceipt;

  /// No description provided for @receiptScanned.
  ///
  /// In en, this message translates to:
  /// **'Receipt scanned successfully'**
  String get receiptScanned;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account Created!'**
  String get accountCreated;

  /// No description provided for @gotItGoToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Got it, go to Sign In'**
  String get gotItGoToSignIn;

  /// No description provided for @welcomeToFlowLedger.
  ///
  /// In en, this message translates to:
  /// **'Welcome to FlowLedger'**
  String get welcomeToFlowLedger;

  /// No description provided for @compareAndAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Compare & Analyze'**
  String get compareAndAnalyze;

  /// No description provided for @bankAccountAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Bank Account Analysis'**
  String get bankAccountAnalysis;

  /// No description provided for @sixMonthTrend.
  ///
  /// In en, this message translates to:
  /// **'6-Month Trend'**
  String get sixMonthTrend;

  /// No description provided for @aiInsights.
  ///
  /// In en, this message translates to:
  /// **'AI Insights'**
  String get aiInsights;

  /// No description provided for @dailySpendingPattern.
  ///
  /// In en, this message translates to:
  /// **'Daily Spending Pattern'**
  String get dailySpendingPattern;

  /// No description provided for @topMerchants.
  ///
  /// In en, this message translates to:
  /// **'Top Merchants'**
  String get topMerchants;

  /// No description provided for @dailySpending.
  ///
  /// In en, this message translates to:
  /// **'Daily Spending'**
  String get dailySpending;

  /// No description provided for @comparePaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Compare Payment Methods'**
  String get comparePaymentMethods;

  /// No description provided for @compareMerchants.
  ///
  /// In en, this message translates to:
  /// **'Compare Merchants'**
  String get compareMerchants;

  /// No description provided for @compareCategories.
  ///
  /// In en, this message translates to:
  /// **'Compare Categories'**
  String get compareCategories;

  /// No description provided for @unusualSpendingDetected.
  ///
  /// In en, this message translates to:
  /// **'Unusual Spending Detected'**
  String get unusualSpendingDetected;

  /// No description provided for @excellentSavings.
  ///
  /// In en, this message translates to:
  /// **'Excellent Savings!'**
  String get excellentSavings;

  /// No description provided for @spendingExceedsIncome.
  ///
  /// In en, this message translates to:
  /// **'Spending Exceeds Income'**
  String get spendingExceedsIncome;

  /// No description provided for @startTracking.
  ///
  /// In en, this message translates to:
  /// **'Start Tracking'**
  String get startTracking;

  /// No description provided for @allLookingGood.
  ///
  /// In en, this message translates to:
  /// **'All Looking Good!'**
  String get allLookingGood;

  /// No description provided for @noBankTransactionsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No bank transactions this month'**
  String get noBankTransactionsThisMonth;

  /// No description provided for @noMerchantData.
  ///
  /// In en, this message translates to:
  /// **'No merchant data'**
  String get noMerchantData;

  /// No description provided for @noDataForTrendAnalysis.
  ///
  /// In en, this message translates to:
  /// **'No data for trend analysis'**
  String get noDataForTrendAnalysis;

  /// No description provided for @noPaymentData.
  ///
  /// In en, this message translates to:
  /// **'No payment data'**
  String get noPaymentData;

  /// No description provided for @noDailyData.
  ///
  /// In en, this message translates to:
  /// **'No daily data'**
  String get noDailyData;

  /// No description provided for @noSpendingData.
  ///
  /// In en, this message translates to:
  /// **'No spending data'**
  String get noSpendingData;

  /// No description provided for @noDataForSelectedCategories.
  ///
  /// In en, this message translates to:
  /// **'No data for selected categories'**
  String get noDataForSelectedCategories;

  /// No description provided for @maxItemsCompareError.
  ///
  /// In en, this message translates to:
  /// **'Maximum 4 items can be compared at a time'**
  String get maxItemsCompareError;

  /// No description provided for @digital.
  ///
  /// In en, this message translates to:
  /// **'Digital'**
  String get digital;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @weeklyInsight.
  ///
  /// In en, this message translates to:
  /// **'Weekly Insight'**
  String get weeklyInsight;

  /// No description provided for @topSpendingCategory.
  ///
  /// In en, this message translates to:
  /// **'Your top spending category this week is {category}. You\'ve spent {amount} on it.'**
  String topSpendingCategory(String category, String amount);

  /// No description provided for @startTrackingInsight.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your expenses to get personalized insights about your spending patterns.'**
  String get startTrackingInsight;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @aboutFlowLedger.
  ///
  /// In en, this message translates to:
  /// **'About FlowLedger'**
  String get aboutFlowLedger;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @followsDeviceSettings.
  ///
  /// In en, this message translates to:
  /// **'Follows device settings'**
  String get followsDeviceSettings;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get pro;

  /// No description provided for @upgradeRequired.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Required'**
  String get upgradeRequired;

  /// No description provided for @thisFeatureRequiresPro.
  ///
  /// In en, this message translates to:
  /// **'This feature requires FlowLedger PRO'**
  String get thisFeatureRequiresPro;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to PRO'**
  String get upgradeToPro;

  /// No description provided for @flowLedgerPro.
  ///
  /// In en, this message translates to:
  /// **'FlowLedger PRO'**
  String get flowLedgerPro;

  /// No description provided for @unlockAllFeatures.
  ///
  /// In en, this message translates to:
  /// **'Unlock all features'**
  String get unlockAllFeatures;

  /// No description provided for @lifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get lifetime;

  /// No description provided for @oneTimePurchase.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase'**
  String get oneTimePurchase;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @perYear.
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get perYear;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get perMonth;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'Best Value'**
  String get bestValue;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get mostPopular;

  /// No description provided for @currencyFilter.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyFilter;

  /// No description provided for @allCurrencies.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCurrencies;

  /// No description provided for @clearDataWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your local data. Cloud sync is not enabled.'**
  String get clearDataWarning;

  /// No description provided for @clearDataCloudNote.
  ///
  /// In en, this message translates to:
  /// **'Your cloud data will remain safe. You can restore by syncing again.'**
  String get clearDataCloudNote;

  /// No description provided for @clearDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all data?'**
  String get clearDataConfirm;

  /// No description provided for @incomeTransactions.
  ///
  /// In en, this message translates to:
  /// **'Income Transactions'**
  String get incomeTransactions;

  /// No description provided for @expenseTransactions.
  ///
  /// In en, this message translates to:
  /// **'Expense Transactions'**
  String get expenseTransactions;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @incomeReceived.
  ///
  /// In en, this message translates to:
  /// **'Income received'**
  String get incomeReceived;

  /// No description provided for @quickSummary.
  ///
  /// In en, this message translates to:
  /// **'Quick Summary'**
  String get quickSummary;

  /// No description provided for @healthScore.
  ///
  /// In en, this message translates to:
  /// **'Health Score'**
  String get healthScore;

  /// No description provided for @savingPercent.
  ///
  /// In en, this message translates to:
  /// **'Saving {percent}%'**
  String savingPercent(String percent);

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @fair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get fair;

  /// No description provided for @poor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get poor;

  /// No description provided for @needsWork.
  ///
  /// In en, this message translates to:
  /// **'Needs Work'**
  String get needsWork;

  /// No description provided for @yourPersonalFinanceCompanion.
  ///
  /// In en, this message translates to:
  /// **'Your Personal Finance Companion'**
  String get yourPersonalFinanceCompanion;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'FlowLedger helps you track all your income streams, understand your expenses and detect money leaks automatically. Take control of your finances with powerful insights, budgeting tools and smart categorization.'**
  String get aboutDescription;

  /// No description provided for @keyFeatures.
  ///
  /// In en, this message translates to:
  /// **'Key Features'**
  String get keyFeatures;

  /// No description provided for @incomeExpenseTracking.
  ///
  /// In en, this message translates to:
  /// **'Income & Expense Tracking'**
  String get incomeExpenseTracking;

  /// No description provided for @smartBudgetsInsights.
  ///
  /// In en, this message translates to:
  /// **'Smart Budgets & Insights'**
  String get smartBudgetsInsights;

  /// No description provided for @receiptScanningAI.
  ///
  /// In en, this message translates to:
  /// **'Receipt Scanning with AI'**
  String get receiptScanningAI;

  /// No description provided for @cloudSyncBackup.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync & Backup'**
  String get cloudSyncBackup;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @flutterDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Flutter Developer'**
  String get flutterDeveloper;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rateUs;

  /// No description provided for @helpUsImprove.
  ///
  /// In en, this message translates to:
  /// **'Help us improve with your feedback'**
  String get helpUsImprove;

  /// No description provided for @madeWithLoveInIndia.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️ in India'**
  String get madeWithLoveInIndia;

  /// No description provided for @importTransactions.
  ///
  /// In en, this message translates to:
  /// **'Import Transactions'**
  String get importTransactions;

  /// No description provided for @premiumFeature.
  ///
  /// In en, this message translates to:
  /// **'Premium Feature'**
  String get premiumFeature;

  /// No description provided for @csvImportPremium.
  ///
  /// In en, this message translates to:
  /// **'CSV Import is available for premium users'**
  String get csvImportPremium;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @csvTemplate.
  ///
  /// In en, this message translates to:
  /// **'CSV Template'**
  String get csvTemplate;

  /// No description provided for @downloadSampleTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download a sample template with example data'**
  String get downloadSampleTemplate;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'REQUIRED'**
  String get required;

  /// No description provided for @fieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'Fields marked with * are mandatory'**
  String get fieldsRequired;

  /// No description provided for @viewFieldDetails.
  ///
  /// In en, this message translates to:
  /// **'View Field Details'**
  String get viewFieldDetails;

  /// No description provided for @selectCsvFile.
  ///
  /// In en, this message translates to:
  /// **'Select a CSV file to import'**
  String get selectCsvFile;

  /// No description provided for @transactionsFound.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions found'**
  String transactionsFound(int count);

  /// No description provided for @changeFile.
  ///
  /// In en, this message translates to:
  /// **'Change File'**
  String get changeFile;

  /// No description provided for @selectCsvFileBtn.
  ///
  /// In en, this message translates to:
  /// **'Select CSV File'**
  String get selectCsvFileBtn;

  /// No description provided for @importType.
  ///
  /// In en, this message translates to:
  /// **'Import Type'**
  String get importType;

  /// No description provided for @autoDetect.
  ///
  /// In en, this message translates to:
  /// **'Auto Detect'**
  String get autoDetect;

  /// No description provided for @autoDetectDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically detect CSV format'**
  String get autoDetectDesc;

  /// No description provided for @flowLedgerExport.
  ///
  /// In en, this message translates to:
  /// **'FlowLedger Export'**
  String get flowLedgerExport;

  /// No description provided for @flowLedgerExportDesc.
  ///
  /// In en, this message translates to:
  /// **'Import from FlowLedger exported CSV'**
  String get flowLedgerExportDesc;

  /// No description provided for @bankStatement.
  ///
  /// In en, this message translates to:
  /// **'Bank Statement'**
  String get bankStatement;

  /// No description provided for @bankStatementDesc.
  ///
  /// In en, this message translates to:
  /// **'Import from bank CSV export'**
  String get bankStatementDesc;

  /// No description provided for @customMapping.
  ///
  /// In en, this message translates to:
  /// **'Custom Mapping'**
  String get customMapping;

  /// No description provided for @customMappingDesc.
  ///
  /// In en, this message translates to:
  /// **'Manually map columns'**
  String get customMappingDesc;

  /// No description provided for @columnMapping.
  ///
  /// In en, this message translates to:
  /// **'Column Mapping'**
  String get columnMapping;

  /// No description provided for @mapColumnsDesc.
  ///
  /// In en, this message translates to:
  /// **'Map your CSV columns to transaction fields'**
  String get mapColumnsDesc;

  /// No description provided for @selectColumn.
  ///
  /// In en, this message translates to:
  /// **'Select column'**
  String get selectColumn;

  /// No description provided for @notMapped.
  ///
  /// In en, this message translates to:
  /// **'Not mapped'**
  String get notMapped;

  /// No description provided for @bankStatementSettings.
  ///
  /// In en, this message translates to:
  /// **'Bank Statement Settings'**
  String get bankStatementSettings;

  /// No description provided for @dateColumn.
  ///
  /// In en, this message translates to:
  /// **'Date Column'**
  String get dateColumn;

  /// No description provided for @descriptionColumn.
  ///
  /// In en, this message translates to:
  /// **'Description Column'**
  String get descriptionColumn;

  /// No description provided for @amountColumn.
  ///
  /// In en, this message translates to:
  /// **'Amount Column'**
  String get amountColumn;

  /// No description provided for @creditColumn.
  ///
  /// In en, this message translates to:
  /// **'Credit Column'**
  String get creditColumn;

  /// No description provided for @debitColumn.
  ///
  /// In en, this message translates to:
  /// **'Debit Column'**
  String get debitColumn;

  /// No description provided for @separateCreditDebitColumns.
  ///
  /// In en, this message translates to:
  /// **'Separate Credit/Debit Columns'**
  String get separateCreditDebitColumns;

  /// No description provided for @positiveCredits.
  ///
  /// In en, this message translates to:
  /// **'Positive amounts are credits (income)'**
  String get positiveCredits;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @andMoreRows.
  ///
  /// In en, this message translates to:
  /// **'... and {count} more rows'**
  String andMoreRows(int count);

  /// No description provided for @importTransactionsBtn.
  ///
  /// In en, this message translates to:
  /// **'Import Transactions'**
  String get importTransactionsBtn;

  /// No description provided for @importing.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get importing;

  /// No description provided for @importSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Import Successful!'**
  String get importSuccessful;

  /// No description provided for @importWithWarnings.
  ///
  /// In en, this message translates to:
  /// **'Import Completed with Warnings'**
  String get importWithWarnings;

  /// No description provided for @totalRows.
  ///
  /// In en, this message translates to:
  /// **'Total Rows'**
  String get totalRows;

  /// No description provided for @expensesImported.
  ///
  /// In en, this message translates to:
  /// **'Expenses Imported'**
  String get expensesImported;

  /// No description provided for @incomeImported.
  ///
  /// In en, this message translates to:
  /// **'Income Imported'**
  String get incomeImported;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @templateReady.
  ///
  /// In en, this message translates to:
  /// **'Template ready to share!'**
  String get templateReady;

  /// No description provided for @failedCreateTemplate.
  ///
  /// In en, this message translates to:
  /// **'Failed to create template'**
  String get failedCreateTemplate;

  /// No description provided for @couldNotReadCsv.
  ///
  /// In en, this message translates to:
  /// **'Could not read CSV file'**
  String get couldNotReadCsv;

  /// No description provided for @errorLoadingFile.
  ///
  /// In en, this message translates to:
  /// **'Error loading file'**
  String get errorLoadingFile;

  /// No description provided for @selectDateColumn.
  ///
  /// In en, this message translates to:
  /// **'Please select the date column'**
  String get selectDateColumn;

  /// No description provided for @selectAmountColumn.
  ///
  /// In en, this message translates to:
  /// **'Please select the amount column'**
  String get selectAmountColumn;

  /// No description provided for @mapDateAmount.
  ///
  /// In en, this message translates to:
  /// **'Please map Date and Amount columns'**
  String get mapDateAmount;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importFailed;

  /// No description provided for @importedTransactions.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} transactions'**
  String importedTransactions(int count);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @noNotesAdded.
  ///
  /// In en, this message translates to:
  /// **'No notes added'**
  String get noNotesAdded;

  /// No description provided for @pleaseSelectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get pleaseSelectPaymentMethod;

  /// No description provided for @pleaseSelectBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Please select a bank account for this payment method'**
  String get pleaseSelectBankAccount;

  /// No description provided for @pleaseEnterMerchantName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a merchant name'**
  String get pleaseEnterMerchantName;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// No description provided for @pleaseEnterCustomCategory.
  ///
  /// In en, this message translates to:
  /// **'Please enter a custom category name'**
  String get pleaseEnterCustomCategory;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get pleaseEnterAmount;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterName;

  /// No description provided for @pleaseEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterValidAmount;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select payment method'**
  String get selectPaymentMethod;

  /// No description provided for @selectBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Select bank account'**
  String get selectBankAccount;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategory;

  /// No description provided for @selectMerchant.
  ///
  /// In en, this message translates to:
  /// **'Select merchant'**
  String get selectMerchant;

  /// No description provided for @enterMerchantName.
  ///
  /// In en, this message translates to:
  /// **'Enter merchant name...'**
  String get enterMerchantName;

  /// No description provided for @anyAdditionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Any additional details...'**
  String get anyAdditionalDetails;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @biweekly.
  ///
  /// In en, this message translates to:
  /// **'Bi-weekly'**
  String get biweekly;

  /// No description provided for @monthlyFreq.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyFreq;

  /// No description provided for @quarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get quarterly;

  /// No description provided for @halfYearly.
  ///
  /// In en, this message translates to:
  /// **'Half-yearly'**
  String get halfYearly;

  /// No description provided for @yearlyFreq.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearlyFreq;

  /// No description provided for @salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salary;

  /// No description provided for @freelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get freelance;

  /// No description provided for @business.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get business;

  /// No description provided for @investment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get investment;

  /// No description provided for @rental.
  ///
  /// In en, this message translates to:
  /// **'Rental'**
  String get rental;

  /// No description provided for @dividend.
  ///
  /// In en, this message translates to:
  /// **'Dividend'**
  String get dividend;

  /// No description provided for @bonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get bonus;

  /// No description provided for @gift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get gift;

  /// No description provided for @refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;

  /// No description provided for @otherIncome.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherIncome;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food & Dining'**
  String get food;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shopping;

  /// No description provided for @utilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get utilities;

  /// No description provided for @entertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get entertainment;

  /// No description provided for @healthcare.
  ///
  /// In en, this message translates to:
  /// **'Healthcare'**
  String get healthcare;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travel;

  /// No description provided for @personalCare.
  ///
  /// In en, this message translates to:
  /// **'Personal Care'**
  String get personalCare;

  /// No description provided for @groceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get groceries;

  /// No description provided for @rent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rent;

  /// No description provided for @insurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get insurance;

  /// No description provided for @subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptions;

  /// No description provided for @otherExpense.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherExpense;

  /// No description provided for @noCategoriesForFilter.
  ///
  /// In en, this message translates to:
  /// **'No items for this category'**
  String get noCategoriesForFilter;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get pullToRefresh;

  /// No description provided for @exportAsPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get exportAsPdf;

  /// No description provided for @exportAsCsv.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get exportAsCsv;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Export successful'**
  String get exportSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @shareExport.
  ///
  /// In en, this message translates to:
  /// **'Share Export'**
  String get shareExport;

  /// No description provided for @debugMode.
  ///
  /// In en, this message translates to:
  /// **'Debug Mode'**
  String get debugMode;

  /// No description provided for @debugPremium.
  ///
  /// In en, this message translates to:
  /// **'Debug Premium'**
  String get debugPremium;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent'**
  String get passwordResetEmailSent;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email for instructions'**
  String get checkYourEmail;

  /// No description provided for @biometricAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get biometricAuthentication;

  /// No description provided for @useFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint to unlock'**
  String get useFingerprint;

  /// No description provided for @useFaceId.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID to unlock'**
  String get useFaceId;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again'**
  String get checkConnection;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @tryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get tryAgainLater;

  /// No description provided for @changesSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get changesSaved;

  /// No description provided for @settingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Settings updated'**
  String get settingsUpdated;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selected;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get item;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// No description provided for @oldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get oldest;

  /// No description provided for @highest.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get highest;

  /// No description provided for @lowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get lowest;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @count.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get count;

  /// No description provided for @percentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get percentage;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get apr;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dec;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @editAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get editAccount;

  /// No description provided for @securityNote.
  ///
  /// In en, this message translates to:
  /// **'FlowLedger stores data locally on your device only. We do not collect or store any sensitive financial information like full account numbers or passwords.'**
  String get securityNote;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get accountName;

  /// No description provided for @accountNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., \"Salary Account\", \"Savings\"'**
  String get accountNameHint;

  /// No description provided for @accountNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Account name is required'**
  String get accountNameRequired;

  /// No description provided for @customAccountType.
  ///
  /// In en, this message translates to:
  /// **'Custom Account Type'**
  String get customAccountType;

  /// No description provided for @customAccountTypeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Trading Account, PPF, etc.'**
  String get customAccountTypeHint;

  /// No description provided for @customAccountTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Custom account type is required'**
  String get customAccountTypeRequired;

  /// No description provided for @accountNumberLast4.
  ///
  /// In en, this message translates to:
  /// **'Account Number (Last 4 digits)'**
  String get accountNumberLast4;

  /// No description provided for @last4DigitsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 1234'**
  String get last4DigitsHint;

  /// No description provided for @last4DigitsRequired.
  ///
  /// In en, this message translates to:
  /// **'Last 4 digits are required'**
  String get last4DigitsRequired;

  /// No description provided for @pleaseEnter4Digits.
  ///
  /// In en, this message translates to:
  /// **'Please enter exactly 4 digits'**
  String get pleaseEnter4Digits;

  /// No description provided for @ifscCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'IFSC Code (Optional)'**
  String get ifscCodeOptional;

  /// No description provided for @ifscCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., HDFC0001234'**
  String get ifscCodeHint;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @updateAccount.
  ///
  /// In en, this message translates to:
  /// **'Update Account'**
  String get updateAccount;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// No description provided for @selectBank.
  ///
  /// In en, this message translates to:
  /// **'Select Bank'**
  String get selectBank;

  /// No description provided for @searchBanks.
  ///
  /// In en, this message translates to:
  /// **'Search banks...'**
  String get searchBanks;

  /// No description provided for @otherEnterCustom.
  ///
  /// In en, this message translates to:
  /// **'Other (Enter custom name)'**
  String get otherEnterCustom;

  /// No description provided for @backToList.
  ///
  /// In en, this message translates to:
  /// **'Back to list'**
  String get backToList;

  /// No description provided for @enterBankName.
  ///
  /// In en, this message translates to:
  /// **'Enter bank name...'**
  String get enterBankName;

  /// No description provided for @paymentSecurityNote.
  ///
  /// In en, this message translates to:
  /// **'FlowLedger stores data locally on your device only. We do not collect or store any sensitive financial information like full card numbers, CVV or bank passwords.'**
  String get paymentSecurityNote;

  /// No description provided for @paymentType.
  ///
  /// In en, this message translates to:
  /// **'Payment Type'**
  String get paymentType;

  /// No description provided for @updateMethod.
  ///
  /// In en, this message translates to:
  /// **'Update Method'**
  String get updateMethod;

  /// No description provided for @addMethod.
  ///
  /// In en, this message translates to:
  /// **'Add Method'**
  String get addMethod;

  /// No description provided for @cashPaymentsNote.
  ///
  /// In en, this message translates to:
  /// **'Cash payments will be tracked without any additional details.'**
  String get cashPaymentsNote;

  /// No description provided for @upiApp.
  ///
  /// In en, this message translates to:
  /// **'UPI App'**
  String get upiApp;

  /// No description provided for @upiIdOptional.
  ///
  /// In en, this message translates to:
  /// **'UPI ID (Optional)'**
  String get upiIdOptional;

  /// No description provided for @upiIdHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., yourname@okbank'**
  String get upiIdHint;

  /// No description provided for @cardName.
  ///
  /// In en, this message translates to:
  /// **'Card Name'**
  String get cardName;

  /// No description provided for @transferType.
  ///
  /// In en, this message translates to:
  /// **'Transfer Type'**
  String get transferType;

  /// No description provided for @walletName.
  ///
  /// In en, this message translates to:
  /// **'Wallet Name'**
  String get walletName;

  /// No description provided for @chequeDetails.
  ///
  /// In en, this message translates to:
  /// **'Cheque Details'**
  String get chequeDetails;

  /// No description provided for @chequeDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Cheque No. 123456'**
  String get chequeDetailsHint;

  /// No description provided for @chequeDetailsRequired.
  ///
  /// In en, this message translates to:
  /// **'Cheque details are required'**
  String get chequeDetailsRequired;

  /// No description provided for @chequeNote.
  ///
  /// In en, this message translates to:
  /// **'Enter cheque number or any reference for tracking.'**
  String get chequeNote;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @enterUpiAppName.
  ///
  /// In en, this message translates to:
  /// **'Enter UPI app name...'**
  String get enterUpiAppName;

  /// No description provided for @upiAppNameRequired.
  ///
  /// In en, this message translates to:
  /// **'UPI app name is required'**
  String get upiAppNameRequired;

  /// No description provided for @cardNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., \"My {cardType} Card\"'**
  String cardNameHint(Object cardType);

  /// No description provided for @cardNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Card name is required'**
  String get cardNameRequired;

  /// No description provided for @enterTransferType.
  ///
  /// In en, this message translates to:
  /// **'Enter transfer type...'**
  String get enterTransferType;

  /// No description provided for @transferTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Transfer type is required'**
  String get transferTypeRequired;

  /// No description provided for @walletNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., \"My Wallet\"'**
  String get walletNameHint;

  /// No description provided for @walletNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Wallet name is required'**
  String get walletNameRequired;

  /// No description provided for @addByTappingPlus.
  ///
  /// In en, this message translates to:
  /// **'Add one by tapping the + button above or by adding an expense with a new merchant'**
  String get addByTappingPlus;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @merchantSettings.
  ///
  /// In en, this message translates to:
  /// **'Merchant Settings'**
  String get merchantSettings;

  /// No description provided for @merchantFieldMandatory.
  ///
  /// In en, this message translates to:
  /// **'Merchant field is mandatory'**
  String get merchantFieldMandatory;

  /// No description provided for @merchantMandatoryNote.
  ///
  /// In en, this message translates to:
  /// **'You must enter a merchant when adding expenses'**
  String get merchantMandatoryNote;

  /// No description provided for @merchantOptionalNote.
  ///
  /// In en, this message translates to:
  /// **'Merchant field is optional when adding expenses'**
  String get merchantOptionalNote;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Track Every Income Stream'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Salary, freelance, business, passive income. Manage all your earnings in one place.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Know Where Money Goes'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Categorize expenses, scan receipts and see spending patterns at a glance.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Find Your Money Leaks'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'AI detects wasteful spending you don\'t notice. Small purchases that add up.'**
  String get onboardingDesc3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In en, this message translates to:
  /// **'Ready to Take Control?'**
  String get onboardingTitle4;

  /// No description provided for @onboardingDesc4.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your finances today and never wonder where your money went again.'**
  String get onboardingDesc4;

  /// No description provided for @yesLetsGo.
  ///
  /// In en, this message translates to:
  /// **'Yes, Let\'s Go!'**
  String get yesLetsGo;

  /// No description provided for @appIsLocked.
  ///
  /// In en, this message translates to:
  /// **'App is locked'**
  String get appIsLocked;

  /// No description provided for @authenticating.
  ///
  /// In en, this message translates to:
  /// **'Authenticating...'**
  String get authenticating;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @useFaceIdTouchIdOrPin.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID, Touch ID, or device PIN'**
  String get useFaceIdTouchIdOrPin;

  /// No description provided for @whatsIncluded.
  ///
  /// In en, this message translates to:
  /// **'What\'s included'**
  String get whatsIncluded;

  /// No description provided for @renewsOn.
  ///
  /// In en, this message translates to:
  /// **'Renews on {date}'**
  String renewsOn(String date);

  /// No description provided for @lifetimeAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Lifetime access'**
  String get lifetimeAccessLabel;

  /// No description provided for @limitedFeatures.
  ///
  /// In en, this message translates to:
  /// **'Limited features'**
  String get limitedFeatures;

  /// No description provided for @editRecurring.
  ///
  /// In en, this message translates to:
  /// **'Edit Recurring'**
  String get editRecurring;

  /// No description provided for @addRecurring.
  ///
  /// In en, this message translates to:
  /// **'Add Recurring'**
  String get addRecurring;

  /// No description provided for @recurringNameHintExpense.
  ///
  /// In en, this message translates to:
  /// **'e.g., \"Netflix Subscription\"'**
  String get recurringNameHintExpense;

  /// No description provided for @recurringNameHintIncome.
  ///
  /// In en, this message translates to:
  /// **'e.g., \"Monthly Salary\"'**
  String get recurringNameHintIncome;

  /// No description provided for @nextDueDate.
  ///
  /// In en, this message translates to:
  /// **'Next Due Date'**
  String get nextDueDate;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick Date'**
  String get pickDate;

  /// No description provided for @chooseIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose Icon'**
  String get chooseIcon;

  /// No description provided for @enterCustomCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Enter custom category name...'**
  String get enterCustomCategoryName;

  /// No description provided for @fromBankAccount.
  ///
  /// In en, this message translates to:
  /// **'From Bank Account'**
  String get fromBankAccount;

  /// No description provided for @toBankAccount.
  ///
  /// In en, this message translates to:
  /// **'To Bank Account'**
  String get toBankAccount;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @updateRecurring.
  ///
  /// In en, this message translates to:
  /// **'Update Recurring'**
  String get updateRecurring;

  /// No description provided for @saveRecurring.
  ///
  /// In en, this message translates to:
  /// **'Save Recurring'**
  String get saveRecurring;

  /// No description provided for @addPaymentMethodFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a payment method'**
  String get addPaymentMethodFirst;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get addNew;

  /// No description provided for @noBankAccountsConfigured.
  ///
  /// In en, this message translates to:
  /// **'No bank accounts configured'**
  String get noBankAccountsConfigured;

  /// No description provided for @tapToAddBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Tap to add a bank account'**
  String get tapToAddBankAccount;

  /// No description provided for @addBank.
  ///
  /// In en, this message translates to:
  /// **'Add Bank'**
  String get addBank;

  /// No description provided for @recurringTransactionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recurring transaction updated!'**
  String get recurringTransactionUpdated;

  /// No description provided for @recurringTransactionAdded.
  ///
  /// In en, this message translates to:
  /// **'Recurring transaction added!'**
  String get recurringTransactionAdded;

  /// No description provided for @reviewReceipt.
  ///
  /// In en, this message translates to:
  /// **'Review Receipt'**
  String get reviewReceipt;

  /// No description provided for @use.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get use;

  /// No description provided for @itemsDetected.
  ///
  /// In en, this message translates to:
  /// **'items detected'**
  String get itemsDetected;

  /// No description provided for @tapToViewFullImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to view full image'**
  String get tapToViewFullImage;

  /// No description provided for @merchantNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Merchant Name'**
  String get merchantNameLabel;

  /// No description provided for @receiptItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get receiptItems;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @noItemsDetected.
  ///
  /// In en, this message translates to:
  /// **'No items detected'**
  String get noItemsDetected;

  /// No description provided for @tapAddItemToAddManually.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add Item\" to add manually'**
  String get tapAddItemToAddManually;

  /// No description provided for @selectedTotal.
  ///
  /// In en, this message translates to:
  /// **'Selected Total'**
  String get selectedTotal;

  /// No description provided for @ofItems.
  ///
  /// In en, this message translates to:
  /// **'of {count} items'**
  String ofItems(int count);

  /// No description provided for @viewRawExtractedText.
  ///
  /// In en, this message translates to:
  /// **'View raw extracted text'**
  String get viewRawExtractedText;

  /// No description provided for @useThisData.
  ///
  /// In en, this message translates to:
  /// **'Use This Data ({count} items)'**
  String useThisData(int count);

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get editItem;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @itemNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Coffee'**
  String get itemNameHint;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @signInToSyncData.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your data across devices'**
  String get signInToSyncData;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterYourPassword;

  /// No description provided for @passwordMin6Chars.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMin6Chars;

  /// No description provided for @signedUpWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Signed up with Google? Skip the form and use the Google button below.'**
  String get signedUpWithGoogle;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @mustBe12YearsOld.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 12 years old to use this app'**
  String get mustBe12YearsOld;

  /// No description provided for @pleaseSelectBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Please select your birth date'**
  String get pleaseSelectBirthDate;

  /// No description provided for @selectYourBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Select your birth date'**
  String get selectYourBirthDate;

  /// No description provided for @newPasswordMustBeDifferent.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from your current password. Please choose a different password.'**
  String get newPasswordMustBeDifferent;

  /// No description provided for @resetLinkExpired.
  ///
  /// In en, this message translates to:
  /// **'This reset link has expired. Please request a new password reset link.'**
  String get resetLinkExpired;

  /// No description provided for @failedToResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset password. The link may have expired. Please try again.'**
  String get failedToResetPassword;

  /// No description provided for @passwordUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully!'**
  String get passwordUpdatedSuccessfully;

  /// No description provided for @selectTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTimeTitle;

  /// No description provided for @setTime.
  ///
  /// In en, this message translates to:
  /// **'Set Time'**
  String get setTime;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get selectDateRange;

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get customRange;

  /// No description provided for @tapToSelectDates.
  ///
  /// In en, this message translates to:
  /// **'Tap to select dates'**
  String get tapToSelectDates;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @limitReached.
  ///
  /// In en, this message translates to:
  /// **'Limit Reached'**
  String get limitReached;

  /// No description provided for @unlimitedAccess.
  ///
  /// In en, this message translates to:
  /// **'Unlimited {feature}'**
  String unlimitedAccess(String feature);

  /// No description provided for @cloudSyncAcrossDevices.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync across devices'**
  String get cloudSyncAcrossDevices;

  /// No description provided for @advancedInsightsReports.
  ///
  /// In en, this message translates to:
  /// **'Advanced insights & reports'**
  String get advancedInsightsReports;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// No description provided for @unlockThisFeature.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium to unlock this feature'**
  String get unlockThisFeature;

  /// No description provided for @deepSpendingAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Deep spending analytics'**
  String get deepSpendingAnalytics;

  /// No description provided for @categoryBreakdowns.
  ///
  /// In en, this message translates to:
  /// **'Category breakdowns'**
  String get categoryBreakdowns;

  /// No description provided for @trendComparisons.
  ///
  /// In en, this message translates to:
  /// **'Trend comparisons'**
  String get trendComparisons;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera Permission Required'**
  String get cameraPermissionRequired;

  /// No description provided for @cameraPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to scan receipts. Please enable it in Settings.'**
  String get cameraPermissionMessage;

  /// No description provided for @photoLibraryPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo Library Permission Required'**
  String get photoLibraryPermissionRequired;

  /// No description provided for @photoLibraryPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Photo library access is needed to select receipt images. Please enable it in Settings.'**
  String get photoLibraryPermissionMessage;

  /// No description provided for @notificationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission Required'**
  String get notificationPermissionRequired;

  /// No description provided for @notificationPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Notifications help you stay on track with expense tracking reminders. Please enable it in Settings.'**
  String get notificationPermissionMessage;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @authenticateToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to continue'**
  String get authenticateToContinue;

  /// No description provided for @authenticateToEditTransaction.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to edit this transaction'**
  String get authenticateToEditTransaction;

  /// No description provided for @authenticateToDeleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to delete this transaction'**
  String get authenticateToDeleteTransaction;

  /// No description provided for @excellentSavingsRate.
  ///
  /// In en, this message translates to:
  /// **'Excellent savings rate'**
  String get excellentSavingsRate;

  /// No description provided for @savingOfIncome.
  ///
  /// In en, this message translates to:
  /// **'Saving {percent}% of income'**
  String savingOfIncome(String percent);

  /// No description provided for @goodSavingsRate.
  ///
  /// In en, this message translates to:
  /// **'Good savings rate'**
  String get goodSavingsRate;

  /// No description provided for @moderateSavings.
  ///
  /// In en, this message translates to:
  /// **'Moderate savings'**
  String get moderateSavings;

  /// No description provided for @overspending.
  ///
  /// In en, this message translates to:
  /// **'Overspending'**
  String get overspending;

  /// No description provided for @spendingMoreThanEarning.
  ///
  /// In en, this message translates to:
  /// **'Spending more than earning'**
  String get spendingMoreThanEarning;

  /// No description provided for @lowSavings.
  ///
  /// In en, this message translates to:
  /// **'Low savings'**
  String get lowSavings;

  /// No description provided for @tryToSave20Percent.
  ///
  /// In en, this message translates to:
  /// **'Try to save at least 20%'**
  String get tryToSave20Percent;

  /// No description provided for @recurringIncome.
  ///
  /// In en, this message translates to:
  /// **'Recurring income'**
  String get recurringIncome;

  /// No description provided for @recurringSourcesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} recurring source(s)'**
  String recurringSourcesCount(int count);

  /// No description provided for @multipleIncomeEntries.
  ///
  /// In en, this message translates to:
  /// **'Multiple income entries'**
  String get multipleIncomeEntries;

  /// No description provided for @entriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String entriesCount(int count);

  /// No description provided for @budgetDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Budget discipline'**
  String get budgetDiscipline;

  /// No description provided for @allBudgetsOnTrack.
  ///
  /// In en, this message translates to:
  /// **'All {count} budget(s) on track'**
  String allBudgetsOnTrack(int count);

  /// No description provided for @budgetOverruns.
  ///
  /// In en, this message translates to:
  /// **'Budget overruns'**
  String get budgetOverruns;

  /// No description provided for @budgetsExceeded.
  ///
  /// In en, this message translates to:
  /// **'{count} budget(s) exceeded'**
  String budgetsExceeded(int count);

  /// No description provided for @manyMicroTransactions.
  ///
  /// In en, this message translates to:
  /// **'Many micro-transactions'**
  String get manyMicroTransactions;

  /// No description provided for @purchasesUnderAmount.
  ///
  /// In en, this message translates to:
  /// **'{count} purchases under ₹200'**
  String purchasesUnderAmount(int count);

  /// No description provided for @consistentSpending.
  ///
  /// In en, this message translates to:
  /// **'Consistent spending'**
  String get consistentSpending;

  /// No description provided for @noUnusualSpikes.
  ///
  /// In en, this message translates to:
  /// **'No unusual spikes'**
  String get noUnusualSpikes;

  /// No description provided for @spendingImproved.
  ///
  /// In en, this message translates to:
  /// **'Spending improved'**
  String get spendingImproved;

  /// No description provided for @percentLessThanAverage.
  ///
  /// In en, this message translates to:
  /// **'{percent}% less than average'**
  String percentLessThanAverage(int percent);

  /// No description provided for @spendingIncreased.
  ///
  /// In en, this message translates to:
  /// **'Spending increased'**
  String get spendingIncreased;

  /// No description provided for @percentMoreThanAverage.
  ///
  /// In en, this message translates to:
  /// **'{percent}% more than average'**
  String percentMoreThanAverage(int percent);

  /// No description provided for @featureBankAccounts.
  ///
  /// In en, this message translates to:
  /// **'Bank Accounts'**
  String get featureBankAccounts;

  /// No description provided for @featureBankAccountsDesc.
  ///
  /// In en, this message translates to:
  /// **'Track transactions across multiple bank accounts'**
  String get featureBankAccountsDesc;

  /// No description provided for @featurePaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get featurePaymentMethods;

  /// No description provided for @featurePaymentMethodsDesc.
  ///
  /// In en, this message translates to:
  /// **'Organize expenses by cards, UPI, cash, and more'**
  String get featurePaymentMethodsDesc;

  /// No description provided for @featureSavingsGoals.
  ///
  /// In en, this message translates to:
  /// **'Savings Goals'**
  String get featureSavingsGoals;

  /// No description provided for @featureSavingsGoalsDesc.
  ///
  /// In en, this message translates to:
  /// **'Set and track your savings targets'**
  String get featureSavingsGoalsDesc;

  /// No description provided for @featureBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get featureBudgets;

  /// No description provided for @featureBudgetsDesc.
  ///
  /// In en, this message translates to:
  /// **'Create category budgets with alerts'**
  String get featureBudgetsDesc;

  /// No description provided for @featureRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring Transactions'**
  String get featureRecurring;

  /// No description provided for @featureRecurringDesc.
  ///
  /// In en, this message translates to:
  /// **'Auto-track subscriptions and regular payments'**
  String get featureRecurringDesc;

  /// No description provided for @featureCustomCategories.
  ///
  /// In en, this message translates to:
  /// **'Custom Categories'**
  String get featureCustomCategories;

  /// No description provided for @featureCustomCategoriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Create personalized expense categories'**
  String get featureCustomCategoriesDesc;

  /// No description provided for @featureReceiptScanning.
  ///
  /// In en, this message translates to:
  /// **'Receipt Scanning'**
  String get featureReceiptScanning;

  /// No description provided for @featureReceiptScanningDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan receipts to auto-add expenses'**
  String get featureReceiptScanningDesc;

  /// No description provided for @featureCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get featureCloudSync;

  /// No description provided for @featureCloudSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Backup and sync across devices'**
  String get featureCloudSyncDesc;

  /// No description provided for @featurePdfReports.
  ///
  /// In en, this message translates to:
  /// **'PDF Reports'**
  String get featurePdfReports;

  /// No description provided for @featurePdfReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'Export beautiful financial reports'**
  String get featurePdfReportsDesc;

  /// No description provided for @featureFullExport.
  ///
  /// In en, this message translates to:
  /// **'Full Data Export'**
  String get featureFullExport;

  /// No description provided for @featureFullExportDesc.
  ///
  /// In en, this message translates to:
  /// **'Export all data in CSV format'**
  String get featureFullExportDesc;

  /// No description provided for @featureAdvancedInsights.
  ///
  /// In en, this message translates to:
  /// **'Advanced Insights'**
  String get featureAdvancedInsights;

  /// No description provided for @featureAdvancedInsightsDesc.
  ///
  /// In en, this message translates to:
  /// **'Detailed analytics and trends'**
  String get featureAdvancedInsightsDesc;

  /// No description provided for @featureMultiCurrency.
  ///
  /// In en, this message translates to:
  /// **'Multi-Currency'**
  String get featureMultiCurrency;

  /// No description provided for @featureMultiCurrencyDesc.
  ///
  /// In en, this message translates to:
  /// **'Track expenses in any currency'**
  String get featureMultiCurrencyDesc;

  /// No description provided for @featureWeeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly Summaries'**
  String get featureWeeklySummary;

  /// No description provided for @featureWeeklySummaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive weekly spending insights'**
  String get featureWeeklySummaryDesc;

  /// No description provided for @featureAdFree.
  ///
  /// In en, this message translates to:
  /// **'Ad-Free Experience'**
  String get featureAdFree;

  /// No description provided for @featureAdFreeDesc.
  ///
  /// In en, this message translates to:
  /// **'No ads or interruptions'**
  String get featureAdFreeDesc;

  /// No description provided for @unlockFinancialPotential.
  ///
  /// In en, this message translates to:
  /// **'Unlock Your Financial Potential'**
  String get unlockFinancialPotential;

  /// No description provided for @getUnlimitedAccess.
  ///
  /// In en, this message translates to:
  /// **'Get unlimited access to all premium features'**
  String get getUnlimitedAccess;

  /// No description provided for @chooseYourPlan.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Plan'**
  String get chooseYourPlan;

  /// No description provided for @whatYoullGet.
  ///
  /// In en, this message translates to:
  /// **'What You\'ll Get'**
  String get whatYoullGet;

  /// No description provided for @noAdsEver.
  ///
  /// In en, this message translates to:
  /// **'No Ads, Ever'**
  String get noAdsEver;

  /// No description provided for @noAdsDesc.
  ///
  /// In en, this message translates to:
  /// **'Enjoy a completely ad-free experience'**
  String get noAdsDesc;

  /// No description provided for @prioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority Support'**
  String get prioritySupport;

  /// No description provided for @prioritySupportDesc.
  ///
  /// In en, this message translates to:
  /// **'Get help when you need it'**
  String get prioritySupportDesc;

  /// No description provided for @cancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime. Terms & Privacy Policy apply.'**
  String get cancelAnytime;

  /// No description provided for @inAppPurchasesSoon.
  ///
  /// In en, this message translates to:
  /// **'In-app purchases will be available soon!'**
  String get inAppPurchasesSoon;

  /// No description provided for @savePercentage.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String savePercentage(String percent);

  /// No description provided for @payOnce.
  ///
  /// In en, this message translates to:
  /// **'Pay Once'**
  String get payOnce;

  /// No description provided for @annual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get annual;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @feature.
  ///
  /// In en, this message translates to:
  /// **'Feature'**
  String get feature;

  /// No description provided for @advancedAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Advanced Analytics'**
  String get advancedAnalytics;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get changeEmail;

  /// No description provided for @currentEmail.
  ///
  /// In en, this message translates to:
  /// **'Current Email'**
  String get currentEmail;

  /// No description provided for @newEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'New Email Address'**
  String get newEmailAddress;

  /// No description provided for @sendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Send Verification Email'**
  String get sendVerificationEmail;

  /// No description provided for @important2WayVerificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Important: 2-Way Verification Required'**
  String get important2WayVerificationRequired;

  /// No description provided for @twoWayVerificationMessage.
  ///
  /// In en, this message translates to:
  /// **'You must have access to BOTH your current email AND your new email to complete this change. Confirmation links will be sent to both addresses and you must click both links (in any order) on this device.'**
  String get twoWayVerificationMessage;

  /// No description provided for @afterClickingBothLinks.
  ///
  /// In en, this message translates to:
  /// **'After clicking both confirmation links, you\'ll be redirected back to the app and your email will be updated.'**
  String get afterClickingBothLinks;

  /// No description provided for @failedToChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to change email'**
  String get failedToChangeEmail;

  /// No description provided for @pleaseEnterAnEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter an email address'**
  String get pleaseEnterAnEmailAddress;

  /// No description provided for @pleaseEnterAValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterAValidEmailAddress;

  /// No description provided for @newEmailMustBeDifferent.
  ///
  /// In en, this message translates to:
  /// **'New email must be different from current email'**
  String get newEmailMustBeDifferent;

  /// No description provided for @verificationEmailSentTo.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent to {email}. Please check your inbox and click the link to confirm the change.'**
  String verificationEmailSentTo(String email);

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered in the system. It may be linked to another account or a previous email change. Please use a different email or contact support.'**
  String get emailAlreadyRegistered;

  /// No description provided for @pleaseWaitBeforeRequestingAgain.
  ///
  /// In en, this message translates to:
  /// **'Please wait a few minutes before requesting another email change.'**
  String get pleaseWaitBeforeRequestingAgain;

  /// No description provided for @thisIsAlreadyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'This is already your current email address.'**
  String get thisIsAlreadyYourEmail;

  /// No description provided for @emailAlreadyRegisteredShort.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Please use a different email.'**
  String get emailAlreadyRegisteredShort;

  /// No description provided for @failedToChangeEmailTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to change email. Please try again.'**
  String get failedToChangeEmailTryAgain;

  /// No description provided for @pleaseEnterValidEmailShort.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmailShort;

  /// No description provided for @deletePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Delete Payment Method'**
  String get deletePaymentMethod;

  /// No description provided for @deletePaymentMethodConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String deletePaymentMethodConfirm(String name);

  /// No description provided for @noPaymentMethodsYet.
  ///
  /// In en, this message translates to:
  /// **'No Payment Methods Yet'**
  String get noPaymentMethodsYet;

  /// No description provided for @addPaymentMethodsDesc.
  ///
  /// In en, this message translates to:
  /// **'Add your payment methods to track\nexpenses more accurately.'**
  String get addPaymentMethodsDesc;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @advancedInsights.
  ///
  /// In en, this message translates to:
  /// **'Advanced Insights'**
  String get advancedInsights;

  /// No description provided for @getDetailedAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Get detailed analytics, spending patterns, and financial health scores'**
  String get getDetailedAnalytics;

  /// No description provided for @expensesByCategory.
  ///
  /// In en, this message translates to:
  /// **'Expenses by Category'**
  String get expensesByCategory;

  /// No description provided for @incomeByCategory.
  ///
  /// In en, this message translates to:
  /// **'Income by Category'**
  String get incomeByCategory;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @selectCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories (select multiple)'**
  String get selectCategories;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @comparePayment.
  ///
  /// In en, this message translates to:
  /// **'Compare Payment Methods'**
  String get comparePayment;

  /// No description provided for @compareMerchant.
  ///
  /// In en, this message translates to:
  /// **'Compare Merchants'**
  String get compareMerchant;

  /// No description provided for @compareCategory.
  ///
  /// In en, this message translates to:
  /// **'Compare Categories'**
  String get compareCategory;

  /// No description provided for @selectUpTo4Items.
  ///
  /// In en, this message translates to:
  /// **'Select up to 4 items to compare'**
  String get selectUpTo4Items;

  /// No description provided for @netBankFlow.
  ///
  /// In en, this message translates to:
  /// **'Net Bank Flow'**
  String get netBankFlow;

  /// No description provided for @moneyIn.
  ///
  /// In en, this message translates to:
  /// **'Money In'**
  String get moneyIn;

  /// No description provided for @moneyOut.
  ///
  /// In en, this message translates to:
  /// **'Money Out'**
  String get moneyOut;

  /// No description provided for @accountBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Account Breakdown'**
  String get accountBreakdown;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @showingFilteredResults.
  ///
  /// In en, this message translates to:
  /// **'Showing filtered results'**
  String get showingFilteredResults;

  /// No description provided for @savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get savings;

  /// No description provided for @financialHealth.
  ///
  /// In en, this message translates to:
  /// **'Financial Health'**
  String get financialHealth;

  /// No description provided for @spendingIncreasedVsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Spending increased significantly vs last month.'**
  String get spendingIncreasedVsLastMonth;

  /// No description provided for @savingPercentOfIncome.
  ///
  /// In en, this message translates to:
  /// **'Saving {percent}% of income'**
  String savingPercentOfIncome(int percent);

  /// No description provided for @immediateActionRecommended.
  ///
  /// In en, this message translates to:
  /// **'Immediate action recommended.'**
  String get immediateActionRecommended;

  /// No description provided for @addIncomeExpensesForInsights.
  ///
  /// In en, this message translates to:
  /// **'Add income and expenses for insights.'**
  String get addIncomeExpensesForInsights;

  /// No description provided for @yourFinancesAreHealthy.
  ///
  /// In en, this message translates to:
  /// **'Your finances are healthy.'**
  String get yourFinancesAreHealthy;

  /// No description provided for @avg.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get avg;

  /// No description provided for @peak.
  ///
  /// In en, this message translates to:
  /// **'Peak'**
  String get peak;

  /// No description provided for @tapOnBarsToSeeDailySpending.
  ///
  /// In en, this message translates to:
  /// **'Tap on bars to see daily spending'**
  String get tapOnBarsToSeeDailySpending;

  /// No description provided for @noExpensesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No expenses this month'**
  String get noExpensesThisMonth;

  /// No description provided for @noIncomeThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No income this month'**
  String get noIncomeThisMonth;

  /// No description provided for @selectCategoriesToDisplay.
  ///
  /// In en, this message translates to:
  /// **'Select categories to display:'**
  String get selectCategoriesToDisplay;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get showAll;

  /// No description provided for @moreCategories.
  ///
  /// In en, this message translates to:
  /// **'More ({count})'**
  String moreCategories(int count);

  /// No description provided for @billReminders.
  ///
  /// In en, this message translates to:
  /// **'Bill Reminders'**
  String get billReminders;

  /// No description provided for @getRemindedBeforePaymentsDue.
  ///
  /// In en, this message translates to:
  /// **'Get reminded before recurring payments are due'**
  String get getRemindedBeforePaymentsDue;

  /// No description provided for @remindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get remindMe;

  /// No description provided for @notificationsHelpMessage.
  ///
  /// In en, this message translates to:
  /// **'Notifications help you stay on top of your finances. You can adjust these settings anytime.'**
  String get notificationsHelpMessage;

  /// No description provided for @reminderSetFor.
  ///
  /// In en, this message translates to:
  /// **'Reminder set for {time}'**
  String reminderSetFor(String time);

  /// No description provided for @flowLedgerNeedsNotificationPermission.
  ///
  /// In en, this message translates to:
  /// **'FlowLedger needs notification permission to send you reminders and alerts.\n\nPlease enable notifications to receive:'**
  String get flowLedgerNeedsNotificationPermission;

  /// No description provided for @pleaseEnableNotificationsInSettings.
  ///
  /// In en, this message translates to:
  /// **'Please enable notifications in your device settings'**
  String get pleaseEnableNotificationsInSettings;

  /// No description provided for @testNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotificationTitle;

  /// No description provided for @testNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Great! Notifications are working perfectly. 🎉'**
  String get testNotificationBody;

  /// No description provided for @testNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent!'**
  String get testNotificationSent;

  /// No description provided for @failedToSendNotification.
  ///
  /// In en, this message translates to:
  /// **'Failed to send notification: {error}'**
  String failedToSendNotification(String error);

  /// No description provided for @signOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?\n\nYour local data will remain on this device, but you won\'t be able to sync until you sign back in.'**
  String get signOutMessage;

  /// No description provided for @signedOutSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Signed out successfully'**
  String get signedOutSuccessfully;

  /// No description provided for @birthDateUpdated.
  ///
  /// In en, this message translates to:
  /// **'Birth date updated'**
  String get birthDateUpdated;

  /// No description provided for @passwordUpdatedSuccessfullyShort.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdatedSuccessfullyShort;

  /// No description provided for @accountDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeletedMessage;

  /// No description provided for @failedToDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account'**
  String get failedToDeleteAccount;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// No description provided for @signInToManageProfile.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your profile'**
  String get signInToManageProfile;

  /// No description provided for @editDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Edit Display Name'**
  String get editDisplayName;

  /// No description provided for @newPasswordDifferentError.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from your current password.'**
  String get newPasswordDifferentError;

  /// No description provided for @passwordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Please choose a stronger password.'**
  String get passwordTooWeak;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection and try again.'**
  String get networkError;

  /// No description provided for @failedToChangePasswordGeneric.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password. Please try again.'**
  String get failedToChangePasswordGeneric;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @pleaseEnterAPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseEnterAPassword;

  /// No description provided for @passwordMustBe6Chars.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMustBe6Chars;

  /// No description provided for @pleaseConfirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmYourPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @typeDELETEToDelete.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to permanently delete your account:'**
  String get typeDELETEToDelete;

  /// No description provided for @clearAllDataQuestion.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data?'**
  String get clearAllDataQuestion;

  /// No description provided for @clearAllDataWarning.
  ///
  /// In en, this message translates to:
  /// **'This action will permanently delete all your local data including:'**
  String get clearAllDataWarning;

  /// No description provided for @allTransactions.
  ///
  /// In en, this message translates to:
  /// **'All transactions'**
  String get allTransactions;

  /// No description provided for @bankAccountsPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Bank accounts & payment methods'**
  String get bankAccountsPaymentMethods;

  /// No description provided for @budgetsSavingsGoals.
  ///
  /// In en, this message translates to:
  /// **'Budgets & savings goals'**
  String get budgetsSavingsGoals;

  /// No description provided for @customCategoriesItem.
  ///
  /// In en, this message translates to:
  /// **'Custom categories'**
  String get customCategoriesItem;

  /// No description provided for @recurringTransactionsItem.
  ///
  /// In en, this message translates to:
  /// **'Recurring transactions'**
  String get recurringTransactionsItem;

  /// No description provided for @cloudDataSafeMessage.
  ///
  /// In en, this message translates to:
  /// **'Your cloud data will remain safe. You can restore by syncing again.'**
  String get cloudDataSafeMessage;

  /// No description provided for @localDataDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your local data. Cloud sync is not enabled.'**
  String get localDataDeleteWarning;

  /// No description provided for @actionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone!'**
  String get actionCannotBeUndone;

  /// No description provided for @importCSV.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get importCSV;

  /// No description provided for @aboutFlowLedgerTitle.
  ///
  /// In en, this message translates to:
  /// **'About FlowLedger'**
  String get aboutFlowLedgerTitle;

  /// No description provided for @debugPremiumMode.
  ///
  /// In en, this message translates to:
  /// **'Debug Premium Mode'**
  String get debugPremiumMode;

  /// No description provided for @last3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 Months'**
  String get last3Months;

  /// No description provided for @addIncomeCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Income Category'**
  String get addIncomeCategory;

  /// No description provided for @addExpenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Expense Category'**
  String get addExpenseCategory;

  /// No description provided for @editIncomeCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Income Category'**
  String get editIncomeCategory;

  /// No description provided for @editExpenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense Category'**
  String get editExpenseCategory;

  /// No description provided for @chooseIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose Icon'**
  String get chooseIconLabel;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @changesWillAffectExisting.
  ///
  /// In en, this message translates to:
  /// **'Changes will affect all existing entries with this category'**
  String get changesWillAffectExisting;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @examples.
  ///
  /// In en, this message translates to:
  /// **'Examples'**
  String get examples;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ This will permanently delete:\n\n• Your profile\n• All income records\n• All expense records\n• All bank accounts\n• All payment methods\n• All budgets and goals\n• All recurring transactions\n• All custom categories\n• All merchants\n\nThis action CANNOT be undone!'**
  String get deleteAccountWarning;

  /// No description provided for @welcomeBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBackTitle;

  /// No description provided for @signInToSyncDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your data across devices'**
  String get signInToSyncDataDesc;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @enterYourEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @enterYourPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPasswordHint;

  /// No description provided for @forgotPasswordQuestion.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordQuestion;

  /// No description provided for @signedUpWithGoogleHint.
  ///
  /// In en, this message translates to:
  /// **'Signed up with Google? Skip the form and use the Google button below.'**
  String get signedUpWithGoogleHint;

  /// No description provided for @orContinueWithText.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWithText;

  /// No description provided for @dontHaveAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccountQuestion;

  /// No description provided for @alreadyHaveAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccountQuestion;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountTitle;

  /// No description provided for @signUpToBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign up to backup and sync your data across all your devices'**
  String get signUpToBackupDesc;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @enterYourNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourNameHint;

  /// No description provided for @birthDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Birth Date'**
  String get birthDateLabel;

  /// No description provided for @selectYourBirthDateHint.
  ///
  /// In en, this message translates to:
  /// **'Select your birth date'**
  String get selectYourBirthDateHint;

  /// No description provided for @yearsOld.
  ///
  /// In en, this message translates to:
  /// **'{age} years old'**
  String yearsOld(int age);

  /// No description provided for @createPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get createPasswordHint;

  /// No description provided for @atLeast6Characters.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get atLeast6Characters;

  /// No description provided for @reenterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get reenterPasswordHint;

  /// No description provided for @accountCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Created!'**
  String get accountCreatedTitle;

  /// No description provided for @verificationEmailSentDesc.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification email to your inbox.\n\n1. Check your email\n2. Click \"Confirm your mail\"\n3. Return here and sign in with your credentials\n\nThe verification link may open the app or a web page - either way, your email will be verified!'**
  String get verificationEmailSentDesc;

  /// No description provided for @gotItGoToSignInBtn.
  ///
  /// In en, this message translates to:
  /// **'Got it, go to Sign In'**
  String get gotItGoToSignInBtn;

  /// No description provided for @accountPreviouslyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account Previously Deleted'**
  String get accountPreviouslyDeleted;

  /// No description provided for @reactivateAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Your previous account was deleted but can be reactivated.\n\nTo reactivate your account:\n1. Go to Sign In\n2. Tap \"Forgot Password\"\n3. Reset your password\n4. Sign in with the new password\n\nYour account will be automatically reactivated when you sign in.'**
  String get reactivateAccountDesc;

  /// No description provided for @goToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Go to Sign In'**
  String get goToSignIn;

  /// No description provided for @accountAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Account Already Exists'**
  String get accountAlreadyExists;

  /// No description provided for @accountExistsGoogleHint.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.\n\nIf you signed up with Google before, please use \"Continue with Google\" to sign in.'**
  String get accountExistsGoogleHint;

  /// No description provided for @welcomeBackMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Your account has been reactivated.'**
  String get welcomeBackMessage;

  /// No description provided for @mustBe12YearsOldMessage.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 12 years old to use FlowLedger'**
  String get mustBe12YearsOldMessage;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'No worries! Enter your email and we\'ll send you a link to reset your password.'**
  String get forgotPasswordDesc;

  /// No description provided for @googleAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'Signed up with Google? Password reset won\'t work. Use \"Continue with Google\" on the login page instead.'**
  String get googleAccountWarning;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get backToSignIn;

  /// No description provided for @passwordResetEmailSentMessage.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent!'**
  String get passwordResetEmailSentMessage;

  /// No description provided for @checkYourEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check Your Email'**
  String get checkYourEmailTitle;

  /// No description provided for @passwordResetSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a password reset link to\n{email}'**
  String passwordResetSentTo(String email);

  /// No description provided for @checkYourEmailInbox.
  ///
  /// In en, this message translates to:
  /// **'Check your email inbox'**
  String get checkYourEmailInbox;

  /// No description provided for @clickTheResetLink.
  ///
  /// In en, this message translates to:
  /// **'Click the reset link'**
  String get clickTheResetLink;

  /// No description provided for @createYourNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Create your new password'**
  String get createYourNewPassword;

  /// No description provided for @signInWithNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Sign in with new password'**
  String get signInWithNewPassword;

  /// No description provided for @openEmailOnDeviceWithApp.
  ///
  /// In en, this message translates to:
  /// **'Open the email on a device with FlowLedger installed. The reset link will open in the app.'**
  String get openEmailOnDeviceWithApp;

  /// No description provided for @didntReceiveEmail.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the email? Try again'**
  String get didntReceiveEmail;

  /// No description provided for @createNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get createNewPasswordTitle;

  /// No description provided for @newPasswordMustBeDifferentDesc.
  ///
  /// In en, this message translates to:
  /// **'Your new password must be different from previously used passwords.'**
  String get newPasswordMustBeDifferentDesc;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @enterNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPasswordHint;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPasswordHint;

  /// No description provided for @resetPasswordBtn.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordBtn;

  /// No description provided for @passwordResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Reset!'**
  String get passwordResetTitle;

  /// No description provided for @passwordResetSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Your password has been successfully reset.\nYou can now sign in with your new password.'**
  String get passwordResetSuccessDesc;

  /// No description provided for @continueToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Continue to Sign In'**
  String get continueToSignIn;

  /// No description provided for @newPasswordSameError.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from your current password. Please choose a different password.'**
  String get newPasswordSameError;

  /// No description provided for @resetLinkExpiredError.
  ///
  /// In en, this message translates to:
  /// **'This reset link has expired. Please request a new password reset link.'**
  String get resetLinkExpiredError;

  /// No description provided for @failedToResetPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset password. The link may have expired. Please try again.'**
  String get failedToResetPasswordError;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @followsDeviceSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Follows device settings'**
  String get followsDeviceSettingsDesc;

  /// No description provided for @couldNotEnableAppLockMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not enable App Lock. Please check your device settings.'**
  String get couldNotEnableAppLockMessage;

  /// No description provided for @notSignedInLabel.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedInLabel;

  /// No description provided for @developerOptions.
  ///
  /// In en, this message translates to:
  /// **'DEVELOPER OPTIONS'**
  String get developerOptions;

  /// No description provided for @debugPremiumModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Debug Premium Mode'**
  String get debugPremiumModeLabel;

  /// No description provided for @enabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabledLabel;

  /// No description provided for @disabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabledLabel;

  /// No description provided for @debugModeWarning.
  ///
  /// In en, this message translates to:
  /// **'Debug mode: Premium features unlocked without real purchase'**
  String get debugModeWarning;

  /// No description provided for @deleteAllDataWarningDetails.
  ///
  /// In en, this message translates to:
  /// **'This action will permanently delete all your local data including:'**
  String get deleteAllDataWarningDetails;

  /// No description provided for @allTransactionsItem.
  ///
  /// In en, this message translates to:
  /// **'All transactions'**
  String get allTransactionsItem;

  /// No description provided for @bankAccountsPaymentMethodsItem.
  ///
  /// In en, this message translates to:
  /// **'Bank accounts & payment methods'**
  String get bankAccountsPaymentMethodsItem;

  /// No description provided for @budgetsSavingsGoalsItem.
  ///
  /// In en, this message translates to:
  /// **'Budgets & savings goals'**
  String get budgetsSavingsGoalsItem;

  /// No description provided for @customCategoriesListItem.
  ///
  /// In en, this message translates to:
  /// **'Custom categories'**
  String get customCategoriesListItem;

  /// No description provided for @recurringTransactionsListItem.
  ///
  /// In en, this message translates to:
  /// **'Recurring transactions'**
  String get recurringTransactionsListItem;

  /// No description provided for @deleteAllDataBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllDataBtn;

  /// No description provided for @clearingDataMessage.
  ///
  /// In en, this message translates to:
  /// **'Clearing data...'**
  String get clearingDataMessage;

  /// No description provided for @allLocalDataClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'All local data has been cleared'**
  String get allLocalDataClearedMessage;

  /// No description provided for @errorClearingDataMessage.
  ///
  /// In en, this message translates to:
  /// **'Error clearing data: {error}'**
  String errorClearingDataMessage(String error);

  /// No description provided for @viewPortfolio.
  ///
  /// In en, this message translates to:
  /// **'View Portfolio'**
  String get viewPortfolio;

  /// No description provided for @viewSourceCode.
  ///
  /// In en, this message translates to:
  /// **'View source code and projects'**
  String get viewSourceCode;

  /// No description provided for @forgotPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'No worries! Enter your email and we\'ll send you a link to reset your password.'**
  String get forgotPasswordDescription;

  /// No description provided for @googlePasswordResetWarning.
  ///
  /// In en, this message translates to:
  /// **'Signed up with Google? Password reset won\'t work. Use \"Continue with Google\" on the login page instead.'**
  String get googlePasswordResetWarning;

  /// No description provided for @weSentPasswordResetLink.
  ///
  /// In en, this message translates to:
  /// **'We sent a password reset link to'**
  String get weSentPasswordResetLink;

  /// No description provided for @checkEmailInbox.
  ///
  /// In en, this message translates to:
  /// **'Check your email inbox'**
  String get checkEmailInbox;

  /// No description provided for @clickResetLink.
  ///
  /// In en, this message translates to:
  /// **'Click the reset link'**
  String get clickResetLink;

  /// No description provided for @resetLinkDeviceNote.
  ///
  /// In en, this message translates to:
  /// **'Open the email on a device with FlowLedger installed. The reset link will open in the app.'**
  String get resetLinkDeviceNote;

  /// No description provided for @didntReceiveEmailTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the email? Try again'**
  String get didntReceiveEmailTryAgain;

  /// No description provided for @passwordMustBeDifferent.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from your current password. Please choose a different password.'**
  String get passwordMustBeDifferent;

  /// No description provided for @passwordResetSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Reset!'**
  String get passwordResetSuccessTitle;

  /// No description provided for @passwordResetSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your password has been successfully reset.\nYou can now sign in with your new password.'**
  String get passwordResetSuccessMessage;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @deleteAllCloudData.
  ///
  /// In en, this message translates to:
  /// **'Delete All Cloud Data'**
  String get deleteAllCloudData;

  /// No description provided for @deleteCloudDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete all data from cloud and local storage'**
  String get deleteCloudDataDesc;

  /// No description provided for @deleteCloudDataWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ This will PERMANENTLY delete:\n\n• All transactions from cloud\n• All bank accounts from cloud\n• All payment methods from cloud\n• All budgets and goals from cloud\n• All recurring transactions from cloud\n• All custom categories from cloud\n• All merchants from cloud\n\nLocal data will also be cleared.\n\nThis action CANNOT be undone!'**
  String get deleteCloudDataWarning;

  /// No description provided for @typeDeleteToConfirmCloudData.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to permanently delete all cloud and local data:'**
  String get typeDeleteToConfirmCloudData;

  /// No description provided for @allDataDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'All cloud and local data deleted successfully'**
  String get allDataDeletedSuccessfully;

  /// No description provided for @failedToDeleteCloudData.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete cloud data'**
  String get failedToDeleteCloudData;

  /// No description provided for @errorDeletingData.
  ///
  /// In en, this message translates to:
  /// **'Error deleting data'**
  String get errorDeletingData;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @emailChanged.
  ///
  /// In en, this message translates to:
  /// **'Email Changed!'**
  String get emailChanged;

  /// No description provided for @emailChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your email has been successfully changed to:'**
  String get emailChangedSuccessfully;

  /// No description provided for @yourNewEmail.
  ///
  /// In en, this message translates to:
  /// **'your new email'**
  String get yourNewEmail;

  /// No description provided for @useNewEmailToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Use this email to sign in from now on.'**
  String get useNewEmailToSignIn;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @exportReports.
  ///
  /// In en, this message translates to:
  /// **'Export Reports'**
  String get exportReports;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'DATE RANGE'**
  String get dateRange;

  /// No description provided for @include.
  ///
  /// In en, this message translates to:
  /// **'INCLUDE'**
  String get include;

  /// No description provided for @exportAs.
  ///
  /// In en, this message translates to:
  /// **'EXPORT AS'**
  String get exportAs;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @pdfReport.
  ///
  /// In en, this message translates to:
  /// **'PDF Report'**
  String get pdfReport;

  /// No description provided for @formattedReport.
  ///
  /// In en, this message translates to:
  /// **'Formatted report'**
  String get formattedReport;

  /// No description provided for @csvExport.
  ///
  /// In en, this message translates to:
  /// **'CSV Export'**
  String get csvExport;

  /// No description provided for @spreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet'**
  String get spreadsheet;

  /// No description provided for @exportReady.
  ///
  /// In en, this message translates to:
  /// **'Export Ready'**
  String get exportReady;

  /// No description provided for @reportGeneratedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your report has been generated successfully'**
  String get reportGeneratedSuccessfully;

  /// No description provided for @shareReport.
  ///
  /// In en, this message translates to:
  /// **'Share Report'**
  String get shareReport;

  /// No description provided for @selectAtLeastOneTransactionType.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one transaction type'**
  String get selectAtLeastOneTransactionType;

  /// No description provided for @failedToGeneratePdf.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate PDF: {error}'**
  String failedToGeneratePdf(String error);

  /// No description provided for @failedToGenerateCsv.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate CSV: {error}'**
  String failedToGenerateCsv(String error);

  /// No description provided for @goalsActiveGoals.
  ///
  /// In en, this message translates to:
  /// **'Active Goals'**
  String get goalsActiveGoals;

  /// No description provided for @goalsCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'Completed ({count})'**
  String goalsCompletedCount(int count);

  /// No description provided for @goalsNewGoal.
  ///
  /// In en, this message translates to:
  /// **'New Goal'**
  String get goalsNewGoal;

  /// No description provided for @goalsEmptyStateDesc.
  ///
  /// In en, this message translates to:
  /// **'Create your first goal to start\ntracking your savings progress'**
  String get goalsEmptyStateDesc;

  /// No description provided for @goalsTotalSaved.
  ///
  /// In en, this message translates to:
  /// **'Total Saved'**
  String get goalsTotalSaved;

  /// No description provided for @goalsActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String goalsActiveCount(int count);

  /// No description provided for @goalsTargetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target: {amount}'**
  String goalsTargetAmount(String amount);

  /// No description provided for @goalsOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get goalsOverdue;

  /// No description provided for @goalsDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days}d left'**
  String goalsDaysLeft(int days);

  /// No description provided for @goalsDaysLeftLong.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String goalsDaysLeftLong(int days);

  /// No description provided for @goalsCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get goalsCompletedLabel;

  /// No description provided for @goalsCreateNewGoal.
  ///
  /// In en, this message translates to:
  /// **'Create New Goal'**
  String get goalsCreateNewGoal;

  /// No description provided for @goalsNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Emergency Fund, New Car'**
  String get goalsNameHint;

  /// No description provided for @goalsEnterTargetAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter target amount'**
  String get goalsEnterTargetAmount;

  /// No description provided for @goalsTargetDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Target Date (Optional)'**
  String get goalsTargetDateOptional;

  /// No description provided for @goalsNoDeadlineSet.
  ///
  /// In en, this message translates to:
  /// **'No deadline set'**
  String get goalsNoDeadlineSet;

  /// No description provided for @goalsUpdateGoal.
  ///
  /// In en, this message translates to:
  /// **'Update Goal'**
  String get goalsUpdateGoal;

  /// No description provided for @goalsPleaseEnterGoalName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a goal name'**
  String get goalsPleaseEnterGoalName;

  /// No description provided for @goalsPleaseEnterValidTargetAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid target amount'**
  String get goalsPleaseEnterValidTargetAmount;

  /// No description provided for @goalsAmountSaved.
  ///
  /// In en, this message translates to:
  /// **'{amount} saved'**
  String goalsAmountSaved(String amount);

  /// No description provided for @goalsWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get goalsWithdraw;

  /// No description provided for @goalsAmountToWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Amount to withdraw'**
  String get goalsAmountToWithdraw;

  /// No description provided for @goalsAmountToAdd.
  ///
  /// In en, this message translates to:
  /// **'Amount to add'**
  String get goalsAmountToAdd;

  /// No description provided for @goalsCannotWithdrawMoreThanSaved.
  ///
  /// In en, this message translates to:
  /// **'Cannot withdraw more than saved amount'**
  String get goalsCannotWithdrawMoreThanSaved;

  /// No description provided for @goalsWithdrawnAmount.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn {amount}'**
  String goalsWithdrawnAmount(String amount);

  /// No description provided for @goalsAddedAmount.
  ///
  /// In en, this message translates to:
  /// **'Added {amount}'**
  String goalsAddedAmount(String amount);

  /// No description provided for @goalsCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Goal completed! {name}'**
  String goalsCompletedMessage(String name);

  /// No description provided for @goalsAmountRemaining.
  ///
  /// In en, this message translates to:
  /// **'{amount} remaining'**
  String goalsAmountRemaining(String amount);

  /// No description provided for @goalsCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get goalsCreated;

  /// No description provided for @goalsMilestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get goalsMilestones;

  /// No description provided for @goalsDeleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This cannot be undone.'**
  String goalsDeleteConfirmation(String name);

  /// No description provided for @premiumFeatureExclusiveMessage.
  ///
  /// In en, this message translates to:
  /// **'{feature} is available exclusively for Premium members. Upgrade to unlock all features!'**
  String premiumFeatureExclusiveMessage(String feature);

  /// No description provided for @freeLimitReachedMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the free limit of {limit} {items}. Upgrade to Premium for unlimited access!'**
  String freeLimitReachedMessage(int limit, String items);

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @percentUsed.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String percentUsed(String percent);

  /// No description provided for @noBudgetsFoundFor.
  ///
  /// In en, this message translates to:
  /// **'No budgets found for {month} {year}'**
  String noBudgetsFoundFor(String month, String year);

  /// No description provided for @copyBudgetsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Copy {count} budget(s) from {fromMonth} {fromYear} to {toMonth} {toYear}?'**
  String copyBudgetsConfirm(
    String count,
    String fromMonth,
    String fromYear,
    String toMonth,
    String toYear,
  );

  /// No description provided for @monthlyBudgetCurrency.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget ({currency})'**
  String monthlyBudgetCurrency(String currency);

  /// No description provided for @setTo0ToRemoveBudget.
  ///
  /// In en, this message translates to:
  /// **'Set to 0 or empty to remove budget for this category'**
  String get setTo0ToRemoveBudget;

  /// No description provided for @createNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Create your new password'**
  String get createNewPassword;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseEnterPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @cashPaymentsTracked.
  ///
  /// In en, this message translates to:
  /// **'Cash payments will be tracked without any additional details.'**
  String get cashPaymentsTracked;

  /// No description provided for @lastFourDigitsRequired.
  ///
  /// In en, this message translates to:
  /// **'Last 4 digits are required'**
  String get lastFourDigitsRequired;

  /// No description provided for @enterExactly4Digits.
  ///
  /// In en, this message translates to:
  /// **'Please enter exactly 4 digits'**
  String get enterExactly4Digits;

  /// No description provided for @chequeNumberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Cheque No. 123456'**
  String get chequeNumberHint;

  /// No description provided for @chequeReferenceInfo.
  ///
  /// In en, this message translates to:
  /// **'Enter cheque number or any reference for tracking.'**
  String get chequeReferenceInfo;

  /// No description provided for @privacyNotice.
  ///
  /// In en, this message translates to:
  /// **'FlowLedger stores data locally on your device only. We do not collect or store any sensitive financial information like full card numbers, CVV or bank passwords.'**
  String get privacyNotice;

  /// No description provided for @beforeDueDate.
  ///
  /// In en, this message translates to:
  /// **'before due date'**
  String get beforeDueDate;

  /// No description provided for @oneDay.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get oneDay;

  /// No description provided for @nDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String nDays(int count);

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not Connected'**
  String get notConnected;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced: {time}'**
  String lastSynced(String time);

  /// No description provided for @neverSynced.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get neverSynced;

  /// No description provided for @signInToEnableCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Sign in to enable cloud sync'**
  String get signInToEnableCloudSync;

  /// No description provided for @syncManuallyWithSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync manually with \"Sync Now\"'**
  String get syncManuallyWithSyncNow;

  /// No description provided for @dataEncryptedSecurely.
  ///
  /// In en, this message translates to:
  /// **'Your data is encrypted and securely stored in the cloud. Sync to access it from any device.'**
  String get dataEncryptedSecurely;

  /// No description provided for @signInToBackupData.
  ///
  /// In en, this message translates to:
  /// **'Sign in to backup your data and sync across devices.'**
  String get signInToBackupData;

  /// No description provided for @signInToEnableSync.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Enable Sync'**
  String get signInToEnableSync;

  /// No description provided for @backupDataAccessAnywhere.
  ///
  /// In en, this message translates to:
  /// **'Backup your data and access it from any device'**
  String get backupDataAccessAnywhere;

  /// No description provided for @autoSyncEnabled.
  ///
  /// In en, this message translates to:
  /// **'Auto-sync enabled. Changes will sync automatically.'**
  String get autoSyncEnabled;

  /// No description provided for @autoSyncDisabled.
  ///
  /// In en, this message translates to:
  /// **'Auto-sync disabled. Use \"Sync Now\" to sync manually.'**
  String get autoSyncDisabled;

  /// No description provided for @syncedUpDown.
  ///
  /// In en, this message translates to:
  /// **'Synced {up} up, {down} down'**
  String syncedUpDown(int up, int down);

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// No description provided for @backedUpItems.
  ///
  /// In en, this message translates to:
  /// **'Backed up {count} items'**
  String backedUpItems(int count);

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed'**
  String get backupFailed;

  /// No description provided for @restoreWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ WARNING: This will REPLACE all your local data with data from the cloud.\n\nAny transactions added locally since your last backup will be LOST.\n\nUse \"Sync Now\" instead if you want to merge local and cloud data.'**
  String get restoreWarning;

  /// No description provided for @restoredItems.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} items'**
  String restoredItems(int count);

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get restoreFailed;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String minAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @noExpensesThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No expenses recorded this week. Keep tracking to get insights!'**
  String get noExpensesThisWeek;

  /// No description provided for @tryToSaveAtLeast20.
  ///
  /// In en, this message translates to:
  /// **'Try to save at least 20%'**
  String get tryToSaveAtLeast20;

  /// No description provided for @nRecurringSources.
  ///
  /// In en, this message translates to:
  /// **'{count} recurring source(s)'**
  String nRecurringSources(int count);

  /// No description provided for @nEntries.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String nEntries(int count);

  /// No description provided for @nBudgetsExceeded.
  ///
  /// In en, this message translates to:
  /// **'{count} budget(s) exceeded'**
  String nBudgetsExceeded(int count);

  /// No description provided for @nPurchasesUnder200.
  ///
  /// In en, this message translates to:
  /// **'{count} purchases under ₹200'**
  String nPurchasesUnder200(int count);

  /// No description provided for @cloudSyncPremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync is a PRO Feature'**
  String get cloudSyncPremiumTitle;

  /// No description provided for @cloudSyncPremiumDesc.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to PRO to backup your data securely and access it from any device.'**
  String get cloudSyncPremiumDesc;

  /// No description provided for @backupDesc.
  ///
  /// In en, this message translates to:
  /// **'Securely store all your data'**
  String get backupDesc;

  /// No description provided for @accessAnyDevice.
  ///
  /// In en, this message translates to:
  /// **'Access from Any Device'**
  String get accessAnyDevice;

  /// No description provided for @accessAnyDeviceDesc.
  ///
  /// In en, this message translates to:
  /// **'Sync across all your devices'**
  String get accessAnyDeviceDesc;

  /// No description provided for @autoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto-Sync'**
  String get autoSync;

  /// No description provided for @autoSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Changes sync automatically'**
  String get autoSyncDesc;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get chooseImage;

  /// No description provided for @pdfDocument.
  ///
  /// In en, this message translates to:
  /// **'PDF Document'**
  String get pdfDocument;

  /// No description provided for @selectPdfReceiptOrBill.
  ///
  /// In en, this message translates to:
  /// **'Select a PDF receipt or bill'**
  String get selectPdfReceiptOrBill;

  /// No description provided for @tipsForBestResults.
  ///
  /// In en, this message translates to:
  /// **'Tips for best results:'**
  String get tipsForBestResults;

  /// No description provided for @ensureGoodLighting.
  ///
  /// In en, this message translates to:
  /// **'Ensure good lighting'**
  String get ensureGoodLighting;

  /// No description provided for @keepReceiptFlat.
  ///
  /// In en, this message translates to:
  /// **'Keep the receipt flat'**
  String get keepReceiptFlat;

  /// No description provided for @includeEntireReceipt.
  ///
  /// In en, this message translates to:
  /// **'Include the entire receipt in frame'**
  String get includeEntireReceipt;

  /// No description provided for @containsAds.
  ///
  /// In en, this message translates to:
  /// **'Contains Ads'**
  String get containsAds;

  /// No description provided for @pdfReports.
  ///
  /// In en, this message translates to:
  /// **'PDF Reports'**
  String get pdfReports;

  /// No description provided for @weeklySummaries.
  ///
  /// In en, this message translates to:
  /// **'Weekly Summaries'**
  String get weeklySummaries;

  /// No description provided for @dataExport.
  ///
  /// In en, this message translates to:
  /// **'Data Export'**
  String get dataExport;

  /// No description provided for @dailyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'FlowLedger Reminder'**
  String get dailyReminderTitle;

  /// No description provided for @weeklySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'📊 Your Weekly Summary'**
  String get weeklySummaryTitle;

  /// No description provided for @weeklySummaryReady.
  ///
  /// In en, this message translates to:
  /// **'Your weekly spending report is ready. Tap to see how you did!'**
  String get weeklySummaryReady;

  /// No description provided for @cheekyMsg1.
  ///
  /// In en, this message translates to:
  /// **'Your wallet called. It wants to know where the money went today. 👀'**
  String get cheekyMsg1;

  /// No description provided for @cheekyMsg2.
  ///
  /// In en, this message translates to:
  /// **'Hey big spender! Don\'t forget to log those expenses before they log you out of your savings.'**
  String get cheekyMsg2;

  /// No description provided for @cheekyMsg3.
  ///
  /// In en, this message translates to:
  /// **'Plot twist: Your expenses don\'t track themselves. Time to spill the financial tea! ☕'**
  String get cheekyMsg3;

  /// No description provided for @cheekyMsg4.
  ///
  /// In en, this message translates to:
  /// **'Your future self will thank you for logging today\'s expenses. Your present self might grumble but do it anyway!'**
  String get cheekyMsg4;

  /// No description provided for @cheekyMsg5.
  ///
  /// In en, this message translates to:
  /// **'Money talks but only if you write down what it says. Track those expenses! 💸'**
  String get cheekyMsg5;

  /// No description provided for @cheekyMsg6.
  ///
  /// In en, this message translates to:
  /// **'Remember that coffee? That lunch? Log them before they become financial mysteries!'**
  String get cheekyMsg6;

  /// No description provided for @cheekyMsg7.
  ///
  /// In en, this message translates to:
  /// **'Your budget is playing hide and seek. Time to find where your money went today!'**
  String get cheekyMsg7;

  /// No description provided for @cheekyMsg8.
  ///
  /// In en, this message translates to:
  /// **'Breaking news: Receipts in your pocket don\'t automatically become data. You\'re needed!'**
  String get cheekyMsg8;

  /// No description provided for @cheekyMsg9.
  ///
  /// In en, this message translates to:
  /// **'Hey you! Yes you with the receipts. It\'s expense tracking time! 📝'**
  String get cheekyMsg9;

  /// No description provided for @cheekyMsg10.
  ///
  /// In en, this message translates to:
  /// **'Your bank statement is preparing a surprise. Make sure you\'re ready by logging expenses!'**
  String get cheekyMsg10;

  /// No description provided for @cheekyMsg11.
  ///
  /// In en, this message translates to:
  /// **'Fun fact: People who track expenses are 73% more likely to have money. We made that up but log anyway!'**
  String get cheekyMsg11;

  /// No description provided for @cheekyMsg12.
  ///
  /// In en, this message translates to:
  /// **'Your expenses are waiting like unopened messages. Time to check them! 💬'**
  String get cheekyMsg12;

  /// No description provided for @cheekyMsg13.
  ///
  /// In en, this message translates to:
  /// **'Quick reminder: That small purchase still counts. Log it! 🛍️'**
  String get cheekyMsg13;

  /// No description provided for @cheekyMsg14.
  ///
  /// In en, this message translates to:
  /// **'Your money has been on an adventure today. Care to document the journey?'**
  String get cheekyMsg14;

  /// No description provided for @cheekyMsg15.
  ///
  /// In en, this message translates to:
  /// **'Even the smallest leak can sink a ship. Track those little expenses! ⛵'**
  String get cheekyMsg15;

  /// No description provided for @cheekyMsg16.
  ///
  /// In en, this message translates to:
  /// **'Psst! Your expenses are gossiping about you. Better log them before they spill the beans! 🫘'**
  String get cheekyMsg16;

  /// No description provided for @cheekyMsg17.
  ///
  /// In en, this message translates to:
  /// **'Your money went on a date today. Document where it went! 💕'**
  String get cheekyMsg17;

  /// No description provided for @cheekyMsg18.
  ///
  /// In en, this message translates to:
  /// **'Alert: Untracked expenses detected in your pocket. Capture them now! 🎯'**
  String get cheekyMsg18;

  /// No description provided for @cheekyMsg19.
  ///
  /// In en, this message translates to:
  /// **'Remember when you said I\'ll track it later? It\'s later now. ⏰'**
  String get cheekyMsg19;

  /// No description provided for @cheekyMsg20.
  ///
  /// In en, this message translates to:
  /// **'Your piggy bank is judging you. Show it you\'re responsible! 🐷'**
  String get cheekyMsg20;

  /// No description provided for @normalMsg1.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to log your expenses for today.'**
  String get normalMsg1;

  /// No description provided for @normalMsg2.
  ///
  /// In en, this message translates to:
  /// **'Take a moment to record today\'s spending.'**
  String get normalMsg2;

  /// No description provided for @normalMsg3.
  ///
  /// In en, this message translates to:
  /// **'Time for your daily expense check-in.'**
  String get normalMsg3;

  /// No description provided for @normalMsg4.
  ///
  /// In en, this message translates to:
  /// **'Have you logged your expenses today?'**
  String get normalMsg4;

  /// No description provided for @normalMsg5.
  ///
  /// In en, this message translates to:
  /// **'Keep your finances on track by logging today\'s expenses.'**
  String get normalMsg5;

  /// No description provided for @normalMsg6.
  ///
  /// In en, this message translates to:
  /// **'A quick reminder to update your expense log.'**
  String get normalMsg6;

  /// No description provided for @normalMsg7.
  ///
  /// In en, this message translates to:
  /// **'End your day right by recording your expenses.'**
  String get normalMsg7;

  /// No description provided for @normalMsg8.
  ///
  /// In en, this message translates to:
  /// **'Stay organized and log any spending from today.'**
  String get normalMsg8;

  /// No description provided for @normalMsg9.
  ///
  /// In en, this message translates to:
  /// **'Your daily expense reminder is here.'**
  String get normalMsg9;

  /// No description provided for @normalMsg10.
  ///
  /// In en, this message translates to:
  /// **'Take 2 minutes to log today\'s transactions.'**
  String get normalMsg10;

  /// No description provided for @normalMsg11.
  ///
  /// In en, this message translates to:
  /// **'Financial tracking reminder: Update your expenses.'**
  String get normalMsg11;

  /// No description provided for @normalMsg12.
  ///
  /// In en, this message translates to:
  /// **'Keep your records current by logging today\'s spending.'**
  String get normalMsg12;

  /// No description provided for @budgetExceededTitle.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Budget Exceeded!'**
  String get budgetExceededTitle;

  /// No description provided for @budgetAlmostGoneTitle.
  ///
  /// In en, this message translates to:
  /// **'🔴 Budget Almost Gone!'**
  String get budgetAlmostGoneTitle;

  /// No description provided for @budgetAlertTitleNotif.
  ///
  /// In en, this message translates to:
  /// **'⚡ Budget Alert'**
  String get budgetAlertTitleNotif;

  /// No description provided for @budgetExceededBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve exceeded your {category} budget. Spent ₹{spent} of ₹{budget}'**
  String budgetExceededBody(String category, String spent, String budget);

  /// No description provided for @budgetAlmostGoneBody.
  ///
  /// In en, this message translates to:
  /// **'Only {percentLeft}% left in your {category} budget. ₹{remaining} remaining.'**
  String budgetAlmostGoneBody(
    String category,
    int percentLeft,
    String remaining,
  );

  /// No description provided for @budgetAlertBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used {percentUsed}% of your {category} budget. ₹{remaining} remaining.'**
  String budgetAlertBody(String category, int percentUsed, String remaining);

  /// No description provided for @goalAchievedTitle.
  ///
  /// In en, this message translates to:
  /// **'🎉 Goal Achieved!'**
  String get goalAchievedTitle;

  /// No description provided for @milestoneReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'🏆 Milestone Reached!'**
  String get milestoneReachedTitle;

  /// No description provided for @goalUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'📊 Goal Update'**
  String get goalUpdateTitle;

  /// No description provided for @goalAchievedBody.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You\'ve reached your \"{goalName}\" goal of ₹{amount}!'**
  String goalAchievedBody(String goalName, String amount);

  /// No description provided for @milestoneBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re {percent}% towards your \"{goalName}\" goal. Keep it up!'**
  String milestoneBody(String goalName, int percent);

  /// No description provided for @goalProgressBody.
  ///
  /// In en, this message translates to:
  /// **'\"{goalName}\" is now {percent}% complete. ₹{remaining} to go!'**
  String goalProgressBody(String goalName, int percent, String remaining);

  /// No description provided for @billDueTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'🔔 Bill Due Today!'**
  String get billDueTodayTitle;

  /// No description provided for @billDueTomorrowTitle.
  ///
  /// In en, this message translates to:
  /// **'⏰ Bill Due Tomorrow'**
  String get billDueTomorrowTitle;

  /// No description provided for @upcomingBillTitle.
  ///
  /// In en, this message translates to:
  /// **'📅 Upcoming Bill'**
  String get upcomingBillTitle;

  /// No description provided for @incomeDueTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'🔔 Income Due Today!'**
  String get incomeDueTodayTitle;

  /// No description provided for @incomeDueTomorrowTitle.
  ///
  /// In en, this message translates to:
  /// **'⏰ Income Due Tomorrow'**
  String get incomeDueTomorrowTitle;

  /// No description provided for @upcomingIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'📅 Upcoming Income'**
  String get upcomingIncomeTitle;

  /// No description provided for @billDueTodayBody.
  ///
  /// In en, this message translates to:
  /// **'{name} (₹{amount}) is due today!'**
  String billDueTodayBody(String name, String amount);

  /// No description provided for @billDueTomorrowBody.
  ///
  /// In en, this message translates to:
  /// **'{name} (₹{amount}) is due tomorrow.'**
  String billDueTomorrowBody(String name, String amount);

  /// No description provided for @billDueInDaysBody.
  ///
  /// In en, this message translates to:
  /// **'{name} (₹{amount}) is due in {days} days.'**
  String billDueInDaysBody(String name, String amount, int days);

  /// No description provided for @weeklySummaryGreat1.
  ///
  /// In en, this message translates to:
  /// **'You saved ₹{savings} this week! Your wallet is doing a happy dance! 💃'**
  String weeklySummaryGreat1(String savings);

  /// No description provided for @weeklySummaryGreat2.
  ///
  /// In en, this message translates to:
  /// **'₹{savings} saved! You\'re basically a financial wizard at this point! 🧙'**
  String weeklySummaryGreat2(String savings);

  /// No description provided for @weeklySummaryGreat3.
  ///
  /// In en, this message translates to:
  /// **'Look at you saving ₹{savings}! Your future self just sent a thank you note! 💌'**
  String weeklySummaryGreat3(String savings);

  /// No description provided for @weeklySummaryGreat4.
  ///
  /// In en, this message translates to:
  /// **'₹{savings} in the bank! Who needs a money tree when you\'ve got skills? 🌳'**
  String weeklySummaryGreat4(String savings);

  /// No description provided for @weeklySummaryGood1.
  ///
  /// In en, this message translates to:
  /// **'Earned ₹{income} and spent ₹{expense}. You\'re ₹{savings} richer! 🎉'**
  String weeklySummaryGood1(String income, String expense, String savings);

  /// No description provided for @weeklySummaryGood2.
  ///
  /// In en, this message translates to:
  /// **'This week: +₹{income} in -₹{expense} out. Net win of ₹{savings}! 📈'**
  String weeklySummaryGood2(String income, String expense, String savings);

  /// No description provided for @weeklySummaryGood3.
  ///
  /// In en, this message translates to:
  /// **'₹{savings} saved! Not bad at all. Every rupee counts! 💪'**
  String weeklySummaryGood3(String savings);

  /// No description provided for @weeklySummaryGood4.
  ///
  /// In en, this message translates to:
  /// **'You managed to save ₹{savings} this week. Small wins add up! 🏆'**
  String weeklySummaryGood4(String savings);

  /// No description provided for @weeklySummaryBad1.
  ///
  /// In en, this message translates to:
  /// **'Uh oh! You overspent by ₹{savings}. Time to befriend your piggy bank! 🐷'**
  String weeklySummaryBad1(String savings);

  /// No description provided for @weeklySummaryBad2.
  ///
  /// In en, this message translates to:
  /// **'₹{savings} over budget. Your wallet needs a vacation from you! 🏖️'**
  String weeklySummaryBad2(String savings);

  /// No description provided for @weeklySummaryBad3.
  ///
  /// In en, this message translates to:
  /// **'Overspent by ₹{savings}. Maybe cook at home next week? 🍳'**
  String weeklySummaryBad3(String savings);

  /// No description provided for @weeklySummaryBad4.
  ///
  /// In en, this message translates to:
  /// **'You went ₹{savings} over. Time to channel your inner saver! 💰'**
  String weeklySummaryBad4(String savings);

  /// No description provided for @weeklySummarySlight1.
  ///
  /// In en, this message translates to:
  /// **'Spent ₹{savings} more than you earned. Let\'s turn this around next week! 💪'**
  String weeklySummarySlight1(String savings);

  /// No description provided for @weeklySummarySlight2.
  ///
  /// In en, this message translates to:
  /// **'₹{savings} over but hey it happens! Fresh start next week! 🌅'**
  String weeklySummarySlight2(String savings);

  /// No description provided for @weeklySummarySlight3.
  ///
  /// In en, this message translates to:
  /// **'Slightly over by ₹{savings}. Nothing a good week can\'t fix! 🔧'**
  String weeklySummarySlight3(String savings);

  /// No description provided for @weeklySummarySlight4.
  ///
  /// In en, this message translates to:
  /// **'A tiny ₹{savings} slip. Back on track from Monday! 📅'**
  String weeklySummarySlight4(String savings);

  /// No description provided for @weeklySummaryNormal.
  ///
  /// In en, this message translates to:
  /// **'Income: ₹{income} | Expenses: ₹{expense} | {savedOrOver}: ₹{savings}'**
  String weeklySummaryNormal(
    String income,
    String expense,
    String savedOrOver,
    String savings,
  );

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @linkGoogleAccount.
  ///
  /// In en, this message translates to:
  /// **'Link Google Account'**
  String get linkGoogleAccount;

  /// No description provided for @linkGoogleDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google or email'**
  String get linkGoogleDescription;

  /// No description provided for @googleConnected.
  ///
  /// In en, this message translates to:
  /// **'Google Connected'**
  String get googleConnected;

  /// No description provided for @googleConnectedDescription.
  ///
  /// In en, this message translates to:
  /// **'You can sign in with Google or email'**
  String get googleConnectedDescription;

  /// No description provided for @unlinkGoogleAccount.
  ///
  /// In en, this message translates to:
  /// **'Unlink Google Account?'**
  String get unlinkGoogleAccount;

  /// No description provided for @unlinkGoogleDescription.
  ///
  /// In en, this message translates to:
  /// **'You will no longer be able to sign in with Google. You can still sign in with your email and password.'**
  String get unlinkGoogleDescription;

  /// No description provided for @unlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get unlink;

  /// No description provided for @googleAccountLinked.
  ///
  /// In en, this message translates to:
  /// **'Google account linked successfully!'**
  String get googleAccountLinked;

  /// No description provided for @googleAccountUnlinked.
  ///
  /// In en, this message translates to:
  /// **'Google account unlinked'**
  String get googleAccountUnlinked;

  /// No description provided for @failedToLinkGoogle.
  ///
  /// In en, this message translates to:
  /// **'Failed to link Google account'**
  String get failedToLinkGoogle;

  /// No description provided for @failedToUnlinkGoogle.
  ///
  /// In en, this message translates to:
  /// **'Failed to unlink Google account'**
  String get failedToUnlinkGoogle;

  /// No description provided for @googleEmailMismatch.
  ///
  /// In en, this message translates to:
  /// **'The Google account email does not match your account email. Please use the same email address.'**
  String get googleEmailMismatch;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'it',
    'ja',
    'ko',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
