import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bcl.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fil.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('bcl'),
    Locale('en'),
    Locale('fil'),
  ];

  /// Bottom navigation tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation tab label
  ///
  /// In en, this message translates to:
  /// **'GIS Map'**
  String get navMap;

  /// Bottom navigation tab label
  ///
  /// In en, this message translates to:
  /// **'Nearest Center'**
  String get navNearestCenter;

  /// Bottom navigation tab label
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

  /// Bottom navigation tab label
  ///
  /// In en, this message translates to:
  /// **'Hotlines'**
  String get navHotlines;

  /// Bottom navigation tab label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offlineModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Offline mode'**
  String get offlineModeLabel;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @cached.
  ///
  /// In en, this message translates to:
  /// **'Cached'**
  String get cached;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @freshnessCaution.
  ///
  /// In en, this message translates to:
  /// **'Caution'**
  String get freshnessCaution;

  /// No description provided for @freshnessSavedVerb.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get freshnessSavedVerb;

  /// No description provided for @freshnessLastUpdatedVerb.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get freshnessLastUpdatedVerb;

  /// No description provided for @viewAlertsTooltip.
  ///
  /// In en, this message translates to:
  /// **'View alerts'**
  String get viewAlertsTooltip;

  /// No description provided for @couldNotLoadCenters.
  ///
  /// In en, this message translates to:
  /// **'Could not load centers'**
  String get couldNotLoadCenters;

  /// No description provided for @viewRoute.
  ///
  /// In en, this message translates to:
  /// **'View route'**
  String get viewRoute;

  /// No description provided for @invalidAlertLink.
  ///
  /// In en, this message translates to:
  /// **'That alert link isn\'t valid.'**
  String get invalidAlertLink;

  /// Tooltip on a hotline card's Call button
  ///
  /// In en, this message translates to:
  /// **'Call {number}'**
  String callNumberTooltip(String number);

  /// Tooltip on a hotline card's Copy button
  ///
  /// In en, this message translates to:
  /// **'Copy {number} to clipboard'**
  String copyNumberTooltip(String number);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get directions'**
  String get getDirections;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFilipino.
  ///
  /// In en, this message translates to:
  /// **'Filipino'**
  String get languageFilipino;

  /// No description provided for @languageBikolLigao.
  ///
  /// In en, this message translates to:
  /// **'Bikol (Ligao)'**
  String get languageBikolLigao;

  /// No description provided for @preparingEmergencyInfo.
  ///
  /// In en, this message translates to:
  /// **'Preparing emergency information…'**
  String get preparingEmergencyInfo;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @stayInformedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay informed and prepared.'**
  String get stayInformedSubtitle;

  /// No description provided for @dashboardSummary.
  ///
  /// In en, this message translates to:
  /// **'Dashboard summary'**
  String get dashboardSummary;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @viewAllEvacuationCenters.
  ///
  /// In en, this message translates to:
  /// **'View All Evacuation Centers'**
  String get viewAllEvacuationCenters;

  /// No description provided for @refreshData.
  ///
  /// In en, this message translates to:
  /// **'Refresh Data'**
  String get refreshData;

  /// No description provided for @emergencyHotlines.
  ///
  /// In en, this message translates to:
  /// **'Emergency Hotlines'**
  String get emergencyHotlines;

  /// No description provided for @statEvacuationCenters.
  ///
  /// In en, this message translates to:
  /// **'Evacuation centers'**
  String get statEvacuationCenters;

  /// No description provided for @statPublicAlerts.
  ///
  /// In en, this message translates to:
  /// **'Public alerts'**
  String get statPublicAlerts;

  /// No description provided for @statDataStatus.
  ///
  /// In en, this message translates to:
  /// **'Data status'**
  String get statDataStatus;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @nearestEvacuationCenterHeading.
  ///
  /// In en, this message translates to:
  /// **'Nearest evacuation center'**
  String get nearestEvacuationCenterHeading;

  /// No description provided for @recentAlerts.
  ///
  /// In en, this message translates to:
  /// **'Recent alerts'**
  String get recentAlerts;

  /// No description provided for @safetyTips.
  ///
  /// In en, this message translates to:
  /// **'Safety tips'**
  String get safetyTips;

  /// No description provided for @noActiveAlerts.
  ///
  /// In en, this message translates to:
  /// **'No active alerts'**
  String get noActiveAlerts;

  /// No description provided for @noActiveEmergencyAlerts.
  ///
  /// In en, this message translates to:
  /// **'No active emergency alerts'**
  String get noActiveEmergencyAlerts;

  /// No description provided for @normalMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Ligao City is currently under normal monitoring.'**
  String get normalMonitoring;

  /// No description provided for @liveDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live data is temporarily unavailable'**
  String get liveDataUnavailable;

  /// No description provided for @showingSavedInfo.
  ///
  /// In en, this message translates to:
  /// **'Showing the latest saved information.'**
  String get showingSavedInfo;

  /// No description provided for @nearestCenterUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Nearest center unavailable'**
  String get nearestCenterUnavailable;

  /// No description provided for @enableLocationServices.
  ///
  /// In en, this message translates to:
  /// **'Enable location services or try again later.'**
  String get enableLocationServices;

  /// No description provided for @noNearbyEvacuationCenters.
  ///
  /// In en, this message translates to:
  /// **'No nearby evacuation centers to show yet.'**
  String get noNearbyEvacuationCenters;

  /// No description provided for @youAreViewingLiveData.
  ///
  /// In en, this message translates to:
  /// **'You\'re viewing live data.'**
  String get youAreViewingLiveData;

  /// No description provided for @checkingForAlerts.
  ///
  /// In en, this message translates to:
  /// **'Checking for emergency alerts…'**
  String get checkingForAlerts;

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTitle;

  /// No description provided for @alertDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert details'**
  String get alertDetailsTitle;

  /// No description provided for @noPublicAlerts.
  ///
  /// In en, this message translates to:
  /// **'No public alerts to show yet.'**
  String get noPublicAlerts;

  /// No description provided for @dateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Date unavailable'**
  String get dateUnavailable;

  /// No description provided for @sentBy.
  ///
  /// In en, this message translates to:
  /// **'Sent by'**
  String get sentBy;

  /// No description provided for @sentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to'**
  String get sentTo;

  /// No description provided for @evacuationEvent.
  ///
  /// In en, this message translates to:
  /// **'Evacuation event'**
  String get evacuationEvent;

  /// No description provided for @couldNotLoadAlerts.
  ///
  /// In en, this message translates to:
  /// **'Could not load alerts'**
  String get couldNotLoadAlerts;

  /// No description provided for @newAlertReceived.
  ///
  /// In en, this message translates to:
  /// **'New alert received'**
  String get newAlertReceived;

  /// No description provided for @newAdvisoryReceived.
  ///
  /// In en, this message translates to:
  /// **'New advisory received'**
  String get newAdvisoryReceived;

  /// No description provided for @emergencyAlertReceived.
  ///
  /// In en, this message translates to:
  /// **'Emergency alert received'**
  String get emergencyAlertReceived;

  /// No description provided for @newInformationAlert.
  ///
  /// In en, this message translates to:
  /// **'New information alert'**
  String get newInformationAlert;

  /// No description provided for @allClearUpdateReceived.
  ///
  /// In en, this message translates to:
  /// **'All-clear update received'**
  String get allClearUpdateReceived;

  /// No description provided for @severityMandatory.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get severityMandatory;

  /// No description provided for @severityAdvisory.
  ///
  /// In en, this message translates to:
  /// **'Advisory'**
  String get severityAdvisory;

  /// No description provided for @severityInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get severityInfo;

  /// No description provided for @severityAllClear.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get severityAllClear;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get statusFull;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @statusOnStandby.
  ///
  /// In en, this message translates to:
  /// **'On standby'**
  String get statusOnStandby;

  /// No description provided for @evacuationCentersTitle.
  ///
  /// In en, this message translates to:
  /// **'Evacuation centers'**
  String get evacuationCentersTitle;

  /// No description provided for @noEvacuationCenters.
  ///
  /// In en, this message translates to:
  /// **'No evacuation centers to show yet.'**
  String get noEvacuationCenters;

  /// Count line above the evacuation centers list
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 evacuation center} other{{count} evacuation centers}}'**
  String evacuationCentersCount(int count);

  /// Count line above the alerts list
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 public alert} other{{count} public alerts}}'**
  String publicAlertsCount(int count);

  /// No description provided for @nearestCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearest center'**
  String get nearestCenterTitle;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied.'**
  String get locationPermissionDenied;

  /// No description provided for @locationServicesOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off.'**
  String get locationServicesOff;

  /// No description provided for @locationPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied — enable it in system settings.'**
  String get locationPermanentlyDenied;

  /// No description provided for @couldNotDetermineLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not determine current location.'**
  String get couldNotDetermineLocation;

  /// No description provided for @couldNotLoadNearbyCenters.
  ///
  /// In en, this message translates to:
  /// **'Could not load nearby centers'**
  String get couldNotLoadNearbyCenters;

  /// No description provided for @emergencyHotlinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Hotlines'**
  String get emergencyHotlinesTitle;

  /// No description provided for @hotlinesOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'These numbers are saved on your device and work even without internet.'**
  String get hotlinesOfflineNote;

  /// No description provided for @couldNotOpenDialer.
  ///
  /// In en, this message translates to:
  /// **'Could not open the phone dialer — use Copy Number to dial manually.'**
  String get couldNotOpenDialer;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @weatherNotYetAvailable.
  ///
  /// In en, this message translates to:
  /// **'Weather updates are not yet available in this app.'**
  String get weatherNotYetAvailable;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionOfflineData.
  ///
  /// In en, this message translates to:
  /// **'Offline & Data'**
  String get settingsSectionOfflineData;

  /// No description provided for @settingsOfflineData.
  ///
  /// In en, this message translates to:
  /// **'Offline Data'**
  String get settingsOfflineData;

  /// No description provided for @settingsOfflineDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage saved data for offline access'**
  String get settingsOfflineDataSubtitle;

  /// No description provided for @settingsSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get settingsSyncNow;

  /// No description provided for @settingsSyncButton.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get settingsSyncButton;

  /// No description provided for @settingsSyncNeverRun.
  ///
  /// In en, this message translates to:
  /// **'Not yet synced'**
  String get settingsSyncNeverRun;

  /// No description provided for @settingsConnectivity.
  ///
  /// In en, this message translates to:
  /// **'Connectivity'**
  String get settingsConnectivity;

  /// No description provided for @settingsSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsSectionPreferences;

  /// No description provided for @appAppearance.
  ///
  /// In en, this message translates to:
  /// **'App Appearance'**
  String get appAppearance;

  /// No description provided for @appearanceSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get appearanceSystem;

  /// No description provided for @appearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// No description provided for @settingsSectionStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get settingsSectionStaff;

  /// No description provided for @settingsStaffAccess.
  ///
  /// In en, this message translates to:
  /// **'Staff Access'**
  String get settingsStaffAccess;

  /// No description provided for @settingsStaffAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register families and manage evacuation records'**
  String get settingsStaffAccessSubtitle;

  /// No description provided for @staffDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff Dashboard'**
  String get staffDashboardTitle;

  /// No description provided for @staffDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register families, evacuees, centers, and more'**
  String get staffDashboardSubtitle;

  /// Settings Staff section identity row subtitle, e.g. 'barangay_official · Brgy. Binatagan'
  ///
  /// In en, this message translates to:
  /// **'{role} · Brgy. {barangay}'**
  String staffIdentityWithBarangay(String role, String barangay);

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotifications;

  /// No description provided for @pushNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotificationsTitle;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Not yet available — no notification service is set up on the backend. This currently saves your preference on this device.'**
  String get pushNotificationsSubtitle;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Electronic Ligao Kaligtasan Sistema'**
  String get aboutTagline;

  /// No description provided for @syncCompleted.
  ///
  /// In en, this message translates to:
  /// **'Information updated.'**
  String get syncCompleted;

  /// No description provided for @syncPartialFailure.
  ///
  /// In en, this message translates to:
  /// **'Some information could not be updated. Showing the latest saved data.'**
  String get syncPartialFailure;

  /// No description provided for @offlineDataManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Data Management'**
  String get offlineDataManagementTitle;

  /// No description provided for @offlineDataManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage saved information for offline access'**
  String get offlineDataManagementSubtitle;

  /// No description provided for @couldNotLoadOfflineData.
  ///
  /// In en, this message translates to:
  /// **'Could not load offline data details'**
  String get couldNotLoadOfflineData;

  /// No description provided for @offlineOverviewCachedRecords.
  ///
  /// In en, this message translates to:
  /// **'Cached Records'**
  String get offlineOverviewCachedRecords;

  /// No description provided for @offlineOverviewStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'Storage Used'**
  String get offlineOverviewStorageUsed;

  /// No description provided for @offlineOverviewLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get offlineOverviewLastUpdated;

  /// No description provided for @cachedDataCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Cached Data Categories'**
  String get cachedDataCategoriesTitle;

  /// Record count line on an Offline Data Management category tile
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 cached item} other{{count} cached items}}'**
  String cachedItemsCount(int count);

  /// No description provided for @noSavedDataForCategory.
  ///
  /// In en, this message translates to:
  /// **'No saved data'**
  String get noSavedDataForCategory;

  /// No description provided for @updateAllData.
  ///
  /// In en, this message translates to:
  /// **'Update All Data'**
  String get updateAllData;

  /// No description provided for @clearCachedData.
  ///
  /// In en, this message translates to:
  /// **'Clear Cached Data'**
  String get clearCachedData;

  /// No description provided for @clearCacheDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear saved offline data?'**
  String get clearCacheDialogTitle;

  /// No description provided for @clearCacheDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove saved alerts, evacuation centers, and map information from this device. New information can be downloaded again when internet access is available.'**
  String get clearCacheDialogBody;

  /// No description provided for @clearCacheDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear Data'**
  String get clearCacheDialogConfirm;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Offline data cleared.'**
  String get cacheCleared;

  /// No description provided for @hazardMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Hazard map'**
  String get hazardMapTitle;

  /// No description provided for @noMapData.
  ///
  /// In en, this message translates to:
  /// **'No map data available yet.'**
  String get noMapData;

  /// No description provided for @couldNotLoadMapData.
  ///
  /// In en, this message translates to:
  /// **'Could not load map data'**
  String get couldNotLoadMapData;

  /// No description provided for @legendEvacuationCenter.
  ///
  /// In en, this message translates to:
  /// **'Evacuation center'**
  String get legendEvacuationCenter;

  /// No description provided for @legendHazardArea.
  ///
  /// In en, this message translates to:
  /// **'Hazard area'**
  String get legendHazardArea;

  /// No description provided for @showMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Show my location'**
  String get showMyLocation;

  /// No description provided for @unableToOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Unable to open a maps application on this device.'**
  String get unableToOpenMaps;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing…'**
  String get refreshing;

  /// No description provided for @alertsAndNoticesTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts & Notices'**
  String get alertsAndNoticesTitle;

  /// No description provided for @alertsAndNoticesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time updates for Ligao City'**
  String get alertsAndNoticesSubtitle;

  /// No description provided for @dateGroupToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateGroupToday;

  /// No description provided for @dateGroupYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateGroupYesterday;

  /// Count line above the alerts list when a severity filter is active
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 {severity} alert} other{{count} {severity} alerts}}'**
  String filteredAlertsCount(int count, String severity);

  /// No description provided for @searchAlertsHint.
  ///
  /// In en, this message translates to:
  /// **'Search alerts'**
  String get searchAlertsHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @noAlertsMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No alerts match your search or filter.'**
  String get noAlertsMatchFilter;

  /// No description provided for @sortAlertsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort alerts'**
  String get sortAlertsTooltip;

  /// No description provided for @sortNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortNewestFirst;

  /// No description provided for @sortOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortOldestFirst;

  /// No description provided for @sortBySeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get sortBySeverity;

  /// No description provided for @latestAlertLabel.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latestAlertLabel;

  /// No description provided for @shareAlert.
  ///
  /// In en, this message translates to:
  /// **'Share alert'**
  String get shareAlert;

  /// No description provided for @additionalInformation.
  ///
  /// In en, this message translates to:
  /// **'Additional information'**
  String get additionalInformation;

  /// No description provided for @severityLabel.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severityLabel;

  /// No description provided for @alertTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get alertTypeLabel;

  /// No description provided for @receivedLabel.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get receivedLabel;

  /// No description provided for @viewEvacuationCenters.
  ///
  /// In en, this message translates to:
  /// **'View evacuation centers'**
  String get viewEvacuationCenters;

  /// No description provided for @invalidCenterLink.
  ///
  /// In en, this message translates to:
  /// **'That center link isn\'t valid.'**
  String get invalidCenterLink;

  /// No description provided for @viewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View on map'**
  String get viewOnMap;

  /// No description provided for @refreshLocation.
  ///
  /// In en, this message translates to:
  /// **'Refresh location'**
  String get refreshLocation;

  /// No description provided for @otherNearbyCenters.
  ///
  /// In en, this message translates to:
  /// **'Other nearby centers'**
  String get otherNearbyCenters;

  /// No description provided for @evacuationCentersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find nearby and available centers'**
  String get evacuationCentersSubtitle;

  /// No description provided for @searchCentersHint.
  ///
  /// In en, this message translates to:
  /// **'Search centers'**
  String get searchCentersHint;

  /// No description provided for @searchMyEvacuationCentersHint.
  ///
  /// In en, this message translates to:
  /// **'Search my evacuation centers...'**
  String get searchMyEvacuationCentersHint;

  /// No description provided for @staffCentersCitywideNotice.
  ///
  /// In en, this message translates to:
  /// **'Showing centers citywide so you can help register residents temporarily in your area.'**
  String get staffCentersCitywideNotice;

  /// No description provided for @centersYourBarangaySection.
  ///
  /// In en, this message translates to:
  /// **'Your barangay'**
  String get centersYourBarangaySection;

  /// No description provided for @centersOtherBarangaysSection.
  ///
  /// In en, this message translates to:
  /// **'Other barangays'**
  String get centersOtherBarangaysSection;

  /// No description provided for @noCentersMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No centers match your search or filter.'**
  String get noCentersMatchFilter;

  /// Count line above the evacuation centers list when a status filter is active
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 {status} center} other{{count} {status} centers}}'**
  String filteredCentersCount(int count, String status);

  /// No description provided for @sortCentersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort centers'**
  String get sortCentersTooltip;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortByName;

  /// No description provided for @sortByOccupancy.
  ///
  /// In en, this message translates to:
  /// **'Occupancy'**
  String get sortByOccupancy;

  /// No description provided for @sortByCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get sortByCapacity;

  /// No description provided for @centerDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Center details'**
  String get centerDetailsTitle;

  /// No description provided for @centerNotFound.
  ///
  /// In en, this message translates to:
  /// **'This evacuation center could not be found.'**
  String get centerNotFound;

  /// No description provided for @overviewSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewSectionTitle;

  /// No description provided for @overviewCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get overviewCapacity;

  /// No description provided for @overviewCurrentOccupancy.
  ///
  /// In en, this message translates to:
  /// **'Current occupancy'**
  String get overviewCurrentOccupancy;

  /// No description provided for @overviewAvailableSlots.
  ///
  /// In en, this message translates to:
  /// **'Available slots'**
  String get overviewAvailableSlots;

  /// No description provided for @overviewOccupancyPercent.
  ///
  /// In en, this message translates to:
  /// **'Occupancy'**
  String get overviewOccupancyPercent;

  /// No description provided for @locationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationSectionTitle;

  /// No description provided for @addressUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Address unavailable'**
  String get addressUnavailable;

  /// No description provided for @centerMapLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Map location is not available for this center yet.'**
  String get centerMapLocationUnavailable;

  /// No description provided for @centerPhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No photo available'**
  String get centerPhotoUnavailable;

  /// No description provided for @centerPhotoUnavailableOffline.
  ///
  /// In en, this message translates to:
  /// **'Photo unavailable offline'**
  String get centerPhotoUnavailableOffline;

  /// No description provided for @facilitiesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get facilitiesSectionTitle;

  /// No description provided for @couldNotLoadFacilities.
  ///
  /// In en, this message translates to:
  /// **'Could not load facilities'**
  String get couldNotLoadFacilities;

  /// No description provided for @facilitiesNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Facilities information is not available.'**
  String get facilitiesNotAvailable;

  /// No description provided for @facilityAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get facilityAvailable;

  /// No description provided for @facilityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get facilityUnavailable;

  /// No description provided for @facilityNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get facilityNotRecorded;

  /// Status line for an available facility with a recorded quantity, e.g. '3 available'
  ///
  /// In en, this message translates to:
  /// **'{quantity, plural, =1{1 available} other{{quantity} available}}'**
  String facilityQuantityAvailable(int quantity);

  /// No description provided for @facilityTypeLatrineCompostPit.
  ///
  /// In en, this message translates to:
  /// **'Compost Pit Latrine'**
  String get facilityTypeLatrineCompostPit;

  /// No description provided for @facilityTypeLatrineSealed.
  ///
  /// In en, this message translates to:
  /// **'Sealed Latrine'**
  String get facilityTypeLatrineSealed;

  /// No description provided for @facilityTypeToiletMale.
  ///
  /// In en, this message translates to:
  /// **'Male Toilet'**
  String get facilityTypeToiletMale;

  /// No description provided for @facilityTypeToiletFemale.
  ///
  /// In en, this message translates to:
  /// **'Female Toilet'**
  String get facilityTypeToiletFemale;

  /// No description provided for @facilityTypeToiletCommon.
  ///
  /// In en, this message translates to:
  /// **'Common Toilet'**
  String get facilityTypeToiletCommon;

  /// No description provided for @facilityTypeBathingAreaMale.
  ///
  /// In en, this message translates to:
  /// **'Male Bathing Area'**
  String get facilityTypeBathingAreaMale;

  /// No description provided for @facilityTypeBathingAreaFemale.
  ///
  /// In en, this message translates to:
  /// **'Female Bathing Area'**
  String get facilityTypeBathingAreaFemale;

  /// No description provided for @facilityTypeBathingAreaCommon.
  ///
  /// In en, this message translates to:
  /// **'Common Bathing Area'**
  String get facilityTypeBathingAreaCommon;

  /// No description provided for @facilityTypeHandwashingFacility.
  ///
  /// In en, this message translates to:
  /// **'Handwashing Facility'**
  String get facilityTypeHandwashingFacility;

  /// No description provided for @facilityTypeLaundrySpace.
  ///
  /// In en, this message translates to:
  /// **'Laundry Space'**
  String get facilityTypeLaundrySpace;

  /// No description provided for @facilityTypeWomenFriendlySpace.
  ///
  /// In en, this message translates to:
  /// **'Women-Friendly Space'**
  String get facilityTypeWomenFriendlySpace;

  /// No description provided for @facilityTypeChildFriendlySpace.
  ///
  /// In en, this message translates to:
  /// **'Child-Friendly Space'**
  String get facilityTypeChildFriendlySpace;

  /// No description provided for @facilityTypeHealthFacility.
  ///
  /// In en, this message translates to:
  /// **'Health Facility'**
  String get facilityTypeHealthFacility;

  /// No description provided for @facilityTypePrayerRoom.
  ///
  /// In en, this message translates to:
  /// **'Prayer Room'**
  String get facilityTypePrayerRoom;

  /// No description provided for @facilityTypeCommunityKitchen.
  ///
  /// In en, this message translates to:
  /// **'Community Kitchen'**
  String get facilityTypeCommunityKitchen;

  /// No description provided for @facilityTypeLivestockArea.
  ///
  /// In en, this message translates to:
  /// **'Livestock Area'**
  String get facilityTypeLivestockArea;

  /// No description provided for @facilityTypeCampManagementDesk.
  ///
  /// In en, this message translates to:
  /// **'Camp Management Desk'**
  String get facilityTypeCampManagementDesk;

  /// No description provided for @facilityTypeInfoBoard.
  ///
  /// In en, this message translates to:
  /// **'Info / Help Desk'**
  String get facilityTypeInfoBoard;

  /// No description provided for @facilityTypeStorageArea.
  ///
  /// In en, this message translates to:
  /// **'Storage Area'**
  String get facilityTypeStorageArea;

  /// No description provided for @centerTypeSchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get centerTypeSchool;

  /// No description provided for @centerTypeCoveredCourt.
  ///
  /// In en, this message translates to:
  /// **'Covered Court'**
  String get centerTypeCoveredCourt;

  /// No description provided for @centerTypeChurch.
  ///
  /// In en, this message translates to:
  /// **'Church'**
  String get centerTypeChurch;

  /// No description provided for @centerTypeBarangayHall.
  ///
  /// In en, this message translates to:
  /// **'Barangay Hall'**
  String get centerTypeBarangayHall;

  /// No description provided for @centerTypeGymnasium.
  ///
  /// In en, this message translates to:
  /// **'Gymnasium'**
  String get centerTypeGymnasium;

  /// No description provided for @centerTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get centerTypeOther;

  /// No description provided for @centerNoLocationSet.
  ///
  /// In en, this message translates to:
  /// **'No location set'**
  String get centerNoLocationSet;

  /// No description provided for @centerChooseLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose Location'**
  String get centerChooseLocation;

  /// No description provided for @centerChangeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get centerChangeLocation;

  /// No description provided for @centerPasteCoordinatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Or paste coordinates (lat, long)'**
  String get centerPasteCoordinatesLabel;

  /// No description provided for @centerSetCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get centerSetCoordinates;

  /// No description provided for @centerInvalidCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Invalid latitude or longitude.'**
  String get centerInvalidCoordinates;

  /// No description provided for @centerClearLocation.
  ///
  /// In en, this message translates to:
  /// **'Clear Location'**
  String get centerClearLocation;

  /// No description provided for @centerUseThisLocation.
  ///
  /// In en, this message translates to:
  /// **'Use This Location'**
  String get centerUseThisLocation;

  /// No description provided for @centerSaveWithoutLocation.
  ///
  /// In en, this message translates to:
  /// **'Save Without Location'**
  String get centerSaveWithoutLocation;

  /// No description provided for @centerFieldCapacityFamilies.
  ///
  /// In en, this message translates to:
  /// **'Capacity (Families)'**
  String get centerFieldCapacityFamilies;

  /// No description provided for @centerFieldCampManager.
  ///
  /// In en, this message translates to:
  /// **'Camp Manager'**
  String get centerFieldCampManager;

  /// No description provided for @centerFieldCampManagerName.
  ///
  /// In en, this message translates to:
  /// **'Camp Manager Name'**
  String get centerFieldCampManagerName;

  /// No description provided for @centerFieldCampManagerContact.
  ///
  /// In en, this message translates to:
  /// **'Camp Manager Contact'**
  String get centerFieldCampManagerContact;

  /// No description provided for @centerFieldPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get centerFieldPhoto;

  /// No description provided for @centerFieldName.
  ///
  /// In en, this message translates to:
  /// **'Center Name'**
  String get centerFieldName;

  /// No description provided for @centerFieldType.
  ///
  /// In en, this message translates to:
  /// **'Center Type'**
  String get centerFieldType;

  /// No description provided for @centerFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get centerFieldAddress;

  /// No description provided for @centerFieldStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get centerFieldStatus;

  /// No description provided for @centerFieldBarangay.
  ///
  /// In en, this message translates to:
  /// **'Barangay'**
  String get centerFieldBarangay;

  /// No description provided for @centerBarangayLockedHelper.
  ///
  /// In en, this message translates to:
  /// **'Locked to your assigned barangay'**
  String get centerBarangayLockedHelper;

  /// No description provided for @centerSectionInformation.
  ///
  /// In en, this message translates to:
  /// **'Center Information'**
  String get centerSectionInformation;

  /// No description provided for @centerSectionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get centerSectionLocation;

  /// No description provided for @centerSectionCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get centerSectionCapacity;

  /// No description provided for @centerEditEvacuationCenter.
  ///
  /// In en, this message translates to:
  /// **'Edit Evacuation Center'**
  String get centerEditEvacuationCenter;

  /// No description provided for @centerEditNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'You may only edit evacuation centers you created yourself.'**
  String get centerEditNotAllowed;

  /// No description provided for @centerCreateEvacuationCenter.
  ///
  /// In en, this message translates to:
  /// **'Create Evacuation Center'**
  String get centerCreateEvacuationCenter;

  /// No description provided for @centerSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get centerSaveChanges;

  /// No description provided for @centerCreateSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Evacuation center created successfully.'**
  String get centerCreateSuccessMessage;

  /// No description provided for @centerUpdateSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Evacuation center updated successfully.'**
  String get centerUpdateSuccessMessage;

  /// No description provided for @centerValidationBanner.
  ///
  /// In en, this message translates to:
  /// **'Check the highlighted fields and try again.'**
  String get centerValidationBanner;

  /// No description provided for @centerOfflineRequired.
  ///
  /// In en, this message translates to:
  /// **'Internet connection is required to add or edit evacuation centers.'**
  String get centerOfflineRequired;

  /// No description provided for @centerTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get centerTakePhoto;

  /// No description provided for @centerChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get centerChooseFromGallery;

  /// No description provided for @centerChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose Photo'**
  String get centerChoosePhoto;

  /// No description provided for @centerChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get centerChangePhoto;

  /// No description provided for @centerDiscardDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get centerDiscardDialogTitle;

  /// No description provided for @centerDiscardDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes to this evacuation center. If you leave now, they\'ll be lost.'**
  String get centerDiscardDialogBody;

  /// No description provided for @centerDiscardDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get centerDiscardDialogConfirm;

  /// No description provided for @layersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get layersTooltip;

  /// No description provided for @mapLayersTitle.
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get mapLayersTitle;

  /// No description provided for @mapLegendTitle.
  ///
  /// In en, this message translates to:
  /// **'Map Legend'**
  String get mapLegendTitle;

  /// No description provided for @fitMapTooltip.
  ///
  /// In en, this message translates to:
  /// **'Fit map'**
  String get fitMapTooltip;

  /// No description provided for @showEvacuationCenters.
  ///
  /// In en, this message translates to:
  /// **'Show evacuation centers'**
  String get showEvacuationCenters;

  /// No description provided for @centerStatusLayerLabel.
  ///
  /// In en, this message translates to:
  /// **'Center Status'**
  String get centerStatusLayerLabel;

  /// No description provided for @hazardAreasLabel.
  ///
  /// In en, this message translates to:
  /// **'Hazard Areas'**
  String get hazardAreasLabel;

  /// No description provided for @showHazardAreas.
  ///
  /// In en, this message translates to:
  /// **'Show hazard areas'**
  String get showHazardAreas;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get resetFilters;

  /// No description provided for @yourLocationLegend.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get yourLocationLegend;

  /// No description provided for @hazardTypeFlood.
  ///
  /// In en, this message translates to:
  /// **'Flood'**
  String get hazardTypeFlood;

  /// No description provided for @hazardTypeLandslide.
  ///
  /// In en, this message translates to:
  /// **'Landslide'**
  String get hazardTypeLandslide;

  /// No description provided for @hazardTypeLahar.
  ///
  /// In en, this message translates to:
  /// **'Lahar'**
  String get hazardTypeLahar;

  /// No description provided for @hazardTypeStormSurge.
  ///
  /// In en, this message translates to:
  /// **'Storm surge'**
  String get hazardTypeStormSurge;

  /// No description provided for @hazardTypeVolcanicDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Volcanic danger zone'**
  String get hazardTypeVolcanicDangerZone;

  /// No description provided for @mapBaseLayerLabel.
  ///
  /// In en, this message translates to:
  /// **'Base Map'**
  String get mapBaseLayerLabel;

  /// No description provided for @mapBaseLayerStreet.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get mapBaseLayerStreet;

  /// No description provided for @mapBaseLayerSatellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get mapBaseLayerSatellite;

  /// No description provided for @mapSatelliteOfflineNotice.
  ///
  /// In en, this message translates to:
  /// **'Satellite imagery needs an internet connection — it isn\'t saved for offline use.'**
  String get mapSatelliteOfflineNotice;

  /// No description provided for @mapAttributionOpenStreetMap.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap contributors'**
  String get mapAttributionOpenStreetMap;

  /// No description provided for @mapAttributionEsri.
  ///
  /// In en, this message translates to:
  /// **'Esri World Imagery'**
  String get mapAttributionEsri;

  /// Layers sheet section heading for the online-only MGB flood and landslide susceptibility overlays
  ///
  /// In en, this message translates to:
  /// **'Hazard susceptibility (MGB)'**
  String get hazardOverlaysSectionTitle;

  /// Switch label and legend heading for the MGB flood susceptibility overlay
  ///
  /// In en, this message translates to:
  /// **'Flood susceptibility'**
  String get hazardOverlayFloodName;

  /// Switch label and legend heading for the MGB rain-induced landslide susceptibility overlay
  ///
  /// In en, this message translates to:
  /// **'Rain-induced landslide susceptibility'**
  String get hazardOverlayLandslideName;

  /// Static note under the susceptibility switches in the Layers sheet
  ///
  /// In en, this message translates to:
  /// **'Hazard susceptibility layers need an internet connection — they aren\'t saved for offline use.'**
  String get hazardOverlaysOnlineNotice;

  /// Source, as-of date and caveat shown under the flood susceptibility switch and in the legend
  ///
  /// In en, this message translates to:
  /// **'Flood susceptibility: Mines and Geosciences Bureau via GeoRiskPH (service metadata: as of July 2018). Susceptibility, not a flood forecast.'**
  String get hazardOverlayFloodNote;

  /// Source, date and caveat shown under the landslide susceptibility switch and in the legend
  ///
  /// In en, this message translates to:
  /// **'Rain-induced landslide susceptibility only: Mines and Geosciences Bureau via GeoRiskPH (service metadata: dated 2012). Susceptibility, not a landslide forecast. Lahar is not mapped.'**
  String get hazardOverlayLandslideNote;

  /// Shown in the Layers sheet and Legend when an overlay's tiles keep failing to load
  ///
  /// In en, this message translates to:
  /// **'{layer} could not be loaded from GeoRiskPH right now. Switch it off and on to retry.'**
  String hazardOverlayLoadFailed(String layer);

  /// Map attribution for the susceptibility overlays; tapping opens georisk.gov.ph
  ///
  /// In en, this message translates to:
  /// **'MGB via GeoRiskPH'**
  String get hazardOverlayAttribution;

  /// Dialog title when an optional app update is available
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailableTitle;

  /// Dialog title when the installed version is below the minimum supported build
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequiredTitle;

  /// Dialog headline naming the new version
  ///
  /// In en, this message translates to:
  /// **'Version {version} is ready'**
  String updateVersionReady(String version);

  /// Body text when an update is required
  ///
  /// In en, this message translates to:
  /// **'This version of E-LIKAS is out of date. Please update so your alerts and evacuation information stay accurate.'**
  String get updateRequiredBody;

  /// Download size line in the update dialog
  ///
  /// In en, this message translates to:
  /// **'{size} MB · Wi-Fi recommended'**
  String updateSizeWifi(String size);

  /// Shown when the manifest gives no download size
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi recommended'**
  String get updateWifiRecommended;

  /// Heading above the release notes
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get updateWhatsNew;

  /// Dismiss button in the update dialog
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// Start-download button in the update dialog
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// Progress dialog title
  ///
  /// In en, this message translates to:
  /// **'Downloading update…'**
  String get updateDownloading;

  /// Shown while the SHA-256 is verified
  ///
  /// In en, this message translates to:
  /// **'Checking the download…'**
  String get updateVerifying;

  /// Shown once the file passed verification
  ///
  /// In en, this message translates to:
  /// **'Download verified. Opening the installer…'**
  String get updateReadyToInstall;

  /// Hint about the Android install-unknown-apps permission
  ///
  /// In en, this message translates to:
  /// **'If Android asks you to allow installs from E-LIKAS, turn it on, then come back and tap Install.'**
  String get updateInstallHint;

  /// Re-open the Android installer for the verified file
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get updateInstall;

  /// Cancel the running download
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get updateCancel;

  /// Error dialog title
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailedTitle;

  /// Error dialog body after the automatic retry also failed
  ///
  /// In en, this message translates to:
  /// **'The update could not be downloaded or did not pass the safety check. Check your connection and try again.'**
  String get updateFailedBody;

  /// Retry the download
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get updateTryAgain;

  /// Fall back to downloading the APK in the browser
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get updateOpenInBrowser;

  /// Settings row title
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get settingsCheckForUpdates;

  /// Settings row subtitle with the installed version
  ///
  /// In en, this message translates to:
  /// **'Version {version} (build {build})'**
  String settingsVersionBuild(String version, String build);

  /// Settings row subtitle while a manual check runs
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get updateChecking;

  /// Snackbar after a manual check finds nothing newer
  ///
  /// In en, this message translates to:
  /// **'E-LIKAS is up to date.'**
  String get updateUpToDate;

  /// Snackbar when a manual check fails
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates right now.'**
  String get updateCheckFailed;

  /// No description provided for @normalMonitoringTitle.
  ///
  /// In en, this message translates to:
  /// **'Normal Monitoring'**
  String get normalMonitoringTitle;

  /// No description provided for @viewAlert.
  ///
  /// In en, this message translates to:
  /// **'View Alert'**
  String get viewAlert;

  /// No description provided for @findNearestCenterAction.
  ///
  /// In en, this message translates to:
  /// **'Find Nearest Center'**
  String get findNearestCenterAction;

  /// No description provided for @showingSavedAlertInfo.
  ///
  /// In en, this message translates to:
  /// **'Showing saved alert information'**
  String get showingSavedAlertInfo;

  /// No description provided for @emergencyHotlinesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These are the official emergency services of Ligao City.'**
  String get emergencyHotlinesSubtitle;

  /// No description provided for @hotlineNumberNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get hotlineNumberNotSet;

  /// No description provided for @emergencyCallNowNote.
  ///
  /// In en, this message translates to:
  /// **'For life-threatening emergencies, call the appropriate emergency service immediately.'**
  String get emergencyCallNowNote;

  /// No description provided for @hotlineCategoryNationalEmergency.
  ///
  /// In en, this message translates to:
  /// **'National Emergency'**
  String get hotlineCategoryNationalEmergency;

  /// No description provided for @hotlineCategoryDisasterResponse.
  ///
  /// In en, this message translates to:
  /// **'Disaster Response'**
  String get hotlineCategoryDisasterResponse;

  /// No description provided for @hotlineCategoryFire.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get hotlineCategoryFire;

  /// No description provided for @hotlineCategoryPolice.
  ///
  /// In en, this message translates to:
  /// **'Police'**
  String get hotlineCategoryPolice;

  /// No description provided for @hotlineCategoryRescue.
  ///
  /// In en, this message translates to:
  /// **'Rescue'**
  String get hotlineCategoryRescue;

  /// No description provided for @hotlineCategoryMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get hotlineCategoryMedical;

  /// No description provided for @hotlineCategorySocialWelfare.
  ///
  /// In en, this message translates to:
  /// **'Social Welfare'**
  String get hotlineCategorySocialWelfare;

  /// No description provided for @hotlineCategoryUtility.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get hotlineCategoryUtility;

  /// No description provided for @favoritesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesSectionTitle;

  /// Accessibility label on a hotline card's favorite-star button when not yet favorited
  ///
  /// In en, this message translates to:
  /// **'Add {name} to favorites'**
  String addToFavoritesTooltip(String name);

  /// Accessibility label on a hotline card's favorite-star button when already favorited
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from favorites'**
  String removeFromFavoritesTooltip(String name);

  /// SnackBar shown after copying a hotline's number
  ///
  /// In en, this message translates to:
  /// **'{name}\'s number copied'**
  String numberCopiedFor(String name);

  /// No description provided for @staffLogoutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get staffLogoutDialogTitle;

  /// No description provided for @staffLogoutDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to access staff features.'**
  String get staffLogoutDialogBody;

  /// No description provided for @staffLogoutDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get staffLogoutDialogConfirm;

  /// No description provided for @staffWorkspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff Dashboard'**
  String get staffWorkspaceTitle;

  /// No description provided for @staffWorkspaceRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get staffWorkspaceRoleLabel;

  /// No description provided for @staffWorkspaceBarangayLabel.
  ///
  /// In en, this message translates to:
  /// **'Barangay'**
  String get staffWorkspaceBarangayLabel;

  /// No description provided for @staffWorkspacePendingCount.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get staffWorkspacePendingCount;

  /// No description provided for @staffWorkspaceNeedsAttentionCount.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention'**
  String get staffWorkspaceNeedsAttentionCount;

  /// No description provided for @staffWorkspaceEvacuationCentersSection.
  ///
  /// In en, this message translates to:
  /// **'Evacuation Centers'**
  String get staffWorkspaceEvacuationCentersSection;

  /// No description provided for @staffWorkspaceRecordsSection.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get staffWorkspaceRecordsSection;

  /// No description provided for @staffWorkspaceRegisterFamily.
  ///
  /// In en, this message translates to:
  /// **'Register a Family'**
  String get staffWorkspaceRegisterFamily;

  /// No description provided for @staffWorkspaceRegisterFamilySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Works offline — syncs when you\'re ready'**
  String get staffWorkspaceRegisterFamilySubtitle;

  /// No description provided for @staffWorkspacePendingRegistrations.
  ///
  /// In en, this message translates to:
  /// **'Pending Registrations'**
  String get staffWorkspacePendingRegistrations;

  /// No description provided for @staffWorkspaceAllEvacuees.
  ///
  /// In en, this message translates to:
  /// **'Evacuees'**
  String get staffWorkspaceAllEvacuees;

  /// No description provided for @staffWorkspaceAllEvacueesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Synced families in your area'**
  String get staffWorkspaceAllEvacueesSubtitle;

  /// No description provided for @registeredFamiliesTitle.
  ///
  /// In en, this message translates to:
  /// **'Registered Families'**
  String get registeredFamiliesTitle;

  /// No description provided for @registeredFamiliesWorkspaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This device\'s saved records — synced or not'**
  String get registeredFamiliesWorkspaceSubtitle;

  /// No description provided for @registeredFamiliesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every family record saved on this device, from any barangay. Records from other barangays only appear here — Evacuees shows your own barangay\'s synced roster.'**
  String get registeredFamiliesSubtitle;

  /// No description provided for @registeredFamiliesNotSyncedSection.
  ///
  /// In en, this message translates to:
  /// **'Not yet synced'**
  String get registeredFamiliesNotSyncedSection;

  /// No description provided for @registeredFamiliesSyncedSection.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get registeredFamiliesSyncedSection;

  /// No description provided for @staffWorkspaceSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get staffWorkspaceSyncNow;

  /// No description provided for @staffWorkspaceLogout.
  ///
  /// In en, this message translates to:
  /// **'Staff Logout'**
  String get staffWorkspaceLogout;

  /// No description provided for @staffWorkspaceLogoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Return to the resident-only experience'**
  String get staffWorkspaceLogoutSubtitle;

  /// No description provided for @staffAddEvacuationCenter.
  ///
  /// In en, this message translates to:
  /// **'Add Evacuation Center'**
  String get staffAddEvacuationCenter;

  /// No description provided for @staffAddEvacuationCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Online only — not queued offline'**
  String get staffAddEvacuationCenterSubtitle;

  /// No description provided for @staffManageEvacuationCenters.
  ///
  /// In en, this message translates to:
  /// **'My Evacuation Centers'**
  String get staffManageEvacuationCenters;

  /// No description provided for @staffManageEvacuationCentersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and edit centers you can manage'**
  String get staffManageEvacuationCentersSubtitle;

  /// No description provided for @staffSessionOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'Working from a saved sign-in. Some actions need a connection.'**
  String get staffSessionOfflineBanner;

  /// No description provided for @staffFamiliesEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No families have been registered yet.'**
  String get staffFamiliesEmptyState;

  /// No description provided for @staffFamiliesNoCacheMessage.
  ///
  /// In en, this message translates to:
  /// **'No saved family information yet — connect to the internet at least once to load it.'**
  String get staffFamiliesNoCacheMessage;

  /// No description provided for @staffFamiliesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load registered families.'**
  String get staffFamiliesLoadError;

  /// Freshness caption on the Registered Families list
  ///
  /// In en, this message translates to:
  /// **'Showing data as of {date}'**
  String staffFamiliesShowingAsOf(String date);

  /// No description provided for @staffFamiliesShowingSaved.
  ///
  /// In en, this message translates to:
  /// **'Showing saved data'**
  String get staffFamiliesShowingSaved;

  /// No description provided for @staffFamiliesUnknownBarangay.
  ///
  /// In en, this message translates to:
  /// **'Unknown barangay'**
  String get staffFamiliesUnknownBarangay;

  /// No description provided for @staffFamiliesUnnamedFamily.
  ///
  /// In en, this message translates to:
  /// **'Unnamed family'**
  String get staffFamiliesUnnamedFamily;

  /// Family card/detail subtitle
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String staffFamiliesMemberCount(int count);

  /// Subtitle on the family detail sheet and the duplicate-match warning
  ///
  /// In en, this message translates to:
  /// **'Registered in {barangay}'**
  String staffFamiliesRegisteredIn(String barangay);

  /// No description provided for @staffFamiliesMembersSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get staffFamiliesMembersSectionTitle;

  /// No description provided for @staffSyncStoppedForAuthMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Sign in again to keep syncing.'**
  String get staffSyncStoppedForAuthMessage;

  /// No description provided for @staffSyncRequiresConnectionMessage.
  ///
  /// In en, this message translates to:
  /// **'Sync requires an internet connection.'**
  String get staffSyncRequiresConnectionMessage;

  /// SnackBar shown after a manual Sync Now run completes
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No registrations were synced.} =1{1 registration synced.} other{{count} registrations synced.}}'**
  String staffSyncCompletedMessage(int count);

  /// No description provided for @staffPendingListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending registrations. Everything is synced.'**
  String get staffPendingListEmpty;

  /// No description provided for @staffPendingListError.
  ///
  /// In en, this message translates to:
  /// **'Could not load pending registrations.'**
  String get staffPendingListError;

  /// No description provided for @staffPendingNoHeadName.
  ///
  /// In en, this message translates to:
  /// **'No head of family set'**
  String get staffPendingNoHeadName;

  /// Pending Registrations list row subtitle
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}} • {barangay} • {date}'**
  String staffPendingSubtitle(int count, String barangay, String date);

  /// No description provided for @staffStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get staffStatusPending;

  /// No description provided for @staffStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get staffStatusSyncing;

  /// No description provided for @staffStatusNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention'**
  String get staffStatusNeedsAttention;

  /// No description provided for @staffRegDiscardDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get staffRegDiscardDialogTitle;

  /// No description provided for @staffRegDiscardDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes to this registration. If you leave now, they\'ll be lost.'**
  String get staffRegDiscardDialogBody;

  /// No description provided for @staffRegDiscardDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get staffRegDiscardDialogConfirm;

  /// No description provided for @staffRegExactlyOneHeadError.
  ///
  /// In en, this message translates to:
  /// **'Select exactly one family member as the head of family.'**
  String get staffRegExactlyOneHeadError;

  /// No description provided for @staffRegValidationBanner.
  ///
  /// In en, this message translates to:
  /// **'Check the highlighted fields and try again.'**
  String get staffRegValidationBanner;

  /// No description provided for @staffRegSavedOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved offline. It will sync automatically once you\'re back online.'**
  String get staffRegSavedOfflineMessage;

  /// No description provided for @staffRegSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Family registered successfully.'**
  String get staffRegSuccessMessage;

  /// No description provided for @staffRegAmbiguousMessage.
  ///
  /// In en, this message translates to:
  /// **'The connection dropped while submitting. Saved to Pending Registrations so you can confirm before resubmitting.'**
  String get staffRegAmbiguousMessage;

  /// No description provided for @staffRegisterFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Register a Family'**
  String get staffRegisterFamilyTitle;

  /// No description provided for @staffRegEditRegistrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Registration'**
  String get staffRegEditRegistrationTitle;

  /// No description provided for @staffRegLookupUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available offline. Connect to load this list.'**
  String get staffRegLookupUnavailable;

  /// No description provided for @staffReg4psBeneficiaryLabel.
  ///
  /// In en, this message translates to:
  /// **'4Ps beneficiary family'**
  String get staffReg4psBeneficiaryLabel;

  /// No description provided for @staffRegMembersSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Members'**
  String get staffRegMembersSectionTitle;

  /// No description provided for @staffRegAddMemberButton.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get staffRegAddMemberButton;

  /// No description provided for @staffRegSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Registration'**
  String get staffRegSubmitButton;

  /// No description provided for @staffRegFieldBarangay.
  ///
  /// In en, this message translates to:
  /// **'Barangay'**
  String get staffRegFieldBarangay;

  /// No description provided for @staffRegFieldHomeAddress.
  ///
  /// In en, this message translates to:
  /// **'Street / Sitio Address'**
  String get staffRegFieldHomeAddress;

  /// No description provided for @staffRegFieldHomeAddressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Purok 3, Sitio Mabuhay'**
  String get staffRegFieldHomeAddressHint;

  /// No description provided for @staffRegFieldEvacuationEvent.
  ///
  /// In en, this message translates to:
  /// **'Evacuation Event'**
  String get staffRegFieldEvacuationEvent;

  /// No description provided for @staffRegFieldDisplacementType.
  ///
  /// In en, this message translates to:
  /// **'Displacement Type'**
  String get staffRegFieldDisplacementType;

  /// No description provided for @staffRegDisplacementInsideCenter.
  ///
  /// In en, this message translates to:
  /// **'Inside evacuation center'**
  String get staffRegDisplacementInsideCenter;

  /// No description provided for @staffRegDisplacementOutsideCenter.
  ///
  /// In en, this message translates to:
  /// **'Private house'**
  String get staffRegDisplacementOutsideCenter;

  /// No description provided for @staffRegFieldEvacuationCenter.
  ///
  /// In en, this message translates to:
  /// **'Evacuation Center'**
  String get staffRegFieldEvacuationCenter;

  /// Header on each dynamic member card in the registration form
  ///
  /// In en, this message translates to:
  /// **'Member {number}'**
  String staffRegMemberCardTitle(int number);

  /// No description provided for @staffRegHeadOfFamilyBadge.
  ///
  /// In en, this message translates to:
  /// **'Head of Family'**
  String get staffRegHeadOfFamilyBadge;

  /// No description provided for @staffRegSetAsHead.
  ///
  /// In en, this message translates to:
  /// **'Set as head'**
  String get staffRegSetAsHead;

  /// No description provided for @staffRegRemoveMember.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get staffRegRemoveMember;

  /// No description provided for @staffRegFieldFirstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get staffRegFieldFirstName;

  /// No description provided for @staffRegFieldMiddleName.
  ///
  /// In en, this message translates to:
  /// **'Middle Name'**
  String get staffRegFieldMiddleName;

  /// No description provided for @staffRegFieldLastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get staffRegFieldLastName;

  /// No description provided for @staffRegFieldSuffix.
  ///
  /// In en, this message translates to:
  /// **'Suffix'**
  String get staffRegFieldSuffix;

  /// No description provided for @staffRegFieldSex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get staffRegFieldSex;

  /// No description provided for @staffRegSexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get staffRegSexMale;

  /// No description provided for @staffRegSexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get staffRegSexFemale;

  /// No description provided for @staffRegFieldDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get staffRegFieldDateOfBirth;

  /// No description provided for @staffRegSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get staffRegSelectDate;

  /// No description provided for @staffRegFieldCivilStatus.
  ///
  /// In en, this message translates to:
  /// **'Civil Status'**
  String get staffRegFieldCivilStatus;

  /// No description provided for @staffRegNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get staffRegNotSpecified;

  /// No description provided for @staffRegCivilStatusSingle.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get staffRegCivilStatusSingle;

  /// No description provided for @staffRegCivilStatusMarried.
  ///
  /// In en, this message translates to:
  /// **'Married'**
  String get staffRegCivilStatusMarried;

  /// No description provided for @staffRegCivilStatusWidowed.
  ///
  /// In en, this message translates to:
  /// **'Widowed'**
  String get staffRegCivilStatusWidowed;

  /// No description provided for @staffRegCivilStatusSeparated.
  ///
  /// In en, this message translates to:
  /// **'Separated'**
  String get staffRegCivilStatusSeparated;

  /// No description provided for @staffRegCivilStatusDivorced.
  ///
  /// In en, this message translates to:
  /// **'Divorced'**
  String get staffRegCivilStatusDivorced;

  /// No description provided for @staffRegFieldContactNumber.
  ///
  /// In en, this message translates to:
  /// **'Contact Number'**
  String get staffRegFieldContactNumber;

  /// No description provided for @staffRegContactRequired.
  ///
  /// In en, this message translates to:
  /// **'Contact number is required.'**
  String get staffRegContactRequired;

  /// No description provided for @staffRegContactInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Philippine mobile number (09XXXXXXXXX or +639XXXXXXXXX).'**
  String get staffRegContactInvalid;

  /// No description provided for @staffRegSameAsHead.
  ///
  /// In en, this message translates to:
  /// **'Same as head of family'**
  String get staffRegSameAsHead;

  /// No description provided for @staffRegHeadContactMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter the head of family\'s contact number first.'**
  String get staffRegHeadContactMissing;

  /// No description provided for @staffRegPossibleDuplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Possible existing match'**
  String get staffRegPossibleDuplicateTitle;

  /// No description provided for @staffRegViewRecord.
  ///
  /// In en, this message translates to:
  /// **'View record'**
  String get staffRegViewRecord;

  /// No description provided for @staffRegIsPwd.
  ///
  /// In en, this message translates to:
  /// **'PWD'**
  String get staffRegIsPwd;

  /// No description provided for @staffRegIsPregnant.
  ///
  /// In en, this message translates to:
  /// **'Pregnant'**
  String get staffRegIsPregnant;

  /// No description provided for @staffRegIsLactating.
  ///
  /// In en, this message translates to:
  /// **'Lactating'**
  String get staffRegIsLactating;

  /// No description provided for @staffRegIsSoloParent.
  ///
  /// In en, this message translates to:
  /// **'Solo Parent'**
  String get staffRegIsSoloParent;

  /// No description provided for @staffRegIsIndigenous.
  ///
  /// In en, this message translates to:
  /// **'Indigenous Person'**
  String get staffRegIsIndigenous;

  /// No description provided for @staffRegIs4psMember.
  ///
  /// In en, this message translates to:
  /// **'4Ps Beneficiary'**
  String get staffRegIs4psMember;

  /// No description provided for @staffRegFieldPwdType.
  ///
  /// In en, this message translates to:
  /// **'Type of Disability'**
  String get staffRegFieldPwdType;

  /// No description provided for @staffLoginOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Connect to sign in.'**
  String get staffLoginOfflineTitle;

  /// No description provided for @staffLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff Sign In'**
  String get staffLoginTitle;

  /// No description provided for @staffLoginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email or username'**
  String get staffLoginEmailLabel;

  /// No description provided for @staffLoginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get staffLoginPasswordLabel;

  /// No description provided for @staffLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get staffLoginButton;

  /// No description provided for @staffPendingDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration Details'**
  String get staffPendingDetailTitle;

  /// No description provided for @staffPendingDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'This registration is no longer in the queue. It may have already synced.'**
  String get staffPendingDetailNotFound;

  /// No description provided for @staffPendingDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this registration.'**
  String get staffPendingDetailLoadError;

  /// No description provided for @staffPendingDetailSummarySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get staffPendingDetailSummarySectionTitle;

  /// No description provided for @staffPendingDetailErrorSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention'**
  String get staffPendingDetailErrorSectionTitle;

  /// No description provided for @staffPendingDetailFieldErrorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Fields to review'**
  String get staffPendingDetailFieldErrorsTitle;

  /// Number of sync attempts made for this registration
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attempt} other{{count} attempts}}'**
  String staffPendingDetailAttemptCount(int count);

  /// No description provided for @staffPendingDetailLastAttempt.
  ///
  /// In en, this message translates to:
  /// **'Last attempt: {date}'**
  String staffPendingDetailLastAttempt(String date);

  /// No description provided for @staffPendingDetailCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String staffPendingDetailCreatedAt(String date);

  /// No description provided for @staffPendingDetailUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String staffPendingDetailUpdatedAt(String date);

  /// No description provided for @staffPendingErrorCategoryValidation.
  ///
  /// In en, this message translates to:
  /// **'Needs correction before resubmitting'**
  String get staffPendingErrorCategoryValidation;

  /// No description provided for @staffPendingErrorCategoryForbidden.
  ///
  /// In en, this message translates to:
  /// **'Not permitted for your account'**
  String get staffPendingErrorCategoryForbidden;

  /// No description provided for @staffPendingErrorCategoryAmbiguous.
  ///
  /// In en, this message translates to:
  /// **'Uncertain outcome'**
  String get staffPendingErrorCategoryAmbiguous;

  /// No description provided for @staffPendingErrorCategoryServer.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get staffPendingErrorCategoryServer;

  /// No description provided for @staffPendingAmbiguousHint.
  ///
  /// In en, this message translates to:
  /// **'The server may have already received this registration before the connection dropped. Confirm the family isn\'t already registered before resubmitting, to avoid creating a duplicate.'**
  String get staffPendingAmbiguousHint;

  /// No description provided for @staffPendingDetailReviewButton.
  ///
  /// In en, this message translates to:
  /// **'Review & Resubmit'**
  String get staffPendingDetailReviewButton;

  /// No description provided for @staffPendingDetailEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get staffPendingDetailEditButton;

  /// No description provided for @staffPendingDetailDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get staffPendingDetailDeleteButton;

  /// No description provided for @staffPendingDetailDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this registration?'**
  String get staffPendingDetailDeleteDialogTitle;

  /// No description provided for @staffPendingDetailDeleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This removes it from the offline queue permanently. This cannot be undone.'**
  String get staffPendingDetailDeleteDialogBody;

  /// No description provided for @staffPendingDetailSyncingNotice.
  ///
  /// In en, this message translates to:
  /// **'This registration is currently syncing. Please wait.'**
  String get staffPendingDetailSyncingNotice;

  /// No description provided for @staffPendingDetailDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Registration removed from the queue.'**
  String get staffPendingDetailDeletedMessage;

  /// No description provided for @ecBoardTitle.
  ///
  /// In en, this message translates to:
  /// **'EC Information Board'**
  String get ecBoardTitle;

  /// No description provided for @ecBoardWorkspaceActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add evacuees and view the age/sex breakdown for a center'**
  String get ecBoardWorkspaceActionSubtitle;

  /// No description provided for @ecBoardAddEvacueeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Evacuee'**
  String get ecBoardAddEvacueeTitle;

  /// No description provided for @ecBoardEditEvacueeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Evacuee Entry'**
  String get ecBoardEditEvacueeTitle;

  /// No description provided for @ecBoardEntryDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Evacuee Entry'**
  String get ecBoardEntryDetailTitle;

  /// No description provided for @ecBoardFieldSex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get ecBoardFieldSex;

  /// No description provided for @ecBoardFieldAgeBracket.
  ///
  /// In en, this message translates to:
  /// **'Age group'**
  String get ecBoardFieldAgeBracket;

  /// No description provided for @ecBoardFieldHousehold.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get ecBoardFieldHousehold;

  /// No description provided for @ecBoardHouseholdExisting.
  ///
  /// In en, this message translates to:
  /// **'Already here'**
  String get ecBoardHouseholdExisting;

  /// No description provided for @ecBoardHouseholdNew.
  ///
  /// In en, this message translates to:
  /// **'New family'**
  String get ecBoardHouseholdNew;

  /// No description provided for @ecBoardSelectHouseholdButton.
  ///
  /// In en, this message translates to:
  /// **'Select family'**
  String get ecBoardSelectHouseholdButton;

  /// No description provided for @ecBoardHouseholdSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by head of family name'**
  String get ecBoardHouseholdSearchHint;

  /// No description provided for @ecBoardRefreshHouseholdsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh family list'**
  String get ecBoardRefreshHouseholdsTooltip;

  /// No description provided for @ecBoardHouseholdsUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get ecBoardHouseholdsUpToDate;

  /// No description provided for @ecBoardPendingHouseholdBadge.
  ///
  /// In en, this message translates to:
  /// **'Pending — not yet synced'**
  String get ecBoardPendingHouseholdBadge;

  /// No description provided for @ecBoardPendingNewHouseholdBadge.
  ///
  /// In en, this message translates to:
  /// **'New family from this device — not yet synced'**
  String get ecBoardPendingNewHouseholdBadge;

  /// No description provided for @ecBoardPendingHouseholdNotice.
  ///
  /// In en, this message translates to:
  /// **'This family hasn\'t synced yet. This entry will sync automatically once it does.'**
  String get ecBoardPendingHouseholdNotice;

  /// No description provided for @ecBoardNewHouseholdHeadName.
  ///
  /// In en, this message translates to:
  /// **'Family name'**
  String get ecBoardNewHouseholdHeadName;

  /// No description provided for @ecBoardSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Save Evacuee'**
  String get ecBoardSubmitButton;

  /// No description provided for @ecBoardValidationBanner.
  ///
  /// In en, this message translates to:
  /// **'Please complete sex, age group, and family before saving.'**
  String get ecBoardValidationBanner;

  /// No description provided for @ecBoardSavedOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved offline. It will sync when you\'re back online.'**
  String get ecBoardSavedOfflineMessage;

  /// No description provided for @ecBoardSavedPendingHouseholdMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved — waiting for the selected family to sync first.'**
  String get ecBoardSavedPendingHouseholdMessage;

  /// No description provided for @ecBoardSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Evacuee added successfully.'**
  String get ecBoardSuccessMessage;

  /// No description provided for @ecBoardNoEventsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No open event yet. CSWDO opens an event when a threat is announced.'**
  String get ecBoardNoEventsAvailable;

  /// No description provided for @ecBoardAgeSexSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Age & Sex Disaggregation'**
  String get ecBoardAgeSexSectionTitle;

  /// No description provided for @ecBoardSectoralSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sectoral Group'**
  String get ecBoardSectoralSectionTitle;

  /// No description provided for @ecBoardLastKnownFromCacheNotice.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing the last confirmed figures saved on this device.'**
  String get ecBoardLastKnownFromCacheNotice;

  /// No description provided for @ecBoardUnclassifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not yet classified'**
  String get ecBoardUnclassifiedLabel;

  /// No description provided for @ecBoardPendingSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Added on this device'**
  String get ecBoardPendingSectionTitle;

  /// No description provided for @ecBoardPendingSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Not yet synced, so shown here only — never added into the board\'s figures. Sync Now sends them, with their sectoral details and family answers.'**
  String get ecBoardPendingSectionSubtitle;

  /// No description provided for @ecBoardSyncNowInlineButton.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get ecBoardSyncNowInlineButton;

  /// No description provided for @ecBoardPendingListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending entries on this device.'**
  String get ecBoardPendingListEmpty;

  /// No description provided for @ecBoardTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get ecBoardTotalLabel;

  /// No description provided for @ecBoardBracketInfant.
  ///
  /// In en, this message translates to:
  /// **'Infant (0-6 mo)'**
  String get ecBoardBracketInfant;

  /// No description provided for @ecBoardBracketToddler.
  ///
  /// In en, this message translates to:
  /// **'Toddler (7-24 mo)'**
  String get ecBoardBracketToddler;

  /// No description provided for @ecBoardBracketPreschooler.
  ///
  /// In en, this message translates to:
  /// **'Preschooler'**
  String get ecBoardBracketPreschooler;

  /// No description provided for @ecBoardBracketSchoolAge.
  ///
  /// In en, this message translates to:
  /// **'School Age'**
  String get ecBoardBracketSchoolAge;

  /// No description provided for @ecBoardBracketTeenage.
  ///
  /// In en, this message translates to:
  /// **'Teenage'**
  String get ecBoardBracketTeenage;

  /// No description provided for @ecBoardBracketAdult.
  ///
  /// In en, this message translates to:
  /// **'Adult'**
  String get ecBoardBracketAdult;

  /// No description provided for @ecBoardBracketSeniorCitizen.
  ///
  /// In en, this message translates to:
  /// **'Senior Citizen'**
  String get ecBoardBracketSeniorCitizen;

  /// No description provided for @ecBoardSectoralPwd.
  ///
  /// In en, this message translates to:
  /// **'Persons with Disability'**
  String get ecBoardSectoralPwd;

  /// No description provided for @ecBoardSectoralChildHeadedFamily.
  ///
  /// In en, this message translates to:
  /// **'Child-Headed Family'**
  String get ecBoardSectoralChildHeadedFamily;

  /// No description provided for @ecBoardSectoralSingleHeadedFamily.
  ///
  /// In en, this message translates to:
  /// **'Single-Headed Family'**
  String get ecBoardSectoralSingleHeadedFamily;

  /// No description provided for @ecBoardSectoralSoloParent.
  ///
  /// In en, this message translates to:
  /// **'Solo Parent'**
  String get ecBoardSectoralSoloParent;

  /// No description provided for @ecBoardSectoralPregnantWomen.
  ///
  /// In en, this message translates to:
  /// **'Pregnant Women'**
  String get ecBoardSectoralPregnantWomen;

  /// No description provided for @ecBoardSectoralLactatingMothers.
  ///
  /// In en, this message translates to:
  /// **'Lactating Mothers'**
  String get ecBoardSectoralLactatingMothers;

  /// No description provided for @ecBoardSectoralFourPsBeneficiary.
  ///
  /// In en, this message translates to:
  /// **'4Ps Beneficiary'**
  String get ecBoardSectoralFourPsBeneficiary;

  /// No description provided for @ecBoardSectoralIndigenousPeoples.
  ///
  /// In en, this message translates to:
  /// **'Indigenous Peoples'**
  String get ecBoardSectoralIndigenousPeoples;

  /// Collapsed section on Add Evacuee for optionally tagging this one person's sectoral flags
  ///
  /// In en, this message translates to:
  /// **'Sectoral details (optional)'**
  String get ecBoardSectoralFlagsTitle;

  /// No description provided for @ecBoardSectoralFlagsHelp.
  ///
  /// In en, this message translates to:
  /// **'Tick only what you know. Leaving a box unticked records nothing — it doesn\'t mean \"no\".'**
  String get ecBoardSectoralFlagsHelp;

  /// Badge on the collapsed sectoral section showing how many flags are ticked
  ///
  /// In en, this message translates to:
  /// **'{count} ticked'**
  String ecBoardSectoralFlagsTicked(int count);

  /// No description provided for @ecBoardFourPsBeneficiaryFamilies.
  ///
  /// In en, this message translates to:
  /// **'4Ps Beneficiary Families'**
  String get ecBoardFourPsBeneficiaryFamilies;

  /// No description provided for @ecBoardAddEvacueeIntro.
  ///
  /// In en, this message translates to:
  /// **'Name and birthdate can be added later on the web dashboard\'s Evacuees page.'**
  String get ecBoardAddEvacueeIntro;

  /// No description provided for @ecBoardSectionWhoIsThisPerson.
  ///
  /// In en, this message translates to:
  /// **'Who is this person?'**
  String get ecBoardSectionWhoIsThisPerson;

  /// No description provided for @ecBoardHeadNote.
  ///
  /// In en, this message translates to:
  /// **'This person\'s age and sex will be used for the family head.'**
  String get ecBoardHeadNote;

  /// No description provided for @ecBoardThisPersonIsHead.
  ///
  /// In en, this message translates to:
  /// **'This person is the family head'**
  String get ecBoardThisPersonIsHead;

  /// No description provided for @ecBoardNoHeadLinkedYet.
  ///
  /// In en, this message translates to:
  /// **'This family has no head linked yet.'**
  String get ecBoardNoHeadLinkedYet;

  /// No description provided for @ecBoardSingleHeadedQuestion.
  ///
  /// In en, this message translates to:
  /// **'Only one family head? (single-headed)'**
  String get ecBoardSingleHeadedQuestion;

  /// No description provided for @ecBoardAnswerNotYetKnown.
  ///
  /// In en, this message translates to:
  /// **'Not yet known'**
  String get ecBoardAnswerNotYetKnown;

  /// No description provided for @ecBoardAnswerYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get ecBoardAnswerYes;

  /// No description provided for @ecBoardAnswerNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get ecBoardAnswerNo;

  /// No description provided for @ecBoardAnswerYesUnder18.
  ///
  /// In en, this message translates to:
  /// **'Yes (under 18)'**
  String get ecBoardAnswerYesUnder18;

  /// No description provided for @ecBoardHeadSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'About the actual family head'**
  String get ecBoardHeadSectionTitle;

  /// No description provided for @ecBoardHeadSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Someone other than the person you\'re adding. Used until they\'re added and linked.'**
  String get ecBoardHeadSectionSubtitle;

  /// No description provided for @ecBoardHeadSexLabel.
  ///
  /// In en, this message translates to:
  /// **'Head\'s sex'**
  String get ecBoardHeadSexLabel;

  /// No description provided for @ecBoardHeadIsMinorLabel.
  ///
  /// In en, this message translates to:
  /// **'Head is a minor?'**
  String get ecBoardHeadIsMinorLabel;

  /// No description provided for @ecBoardWillBeRecordedTitle.
  ///
  /// In en, this message translates to:
  /// **'Will be recorded'**
  String get ecBoardWillBeRecordedTitle;

  /// No description provided for @ecBoardSummaryAdding.
  ///
  /// In en, this message translates to:
  /// **'Adding 1 {sex}, {ageGroup}.'**
  String ecBoardSummaryAdding(String sex, String ageGroup);

  /// No description provided for @ecBoardSummaryChooseAgeSex.
  ///
  /// In en, this message translates to:
  /// **'Choose this person\'s age group and sex.'**
  String get ecBoardSummaryChooseAgeSex;

  /// No description provided for @ecBoardSummaryJoinsHousehold.
  ///
  /// In en, this message translates to:
  /// **'Joins the family already here: {household}.'**
  String ecBoardSummaryJoinsHousehold(String household);

  /// No description provided for @ecBoardSummaryChooseHousehold.
  ///
  /// In en, this message translates to:
  /// **'Choose the family this person belongs to.'**
  String get ecBoardSummaryChooseHousehold;

  /// No description provided for @ecBoardSummaryBecomesHead.
  ///
  /// In en, this message translates to:
  /// **'Becomes that family\'s head ({minor}).'**
  String ecBoardSummaryBecomesHead(String minor);

  /// No description provided for @ecBoardSummaryNewHousehold.
  ///
  /// In en, this message translates to:
  /// **'New family: {name}, {barangay}.'**
  String ecBoardSummaryNewHousehold(String name, String barangay);

  /// No description provided for @ecBoardSummaryNoHeadName.
  ///
  /// In en, this message translates to:
  /// **'(family name not entered yet)'**
  String get ecBoardSummaryNoHeadName;

  /// No description provided for @ecBoardSummaryNoBarangay.
  ///
  /// In en, this message translates to:
  /// **'(home barangay not chosen yet)'**
  String get ecBoardSummaryNoBarangay;

  /// No description provided for @ecBoardHomeBarangayLabel.
  ///
  /// In en, this message translates to:
  /// **'Home barangay'**
  String get ecBoardHomeBarangayLabel;

  /// No description provided for @ecBoardHomeBarangayHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the family\'s home barangay...'**
  String get ecBoardHomeBarangayHint;

  /// No description provided for @ecBoardHomeBarangayHelp.
  ///
  /// In en, this message translates to:
  /// **'Where the family lives -- not necessarily where this center is.'**
  String get ecBoardHomeBarangayHelp;

  /// No description provided for @ecBoardHomeBarangaySameAsCenter.
  ///
  /// In en, this message translates to:
  /// **'Same as this center ({barangay})'**
  String ecBoardHomeBarangaySameAsCenter(String barangay);

  /// No description provided for @ecBoardHomeBarangayRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose the family\'s home barangay.'**
  String get ecBoardHomeBarangayRequired;

  /// No description provided for @ecBoardFamilyHereGeneric.
  ///
  /// In en, this message translates to:
  /// **'Family #{id} · {barangay} · {count} here'**
  String ecBoardFamilyHereGeneric(int id, String barangay, int count);

  /// No description provided for @ecBoardFamilyNumber.
  ///
  /// In en, this message translates to:
  /// **'Family #{id}'**
  String ecBoardFamilyNumber(int id);

  /// No description provided for @ecBoardNoFamiliesHere.
  ///
  /// In en, this message translates to:
  /// **'No families here right now.'**
  String get ecBoardNoFamiliesHere;

  /// No description provided for @ecBoardFamiliesHereOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline: showing the families saved on this phone. One that has left this center will be refused when it syncs.'**
  String get ecBoardFamiliesHereOffline;

  /// No description provided for @ecBoardOtherBarangayNote.
  ///
  /// In en, this message translates to:
  /// **'This center is in {barangay}. Add only people who are staying at this center.'**
  String ecBoardOtherBarangayNote(String barangay);

  /// No description provided for @ecBoardEventClosedName.
  ///
  /// In en, this message translates to:
  /// **'{name} (closed)'**
  String ecBoardEventClosedName(String name);

  /// No description provided for @ecBoardClosedEventNote.
  ///
  /// In en, this message translates to:
  /// **'This event is closed. Evacuees can no longer be added to it.'**
  String get ecBoardClosedEventNote;

  /// No description provided for @ecBoardClosedEventWaitingNote.
  ///
  /// In en, this message translates to:
  /// **'Entries still waiting on this phone for it can\'t sync. Check them, then delete them from this phone.'**
  String get ecBoardClosedEventWaitingNote;

  /// No description provided for @ecBoardSummaryHeadIsThisPerson.
  ///
  /// In en, this message translates to:
  /// **'Head: this person ({minor}).'**
  String ecBoardSummaryHeadIsThisPerson(String minor);

  /// No description provided for @ecBoardSummaryHeadIsSomeoneElse.
  ///
  /// In en, this message translates to:
  /// **'Head: someone else, {sex}, {minor}.'**
  String ecBoardSummaryHeadIsSomeoneElse(String sex, String minor);

  /// No description provided for @ecBoardSummarySexNotYetKnown.
  ///
  /// In en, this message translates to:
  /// **'sex not yet known'**
  String get ecBoardSummarySexNotYetKnown;

  /// No description provided for @ecBoardSummaryMinorUnknown.
  ///
  /// In en, this message translates to:
  /// **'minor or not: not yet known'**
  String get ecBoardSummaryMinorUnknown;

  /// No description provided for @ecBoardSummaryMinor.
  ///
  /// In en, this message translates to:
  /// **'a minor'**
  String get ecBoardSummaryMinor;

  /// No description provided for @ecBoardSummaryNotMinor.
  ///
  /// In en, this message translates to:
  /// **'not a minor'**
  String get ecBoardSummaryNotMinor;

  /// No description provided for @ecBoardSummarySingleHeaded.
  ///
  /// In en, this message translates to:
  /// **'Single-headed: {answer}.'**
  String ecBoardSummarySingleHeaded(String answer);

  /// No description provided for @ecBoardSummaryAnswerUnknown.
  ///
  /// In en, this message translates to:
  /// **'not yet known'**
  String get ecBoardSummaryAnswerUnknown;

  /// No description provided for @ecBoardSummaryAnswerYes.
  ///
  /// In en, this message translates to:
  /// **'yes'**
  String get ecBoardSummaryAnswerYes;

  /// No description provided for @ecBoardSummaryAnswerNo.
  ///
  /// In en, this message translates to:
  /// **'no'**
  String get ecBoardSummaryAnswerNo;

  /// No description provided for @ecBoardSummaryMale.
  ///
  /// In en, this message translates to:
  /// **'male'**
  String get ecBoardSummaryMale;

  /// No description provided for @ecBoardSummaryFemale.
  ///
  /// In en, this message translates to:
  /// **'female'**
  String get ecBoardSummaryFemale;

  /// No description provided for @ecBoardSummarySectoral.
  ///
  /// In en, this message translates to:
  /// **'Sectoral: {flags}.'**
  String ecBoardSummarySectoral(String flags);

  /// No description provided for @ecBoardSummaryNoSectoral.
  ///
  /// In en, this message translates to:
  /// **'No sectoral details.'**
  String get ecBoardSummaryNoSectoral;

  /// No description provided for @ecBoardSectoralLiveExplanation.
  ///
  /// In en, this message translates to:
  /// **'Counted from each evacuee\'s sectoral details. Child- and single-headed families are counted once per family, by the head\'s sex, from the answers given when the family was added.'**
  String get ecBoardSectoralLiveExplanation;

  /// No description provided for @familyMemberDetailsPending.
  ///
  /// In en, this message translates to:
  /// **'Member {index} — details pending'**
  String familyMemberDetailsPending(int index);

  /// No description provided for @familyMemberCheckedInAt.
  ///
  /// In en, this message translates to:
  /// **'Checked in at {center}'**
  String familyMemberCheckedInAt(String center);

  /// No description provided for @familyMemberCheckedInUnspecified.
  ///
  /// In en, this message translates to:
  /// **'Checked in at unspecified location'**
  String get familyMemberCheckedInUnspecified;

  /// No description provided for @familyMemberCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'Checked out'**
  String get familyMemberCheckedOut;

  /// No description provided for @familyMembersNeedConnection.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to see who\'s still checked in and to check someone out.'**
  String get familyMembersNeedConnection;

  /// No description provided for @familyHeadNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Head not yet linked. Counts use the answers given for the head ({answers}) until a member is linked. When the head arrives, add them with Add Evacuee → Already here and tick \"This person is the family head\".'**
  String familyHeadNotLinked(String answers);

  /// No description provided for @familyHeadNotLinkedNothingKnown.
  ///
  /// In en, this message translates to:
  /// **'Head not yet linked. Nothing is known about the head yet until a member is linked. When the head arrives, add them with Add Evacuee → Already here and tick \"This person is the family head\".'**
  String get familyHeadNotLinkedNothingKnown;

  /// No description provided for @familyLegacyBulkEntryNotice.
  ///
  /// In en, this message translates to:
  /// **'Legacy bulk entry — needs manual review. Anonymous people from an old headcount, not a real family.'**
  String get familyLegacyBulkEntryNotice;

  /// No description provided for @checkOutButton.
  ///
  /// In en, this message translates to:
  /// **'Check out'**
  String get checkOutButton;

  /// No description provided for @checkOutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Check out {name}'**
  String checkOutDialogTitle(String name);

  /// No description provided for @checkOutDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Closes their stay at {center}, so they no longer count as here now.'**
  String checkOutDialogSubtitle(String center);

  /// No description provided for @checkOutTheirCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'their current location'**
  String get checkOutTheirCurrentLocation;

  /// No description provided for @checkOutReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get checkOutReasonLabel;

  /// No description provided for @checkOutReturnedHome.
  ///
  /// In en, this message translates to:
  /// **'Returned home'**
  String get checkOutReturnedHome;

  /// No description provided for @checkOutTransferred.
  ///
  /// In en, this message translates to:
  /// **'Transferred elsewhere'**
  String get checkOutTransferred;

  /// No description provided for @checkOutReturnedHomeLower.
  ///
  /// In en, this message translates to:
  /// **'returned home'**
  String get checkOutReturnedHomeLower;

  /// No description provided for @checkOutTransferredLower.
  ///
  /// In en, this message translates to:
  /// **'transferred elsewhere'**
  String get checkOutTransferredLower;

  /// No description provided for @checkOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Check out {name} as {reason}? They\'ll no longer count as here now.'**
  String checkOutConfirm(String name, String reason);

  /// No description provided for @checkOutMemberPendingName.
  ///
  /// In en, this message translates to:
  /// **'Member {index} (details pending)'**
  String checkOutMemberPendingName(int index);

  /// No description provided for @checkOutSucceeded.
  ///
  /// In en, this message translates to:
  /// **'{name} checked out.'**
  String checkOutSucceeded(String name);

  /// No description provided for @checkOutOther.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get checkOutOther;

  /// No description provided for @checkOutOtherLower.
  ///
  /// In en, this message translates to:
  /// **'departed for another reason'**
  String get checkOutOtherLower;

  /// No description provided for @markFamilyDepartedButton.
  ///
  /// In en, this message translates to:
  /// **'Mark family as departed'**
  String get markFamilyDepartedButton;

  /// No description provided for @markFamilyDepartedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Checks out everyone ticked, with one reason for all of them. Members already checked out aren\'t listed.'**
  String get markFamilyDepartedSubtitle;

  /// No description provided for @markFamilyDepartedWho.
  ///
  /// In en, this message translates to:
  /// **'Who is leaving'**
  String get markFamilyDepartedWho;

  /// No description provided for @markFamilyDepartedReasonHelp.
  ///
  /// In en, this message translates to:
  /// **'Applies to everyone ticked above.'**
  String get markFamilyDepartedReasonHelp;

  /// No description provided for @markFamilyDepartedSubmit.
  ///
  /// In en, this message translates to:
  /// **'Mark {count} as departed'**
  String markFamilyDepartedSubmit(int count);

  /// No description provided for @markFamilyDepartedConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Mark 1 member as departed?} other{Mark {count} members as departed?}}'**
  String markFamilyDepartedConfirmTitle(int count);

  /// No description provided for @markFamilyDepartedConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'They\'ll be recorded as {reason} and no longer count as here now.'**
  String markFamilyDepartedConfirmMessage(String reason);

  /// No description provided for @markFamilyDepartedConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Mark as departed'**
  String get markFamilyDepartedConfirmButton;

  /// No description provided for @markFamilyDepartedWorking.
  ///
  /// In en, this message translates to:
  /// **'Marking…'**
  String get markFamilyDepartedWorking;

  /// No description provided for @markFamilyDepartedDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member marked as departed.} other{{count} members marked as departed.}}'**
  String markFamilyDepartedDone(int count);

  /// No description provided for @markFamilyDepartedPartialTitle.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} marked as departed'**
  String markFamilyDepartedPartialTitle(int done, int total);

  /// No description provided for @markFamilyDepartedPartialBody.
  ///
  /// In en, this message translates to:
  /// **'These weren\'t checked out:'**
  String get markFamilyDepartedPartialBody;

  /// No description provided for @ecBoardHeaderCenter.
  ///
  /// In en, this message translates to:
  /// **'Evacuation center'**
  String get ecBoardHeaderCenter;

  /// No description provided for @ecBoardAsOf.
  ///
  /// In en, this message translates to:
  /// **'As of'**
  String get ecBoardAsOf;

  /// No description provided for @ecBoardAsOfNotYetFetched.
  ///
  /// In en, this message translates to:
  /// **'Not yet fetched'**
  String get ecBoardAsOfNotYetFetched;

  /// No description provided for @ecBoardNotYetFetchedHelp.
  ///
  /// In en, this message translates to:
  /// **'This board hasn\'t been loaded on this device yet, so every figure shows a dash. Connect to the internet and try again.'**
  String get ecBoardNotYetFetchedHelp;

  /// No description provided for @ecBoardHeaderFamilies.
  ///
  /// In en, this message translates to:
  /// **'Families (Cum/Now)'**
  String get ecBoardHeaderFamilies;

  /// No description provided for @ecBoardHeaderPersons.
  ///
  /// In en, this message translates to:
  /// **'Persons (Cum/Now)'**
  String get ecBoardHeaderPersons;

  /// No description provided for @staffUseTheWebTitle.
  ///
  /// In en, this message translates to:
  /// **'Use the web'**
  String get staffUseTheWebTitle;

  /// No description provided for @staffUseTheWebBody.
  ///
  /// In en, this message translates to:
  /// **'Administrator accounts manage users, logs and backups on the E-LIKAS website. The mobile app is for barangay field work and CSWD monitoring.'**
  String get staffUseTheWebBody;

  /// No description provided for @staffOpenWebsite.
  ///
  /// In en, this message translates to:
  /// **'Open the E-LIKAS website'**
  String get staffOpenWebsite;

  /// No description provided for @staffSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get staffSignOut;

  /// No description provided for @centerApprovalUnverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get centerApprovalUnverified;

  /// No description provided for @centerApprovalRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get centerApprovalRejected;

  /// No description provided for @centerApprovalEditWaiting.
  ///
  /// In en, this message translates to:
  /// **'Edit waiting for CSWD'**
  String get centerApprovalEditWaiting;

  /// No description provided for @centerRejectedNotUsable.
  ///
  /// In en, this message translates to:
  /// **'Rejected by CSWD. Not usable on the EC Board.'**
  String get centerRejectedNotUsable;

  /// No description provided for @staffOwnCentersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No evacuation centers in your barangay yet'**
  String get staffOwnCentersEmpty;

  /// No description provided for @residentBarangayTitle.
  ///
  /// In en, this message translates to:
  /// **'Your barangay'**
  String get residentBarangayTitle;

  /// No description provided for @residentBarangayNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not chosen yet'**
  String get residentBarangayNotSet;

  /// No description provided for @residentBarangayPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your barangay'**
  String get residentBarangayPickerTitle;

  /// No description provided for @residentBarangaySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search barangays'**
  String get residentBarangaySearchHint;

  /// No description provided for @residentBarangayListUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The barangay list needs an internet connection the first time.'**
  String get residentBarangayListUnavailable;

  /// No description provided for @residentBarangayWhy.
  ///
  /// In en, this message translates to:
  /// **'See your barangay\'s status and its evacuation centers first.'**
  String get residentBarangayWhy;

  /// No description provided for @residentBarangayStatusOf.
  ///
  /// In en, this message translates to:
  /// **'Brgy. {barangay}'**
  String residentBarangayStatusOf(Object barangay);

  /// No description provided for @residentNoOpenEvent.
  ///
  /// In en, this message translates to:
  /// **'No disaster event is open.'**
  String get residentNoOpenEvent;

  /// No description provided for @residentStatusSavedCopy.
  ///
  /// In en, this message translates to:
  /// **'As of {age}'**
  String residentStatusSavedCopy(Object age);

  /// No description provided for @showBarangayStatus.
  ///
  /// In en, this message translates to:
  /// **'Barangay status'**
  String get showBarangayStatus;

  /// No description provided for @barangayBoundariesAttribution.
  ///
  /// In en, this message translates to:
  /// **'Barangay boundaries: PSA-NAMRIA via HDX (CC BY-IGO)'**
  String get barangayBoundariesAttribution;

  /// No description provided for @barangayStatusTapped.
  ///
  /// In en, this message translates to:
  /// **'{barangay}: {status}'**
  String barangayStatusTapped(Object barangay, Object status);

  /// No description provided for @centersInYourBarangay.
  ///
  /// In en, this message translates to:
  /// **'Centers in Brgy. {barangay}'**
  String centersInYourBarangay(Object barangay);

  /// No description provided for @centerNoMapLocationYet.
  ///
  /// In en, this message translates to:
  /// **'No map location yet. Ask your barangay for directions.'**
  String get centerNoMapLocationYet;

  /// No description provided for @staffTabCenters.
  ///
  /// In en, this message translates to:
  /// **'Centers'**
  String get staffTabCenters;

  /// No description provided for @staffTabMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get staffTabMore;

  /// No description provided for @staffTabResidentApp.
  ///
  /// In en, this message translates to:
  /// **'Resident app'**
  String get staffTabResidentApp;

  /// No description provided for @staffSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Staff sign in'**
  String get staffSignInButton;

  /// No description provided for @staffModeButton.
  ///
  /// In en, this message translates to:
  /// **'Staff Mode'**
  String get staffModeButton;

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncTitle;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncAllDone.
  ///
  /// In en, this message translates to:
  /// **'Everything is synced'**
  String get syncAllDone;

  /// No description provided for @syncWaitingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 waiting to sync} other{{count} waiting to sync}}'**
  String syncWaitingCount(int count);

  /// No description provided for @syncAttentionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 needs a look} other{{count} need a look}}'**
  String syncAttentionCount(int count);

  /// No description provided for @syncSentMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing new to send.} =1{1 sent.} other{{count} sent.}}'**
  String syncSentMessage(int count);

  /// No description provided for @syncNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs a look'**
  String get syncNeedsAttention;

  /// No description provided for @syncWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync'**
  String get syncWaiting;

  /// No description provided for @syncFamilyRegistrations.
  ///
  /// In en, this message translates to:
  /// **'Family registrations'**
  String get syncFamilyRegistrations;

  /// No description provided for @syncTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get syncTryAgain;

  /// No description provided for @syncDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this action?'**
  String get syncDiscardTitle;

  /// No description provided for @syncDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'\"{summary}\" will not be sent. This cannot be undone.'**
  String syncDiscardBody(Object summary);

  /// No description provided for @syncDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get syncDiscardConfirm;

  /// No description provided for @syncDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Action discarded'**
  String get syncDiscarded;

  /// No description provided for @syncCouldNotRead.
  ///
  /// In en, this message translates to:
  /// **'Could not read the queue on this device.'**
  String get syncCouldNotRead;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @staffSyncRow.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get staffSyncRow;

  /// No description provided for @purokOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Purok (optional)'**
  String get purokOptionalLabel;

  /// No description provided for @purokNone.
  ///
  /// In en, this message translates to:
  /// **'No purok'**
  String get purokNone;

  /// No description provided for @ecBoardFamiliesHereTitle.
  ///
  /// In en, this message translates to:
  /// **'Families here now'**
  String get ecBoardFamiliesHereTitle;

  /// No description provided for @ecBoardFamiliesHereEmpty.
  ///
  /// In en, this message translates to:
  /// **'No family is checked in here for this event.'**
  String get ecBoardFamiliesHereEmpty;

  /// No description provided for @ecBoardFamilyMembers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String ecBoardFamilyMembers(int count);

  /// No description provided for @showAllCount.
  ///
  /// In en, this message translates to:
  /// **'Show all {count}'**
  String showAllCount(int count);

  /// No description provided for @returningFamiliesTitle.
  ///
  /// In en, this message translates to:
  /// **'Returning families'**
  String get returningFamiliesTitle;

  /// No description provided for @returningFamiliesOfflineButton.
  ///
  /// In en, this message translates to:
  /// **'Returning families (needs a connection)'**
  String get returningFamiliesOfflineButton;

  /// No description provided for @returningFamiliesNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Returning families need an internet connection.'**
  String get returningFamiliesNeedsConnection;

  /// No description provided for @returningFamiliesNoPastEvents.
  ///
  /// In en, this message translates to:
  /// **'No family of your barangay from a past event can be entered here.'**
  String get returningFamiliesNoPastEvents;

  /// No description provided for @returningFamiliesPastEvent.
  ///
  /// In en, this message translates to:
  /// **'Past event'**
  String get returningFamiliesPastEvent;

  /// No description provided for @returningFamiliesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Family or member name'**
  String get returningFamiliesSearchHint;

  /// No description provided for @returningFamiliesNone.
  ///
  /// In en, this message translates to:
  /// **'No family found.'**
  String get returningFamiliesNone;

  /// No description provided for @returningFamilyAlreadyIn.
  ///
  /// In en, this message translates to:
  /// **'Already in this event'**
  String get returningFamilyAlreadyIn;

  /// No description provided for @returningFamilyWhoArrived.
  ///
  /// In en, this message translates to:
  /// **'Who arrived?'**
  String get returningFamilyWhoArrived;

  /// No description provided for @returningFamilyUnnamed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member without a name is not listed.} other{{count} members without a name are not listed.}}'**
  String returningFamilyUnnamed(int count);

  /// No description provided for @returningMemberCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Already checked in this event'**
  String get returningMemberCheckedIn;

  /// No description provided for @returningMemberAge.
  ///
  /// In en, this message translates to:
  /// **'{age, plural, =1{1 year} other{{age} years}}'**
  String returningMemberAge(int age);

  /// No description provided for @returningMemberAgeGroup.
  ///
  /// In en, this message translates to:
  /// **'Age group (no birthdate on record)'**
  String get returningMemberAgeGroup;

  /// No description provided for @returningMemberStillPregnant.
  ///
  /// In en, this message translates to:
  /// **'Pregnant now'**
  String get returningMemberStillPregnant;

  /// No description provided for @returningMemberStillLactating.
  ///
  /// In en, this message translates to:
  /// **'Lactating now'**
  String get returningMemberStillLactating;

  /// No description provided for @returningFamilyEnroll.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Enter 1 person} other{Enter {count} people}}'**
  String returningFamilyEnroll(int count);

  /// No description provided for @returningFamilyDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person entered} other{{count} people entered}}'**
  String returningFamilyDone(int count);

  /// No description provided for @returningFamilyDuplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Same family?'**
  String get returningFamilyDuplicateTitle;

  /// No description provided for @returningFamilyDuplicateBody.
  ///
  /// In en, this message translates to:
  /// **'A family that may be the same one is already in this event.'**
  String get returningFamilyDuplicateBody;

  /// No description provided for @returningFamilyLinkTo.
  ///
  /// In en, this message translates to:
  /// **'Same family, link it: {name} · {center} · {members}'**
  String returningFamilyLinkTo(String name, String center, String members);

  /// No description provided for @returningFamilyDifferent.
  ///
  /// In en, this message translates to:
  /// **'Different family, add as new'**
  String get returningFamilyDifferent;

  /// No description provided for @centerLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location on the map'**
  String get centerLocationTitle;

  /// No description provided for @centerLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'On the map'**
  String get centerLocationOnMap;

  /// No description provided for @centerLocationWaitingForCswd.
  ///
  /// In en, this message translates to:
  /// **'A location you sent is waiting for CSWD.'**
  String get centerLocationWaitingForCswd;

  /// No description provided for @centerLocationWaitingToSync.
  ///
  /// In en, this message translates to:
  /// **'A location is saved on this phone and will be sent when online.'**
  String get centerLocationWaitingToSync;

  /// No description provided for @centerLocationSetFromPhone.
  ///
  /// In en, this message translates to:
  /// **'Set location from this phone'**
  String get centerLocationSetFromPhone;

  /// No description provided for @centerLocationConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Use this location?'**
  String get centerLocationConfirmTitle;

  /// No description provided for @centerLocationAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accurate to about {meters} m'**
  String centerLocationAccuracy(int meters);

  /// No description provided for @centerLocationLowAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Low accuracy. Step outside or wait a moment, then try again.'**
  String get centerLocationLowAccuracy;

  /// No description provided for @centerLocationGoesToCswd.
  ///
  /// In en, this message translates to:
  /// **'Stand at the center\'s entrance. CSWD approves the location before it appears on the map.'**
  String get centerLocationGoesToCswd;

  /// No description provided for @centerLocationSend.
  ///
  /// In en, this message translates to:
  /// **'Send to CSWD'**
  String get centerLocationSend;

  /// No description provided for @centerLocationSummary.
  ///
  /// In en, this message translates to:
  /// **'Location of {center}'**
  String centerLocationSummary(Object center);

  /// No description provided for @centerLocationQueued.
  ///
  /// In en, this message translates to:
  /// **'Location sent for CSWD approval (or kept until you are online).'**
  String get centerLocationQueued;

  /// No description provided for @facilityRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Facility requests'**
  String get facilityRequestsTitle;

  /// No description provided for @facilityRequestsNone.
  ///
  /// In en, this message translates to:
  /// **'No request yet.'**
  String get facilityRequestsNone;

  /// No description provided for @facilityRequestsNeedConnection.
  ///
  /// In en, this message translates to:
  /// **'The requests sent before need a connection to show.'**
  String get facilityRequestsNeedConnection;

  /// No description provided for @facilityRequestsAsk.
  ///
  /// In en, this message translates to:
  /// **'Request what\'s missing'**
  String get facilityRequestsAsk;

  /// No description provided for @facilityRequestWhat.
  ///
  /// In en, this message translates to:
  /// **'What is missing'**
  String get facilityRequestWhat;

  /// No description provided for @facilityRequestOther.
  ///
  /// In en, this message translates to:
  /// **'Something else (type it)'**
  String get facilityRequestOther;

  /// No description provided for @facilityRequestItem.
  ///
  /// In en, this message translates to:
  /// **'What is needed'**
  String get facilityRequestItem;

  /// No description provided for @facilityRequestQuantity.
  ///
  /// In en, this message translates to:
  /// **'How many'**
  String get facilityRequestQuantity;

  /// No description provided for @facilityRequestReason.
  ///
  /// In en, this message translates to:
  /// **'Why (optional)'**
  String get facilityRequestReason;

  /// No description provided for @facilityRequestSend.
  ///
  /// In en, this message translates to:
  /// **'Send to CSWD'**
  String get facilityRequestSend;

  /// No description provided for @facilityRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent to CSWD (or kept until you are online).'**
  String get facilityRequestSent;

  /// No description provided for @facilityRequestSummary.
  ///
  /// In en, this message translates to:
  /// **'{what} × {count} for {center}'**
  String facilityRequestSummary(String what, int count, String center);

  /// No description provided for @requestStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get requestStatusWaiting;

  /// No description provided for @requestStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get requestStatusApproved;

  /// No description provided for @requestStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get requestStatusRejected;

  /// No description provided for @decrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get decrease;

  /// No description provided for @increase.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get increase;

  /// No description provided for @reliefTitle.
  ///
  /// In en, this message translates to:
  /// **'Relief boxes'**
  String get reliefTitle;

  /// No description provided for @staffTabRelief.
  ///
  /// In en, this message translates to:
  /// **'Relief'**
  String get staffTabRelief;

  /// No description provided for @reliefNeedsConnectionFirst.
  ///
  /// In en, this message translates to:
  /// **'Relief boxes need a connection the first time.'**
  String get reliefNeedsConnectionFirst;

  /// No description provided for @staffNoOpenEvent.
  ///
  /// In en, this message translates to:
  /// **'No open event yet. CSWDO opens an event when a threat is announced.'**
  String get staffNoOpenEvent;

  /// No description provided for @savedCopyAge.
  ///
  /// In en, this message translates to:
  /// **'As of {age}'**
  String savedCopyAge(Object age);

  /// No description provided for @reliefNoRoundYet.
  ///
  /// In en, this message translates to:
  /// **'No relief round yet.'**
  String get reliefNoRoundYet;

  /// No description provided for @reliefRound.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String reliefRound(int number);

  /// No description provided for @reliefNeed.
  ///
  /// In en, this message translates to:
  /// **'Need'**
  String get reliefNeed;

  /// No description provided for @reliefReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get reliefReceived;

  /// No description provided for @reliefGiven.
  ///
  /// In en, this message translates to:
  /// **'Given'**
  String get reliefGiven;

  /// No description provided for @reliefShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get reliefShort;

  /// No description provided for @reliefBoxesToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Boxes to confirm'**
  String get reliefBoxesToConfirm;

  /// No description provided for @reliefGiveBoxes.
  ///
  /// In en, this message translates to:
  /// **'Give boxes'**
  String get reliefGiveBoxes;

  /// No description provided for @reliefGivenOfReceived.
  ///
  /// In en, this message translates to:
  /// **'{given} given of {received} received'**
  String reliefGivenOfReceived(int given, int received);

  /// No description provided for @reliefBoxesSent.
  ///
  /// In en, this message translates to:
  /// **'{boxes} sent, round {round}'**
  String reliefBoxesSent(String boxes, int round);

  /// No description provided for @reliefConfirmArrived.
  ///
  /// In en, this message translates to:
  /// **'Confirm what arrived'**
  String get reliefConfirmArrived;

  /// No description provided for @reliefHowManyArrived.
  ///
  /// In en, this message translates to:
  /// **'How many boxes arrived?'**
  String get reliefHowManyArrived;

  /// No description provided for @reliefBoxesArrived.
  ///
  /// In en, this message translates to:
  /// **'Boxes received (of {sent} sent)'**
  String reliefBoxesArrived(int sent);

  /// No description provided for @reliefFewerNote.
  ///
  /// In en, this message translates to:
  /// **'Why fewer? (required)'**
  String get reliefFewerNote;

  /// No description provided for @reliefConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get reliefConfirm;

  /// No description provided for @reliefConfirmSummary.
  ///
  /// In en, this message translates to:
  /// **'{boxes} received, round {round}'**
  String reliefConfirmSummary(String boxes, int round);

  /// No description provided for @reliefLeftToGive.
  ///
  /// In en, this message translates to:
  /// **'Left to give'**
  String get reliefLeftToGive;

  /// No description provided for @reliefByPriority.
  ///
  /// In en, this message translates to:
  /// **'By priority'**
  String get reliefByPriority;

  /// No description provided for @reliefByName.
  ///
  /// In en, this message translates to:
  /// **'By name'**
  String get reliefByName;

  /// No description provided for @reliefSuggestedOrderNote.
  ///
  /// In en, this message translates to:
  /// **'Priority order: give to the families at the top first.'**
  String get reliefSuggestedOrderNote;

  /// No description provided for @reliefPurokHeading.
  ///
  /// In en, this message translates to:
  /// **'{purok} · {given} of {total} given'**
  String reliefPurokHeading(String purok, int given, int total);

  /// No description provided for @reliefGiveBox.
  ///
  /// In en, this message translates to:
  /// **'Give box'**
  String get reliefGiveBox;

  /// No description provided for @reliefGivenWaiting.
  ///
  /// In en, this message translates to:
  /// **'Given, waiting to sync'**
  String get reliefGivenWaiting;

  /// No description provided for @reliefVoidWaiting.
  ///
  /// In en, this message translates to:
  /// **'Void waiting to sync'**
  String get reliefVoidWaiting;

  /// No description provided for @reliefVoidHandout.
  ///
  /// In en, this message translates to:
  /// **'Void handout'**
  String get reliefVoidHandout;

  /// No description provided for @reliefVoidTitle.
  ///
  /// In en, this message translates to:
  /// **'Void the box for {family}?'**
  String reliefVoidTitle(Object family);

  /// No description provided for @reliefVoidBody.
  ///
  /// In en, this message translates to:
  /// **'The family will show as not given yet. This cannot be undone.'**
  String get reliefVoidBody;

  /// No description provided for @reliefVoidReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (required)'**
  String get reliefVoidReason;

  /// No description provided for @reliefGiveSummary.
  ///
  /// In en, this message translates to:
  /// **'Box for {family}, round {round}'**
  String reliefGiveSummary(String family, int round);

  /// No description provided for @reliefVoidSummary.
  ///
  /// In en, this message translates to:
  /// **'Void box for {family}'**
  String reliefVoidSummary(Object family);

  /// No description provided for @staffTabBarangay.
  ///
  /// In en, this message translates to:
  /// **'Barangay'**
  String get staffTabBarangay;

  /// No description provided for @barangayStatusNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'The barangay status needs a connection the first time.'**
  String get barangayStatusNeedsConnection;

  /// No description provided for @barangayStatusSetBy.
  ///
  /// In en, this message translates to:
  /// **'Set by {name}, {when}'**
  String barangayStatusSetBy(Object name, Object when);

  /// No description provided for @barangayStatusReadOnly.
  ///
  /// In en, this message translates to:
  /// **'The event is closed. The status can only be changed during an open event.'**
  String get barangayStatusReadOnly;

  /// No description provided for @barangayStatusCswdOrder.
  ///
  /// In en, this message translates to:
  /// **'Under \"{status}\", ordered by CSWD. Only CSWD can change it.'**
  String barangayStatusCswdOrder(Object status);

  /// No description provided for @barangayStatusChange.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get barangayStatusChange;

  /// No description provided for @barangayStatusNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional; required to update the same status)'**
  String get barangayStatusNote;

  /// No description provided for @barangayStatusSave.
  ///
  /// In en, this message translates to:
  /// **'Save status'**
  String get barangayStatusSave;

  /// No description provided for @barangayStatusSaved.
  ///
  /// In en, this message translates to:
  /// **'Marked \"{status}\" (sent when online).'**
  String barangayStatusSaved(Object status);

  /// No description provided for @finalCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Final count'**
  String get finalCountTitle;

  /// No description provided for @finalCountFigures.
  ///
  /// In en, this message translates to:
  /// **'{families} · {persons}'**
  String finalCountFigures(String families, String persons);

  /// No description provided for @finalCountInsideOutside.
  ///
  /// In en, this message translates to:
  /// **'{inside} inside centers · {outside} outside'**
  String finalCountInsideOutside(int inside, int outside);

  /// No description provided for @finalCountNoStay.
  ///
  /// In en, this message translates to:
  /// **'{count} with no stay recorded'**
  String finalCountNoStay(int count);

  /// No description provided for @finalCountNotSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Not submitted yet'**
  String get finalCountNotSubmitted;

  /// No description provided for @finalCountWaiting.
  ///
  /// In en, this message translates to:
  /// **'Submitted, waiting for CSWD'**
  String get finalCountWaiting;

  /// No description provided for @finalCountReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned by CSWD'**
  String get finalCountReturned;

  /// No description provided for @finalCountValidated.
  ///
  /// In en, this message translates to:
  /// **'Validated: {families} (the relief need)'**
  String finalCountValidated(String families);

  /// No description provided for @finalCountChanged.
  ///
  /// In en, this message translates to:
  /// **'The count has changed since the last submission.'**
  String get finalCountChanged;

  /// No description provided for @finalCountSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit final count'**
  String get finalCountSubmit;

  /// No description provided for @finalCountSubmitUpdated.
  ///
  /// In en, this message translates to:
  /// **'Submit updated count'**
  String get finalCountSubmitUpdated;

  /// No description provided for @finalCountSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit this final count?'**
  String get finalCountSubmitTitle;

  /// No description provided for @finalCountComputedNote.
  ///
  /// In en, this message translates to:
  /// **'The system computes these numbers from the families registered in this event; they are not typed in.'**
  String get finalCountComputedNote;

  /// No description provided for @finalCountNote.
  ///
  /// In en, this message translates to:
  /// **'Note for CSWD (optional)'**
  String get finalCountNote;

  /// No description provided for @finalCountSummary.
  ///
  /// In en, this message translates to:
  /// **'Final count: {families}, {persons}'**
  String finalCountSummary(String families, String persons);

  /// No description provided for @reliefShortfallTitle.
  ///
  /// In en, this message translates to:
  /// **'Request more boxes for round {round}'**
  String reliefShortfallTitle(int round);

  /// No description provided for @reliefShortfallSend.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get reliefShortfallSend;

  /// No description provided for @reliefShortfallAsk.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Request 1 more box} other{Request up to {count} more boxes}}'**
  String reliefShortfallAsk(int count);

  /// No description provided for @reliefShortfallRow.
  ///
  /// In en, this message translates to:
  /// **'Requested {count} more: {status}'**
  String reliefShortfallRow(int count, String status);

  /// No description provided for @reliefShortfallSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Request 1 more box, round {round}} other{Request {count} more boxes, round {round}}}'**
  String reliefShortfallSummary(int count, int round);

  /// No description provided for @staffMyCentersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set a location, request what is missing'**
  String get staffMyCentersSubtitle;

  /// No description provided for @pendingRegistrationsRetiring.
  ///
  /// In en, this message translates to:
  /// **'Full registrations are no longer started on the phone; families are entered on the EC Board. Sync or fix the ones below. This screen goes away once they are done.'**
  String get pendingRegistrationsRetiring;

  /// No description provided for @monitoringTitle.
  ///
  /// In en, this message translates to:
  /// **'Monitoring'**
  String get monitoringTitle;

  /// No description provided for @staffTabMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Monitoring'**
  String get staffTabMonitoring;

  /// No description provided for @monitoringOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get monitoringOverview;

  /// No description provided for @monitoringCenters.
  ///
  /// In en, this message translates to:
  /// **'Centers'**
  String get monitoringCenters;

  /// No description provided for @monitoringBarangays.
  ///
  /// In en, this message translates to:
  /// **'Barangays'**
  String get monitoringBarangays;

  /// No description provided for @monitoringRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get monitoringRequests;

  /// No description provided for @monitoringPersons.
  ///
  /// In en, this message translates to:
  /// **'Persons'**
  String get monitoringPersons;

  /// No description provided for @monitoringFamilies.
  ///
  /// In en, this message translates to:
  /// **'Families'**
  String get monitoringFamilies;

  /// No description provided for @monitoringInside.
  ///
  /// In en, this message translates to:
  /// **'Inside centers'**
  String get monitoringInside;

  /// No description provided for @monitoringCentersInUse.
  ///
  /// In en, this message translates to:
  /// **'Centers in use'**
  String get monitoringCentersInUse;

  /// No description provided for @monitoringArrivedLastHour.
  ///
  /// In en, this message translates to:
  /// **'{count} arrived in the last hour'**
  String monitoringArrivedLastHour(int count);

  /// No description provided for @monitoringNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get monitoringNeedsAttention;

  /// No description provided for @monitoringNothingUrgent.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs attention now.'**
  String get monitoringNothingUrgent;

  /// No description provided for @monitoringCentersSummary.
  ///
  /// In en, this message translates to:
  /// **'{inUse} of {centers} in use · {noCapacity} without capacity'**
  String monitoringCentersSummary(int inUse, String centers, int noCapacity);

  /// No description provided for @monitoringShort.
  ///
  /// In en, this message translates to:
  /// **'Short: {items}'**
  String monitoringShort(Object items);

  /// No description provided for @monitoringNoChecklist.
  ///
  /// In en, this message translates to:
  /// **'No facilities checklist'**
  String get monitoringNoChecklist;

  /// No description provided for @monitoringInsideNoCapacity.
  ///
  /// In en, this message translates to:
  /// **'{count} inside · capacity not set'**
  String monitoringInsideNoCapacity(int count);

  /// No description provided for @monitoringNotNormal.
  ///
  /// In en, this message translates to:
  /// **'Not normal'**
  String get monitoringNotNormal;

  /// No description provided for @monitoringAllNormal.
  ///
  /// In en, this message translates to:
  /// **'Every barangay is normal.'**
  String get monitoringAllNormal;

  /// No description provided for @monitoringLatestChanges.
  ///
  /// In en, this message translates to:
  /// **'Latest changes'**
  String get monitoringLatestChanges;

  /// No description provided for @monitoringNoRequests.
  ///
  /// In en, this message translates to:
  /// **'No request is waiting.'**
  String get monitoringNoRequests;

  /// No description provided for @monitoringNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Monitoring needs a connection the first time.'**
  String get monitoringNeedsConnection;

  /// No description provided for @monitoringUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {age}'**
  String monitoringUpdated(Object age);

  /// No description provided for @reliefNextInLine.
  ///
  /// In en, this message translates to:
  /// **'Next in line'**
  String get reliefNextInLine;

  /// No description provided for @reliefWaitingForBoxes.
  ///
  /// In en, this message translates to:
  /// **'Waiting for more boxes'**
  String get reliefWaitingForBoxes;

  /// No description provided for @countFamilies.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 family} other{{count} families}}'**
  String countFamilies(int count);

  /// No description provided for @countPersons.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} persons}}'**
  String countPersons(int count);

  /// No description provided for @countBoxes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 box} other{{count} boxes}}'**
  String countBoxes(int count);

  /// No description provided for @countCenters.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 center} other{{count} centers}}'**
  String countCenters(int count);

  /// No description provided for @countEvacuees.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 evacuee} other{{count} evacuees}}'**
  String countEvacuees(int count);

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register family'**
  String get registerTitle;

  /// No description provided for @registerStepHead.
  ///
  /// In en, this message translates to:
  /// **'Head of family'**
  String get registerStepHead;

  /// No description provided for @registerStepMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get registerStepMembers;

  /// No description provided for @registerStepPlace.
  ///
  /// In en, this message translates to:
  /// **'Purok and center'**
  String get registerStepPlace;

  /// No description provided for @registerStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get registerStepReview;

  /// No description provided for @registerStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String registerStepOf(int step, int total);

  /// No description provided for @registerBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get registerBack;

  /// No description provided for @registerNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get registerNext;

  /// No description provided for @registerSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get registerSave;

  /// No description provided for @registerSaved.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s family saved. It is sent now, or when you are back online.'**
  String registerSaved(Object name);

  /// No description provided for @registerDiscardDraft.
  ///
  /// In en, this message translates to:
  /// **'Discard this draft'**
  String get registerDiscardDraft;

  /// No description provided for @registerFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get registerFirstName;

  /// No description provided for @registerMiddleName.
  ///
  /// In en, this message translates to:
  /// **'Middle name (optional)'**
  String get registerMiddleName;

  /// No description provided for @registerLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get registerLastName;

  /// No description provided for @registerSex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get registerSex;

  /// No description provided for @registerBirthdate.
  ///
  /// In en, this message translates to:
  /// **'Choose the date of birth'**
  String get registerBirthdate;

  /// No description provided for @registerBirthdateValue.
  ///
  /// In en, this message translates to:
  /// **'Born {date}'**
  String registerBirthdateValue(Object date);

  /// No description provided for @registerMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get registerMobile;

  /// No description provided for @registerMobileInvalid.
  ///
  /// In en, this message translates to:
  /// **'11 digits starting with 09 (or +639)'**
  String get registerMobileInvalid;

  /// No description provided for @registerPwd.
  ///
  /// In en, this message translates to:
  /// **'Person with disability (PWD)'**
  String get registerPwd;

  /// No description provided for @registerPwdType.
  ///
  /// In en, this message translates to:
  /// **'Type of disability'**
  String get registerPwdType;

  /// No description provided for @registerSoloParent.
  ///
  /// In en, this message translates to:
  /// **'Solo parent'**
  String get registerSoloParent;

  /// No description provided for @registerIndigenous.
  ///
  /// In en, this message translates to:
  /// **'Indigenous person'**
  String get registerIndigenous;

  /// No description provided for @register4ps.
  ///
  /// In en, this message translates to:
  /// **'4Ps beneficiary'**
  String get register4ps;

  /// No description provided for @registerMembersHint.
  ///
  /// In en, this message translates to:
  /// **'Add the other people of the family. Each one uses the head\'s mobile number unless they have their own.'**
  String get registerMembersHint;

  /// No description provided for @registerAddMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get registerAddMember;

  /// No description provided for @registerEditMember.
  ///
  /// In en, this message translates to:
  /// **'Edit member'**
  String get registerEditMember;

  /// No description provided for @registerRemoveMember.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get registerRemoveMember;

  /// No description provided for @registerSaveMember.
  ///
  /// In en, this message translates to:
  /// **'Save member'**
  String get registerSaveMember;

  /// No description provided for @registerBarangay.
  ///
  /// In en, this message translates to:
  /// **'Barangay'**
  String get registerBarangay;

  /// No description provided for @registerCenter.
  ///
  /// In en, this message translates to:
  /// **'Evacuation center'**
  String get registerCenter;

  /// No description provided for @registerHomeAddress.
  ///
  /// In en, this message translates to:
  /// **'Home address (optional)'**
  String get registerHomeAddress;

  /// No description provided for @registerSaveNote.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone first and sent to the server; nothing is lost offline.'**
  String get registerSaveNote;

  /// No description provided for @sexFemaleShort.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get sexFemaleShort;

  /// No description provided for @sexMaleShort.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get sexMaleShort;

  /// No description provided for @staffTabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get staffTabHome;

  /// No description provided for @homeEvacueesHere.
  ///
  /// In en, this message translates to:
  /// **'Evacuees in my centers'**
  String get homeEvacueesHere;

  /// No description provided for @homeWithoutBox.
  ///
  /// In en, this message translates to:
  /// **'Families without a box'**
  String get homeWithoutBox;

  /// No description provided for @homeBoxesLeft.
  ///
  /// In en, this message translates to:
  /// **'Boxes left'**
  String get homeBoxesLeft;

  /// No description provided for @homeEvacuees.
  ///
  /// In en, this message translates to:
  /// **'Evacuees'**
  String get homeEvacuees;

  /// No description provided for @homeNoOccupancyYet.
  ///
  /// In en, this message translates to:
  /// **'No count yet'**
  String get homeNoOccupancyYet;

  /// No description provided for @homeCheckInOut.
  ///
  /// In en, this message translates to:
  /// **'Check in / Check out'**
  String get homeCheckInOut;

  /// No description provided for @homeGiveBox.
  ///
  /// In en, this message translates to:
  /// **'Give relief box'**
  String get homeGiveBox;

  /// No description provided for @homeTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get homeTodo;

  /// No description provided for @homeTodoNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing to do right now.'**
  String get homeTodoNone;

  /// No description provided for @homeTodoWithoutBox.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 family is waiting for a box} other{{count} families are waiting for boxes}}'**
  String homeTodoWithoutBox(int count);

  /// No description provided for @homeTodoFinalCountNotSent.
  ///
  /// In en, this message translates to:
  /// **'Final count not sent'**
  String get homeTodoFinalCountNotSent;

  /// No description provided for @homeBarangayStatus.
  ///
  /// In en, this message translates to:
  /// **'Barangay status'**
  String get homeBarangayStatus;

  /// No description provided for @homeAllHotlines.
  ///
  /// In en, this message translates to:
  /// **'All hotlines'**
  String get homeAllHotlines;

  /// No description provided for @syncAllSent.
  ///
  /// In en, this message translates to:
  /// **'All sent'**
  String get syncAllSent;

  /// No description provided for @syncWaitingToSend.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 waiting to send} other{{count} waiting to send}}'**
  String syncWaitingToSend(int count);

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsNeedConnection.
  ///
  /// In en, this message translates to:
  /// **'Notifications need a connection the first time.'**
  String get notificationsNeedConnection;

  /// No description provided for @notificationsNone.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notificationsNone;

  /// No description provided for @cswdHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'City overview'**
  String get cswdHomeTitle;

  /// No description provided for @eventStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get eventStatusActive;

  /// No description provided for @eventStatusMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Monitoring'**
  String get eventStatusMonitoring;

  /// No description provided for @cswdBarangaysByStatus.
  ///
  /// In en, this message translates to:
  /// **'Barangays per status'**
  String get cswdBarangaysByStatus;

  /// No description provided for @cswdCenterNearlyFull.
  ///
  /// In en, this message translates to:
  /// **'{name} is {percent}% full'**
  String cswdCenterNearlyFull(String name, int percent);

  /// No description provided for @cswdBarangayShortBoxes.
  ///
  /// In en, this message translates to:
  /// **'{name} is short {boxes}'**
  String cswdBarangayShortBoxes(String name, String boxes);

  /// No description provided for @countBarangays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 barangay} other{{count} barangays}}'**
  String countBarangays(int count);

  /// No description provided for @cswdFinalCountsNotSent.
  ///
  /// In en, this message translates to:
  /// **'Final count not sent: {barangays} ({names})'**
  String cswdFinalCountsNotSent(String barangays, String names);

  /// No description provided for @cswdDoThisOnTheWeb.
  ///
  /// In en, this message translates to:
  /// **'Other changes (events, centers, accounts, relief stock): do this on the web.'**
  String get cswdDoThisOnTheWeb;

  /// No description provided for @cswdOpenMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Open monitoring'**
  String get cswdOpenMonitoring;

  /// No description provided for @cswdReadiness.
  ///
  /// In en, this message translates to:
  /// **'Readiness'**
  String get cswdReadiness;

  /// No description provided for @cswdReadyCenters.
  ///
  /// In en, this message translates to:
  /// **'{centers} ready of {approved} approved'**
  String cswdReadyCenters(String centers, int approved);

  /// No description provided for @cswdBelowStandards.
  ///
  /// In en, this message translates to:
  /// **'Below standards: {centers}'**
  String cswdBelowStandards(String centers);

  /// No description provided for @cswdBoxStock.
  ///
  /// In en, this message translates to:
  /// **'City box stock: {boxes}'**
  String cswdBoxStock(String boxes);

  /// No description provided for @cswdWatchedBarangays.
  ///
  /// In en, this message translates to:
  /// **'Watched: {names}'**
  String cswdWatchedBarangays(String names);

  /// No description provided for @cswdOrderNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'An evacuation order needs a connection. It is never saved to send later.'**
  String get cswdOrderNeedsConnection;

  /// No description provided for @cswdOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Order {status} for {name}?'**
  String cswdOrderTitle(String status, String name);

  /// No description provided for @cswdOrderBody.
  ///
  /// In en, this message translates to:
  /// **'This notifies the barangay.'**
  String get cswdOrderBody;

  /// No description provided for @cswdOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Order {status}'**
  String cswdOrderConfirm(String status);

  /// No description provided for @barangayStatusOrdered.
  ///
  /// In en, this message translates to:
  /// **'{status} ordered for {name}.'**
  String barangayStatusOrdered(String status, String name);

  /// No description provided for @cswdOrderEvacuation.
  ///
  /// In en, this message translates to:
  /// **'Evacuation order'**
  String get cswdOrderEvacuation;

  /// No description provided for @staffMorePublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get staffMorePublic;

  /// No description provided for @staffMorePublicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The resident app: alerts, centers, hotlines'**
  String get staffMorePublicSubtitle;

  /// No description provided for @distanceMetersAway.
  ///
  /// In en, this message translates to:
  /// **'{meters} m away'**
  String distanceMetersAway(int meters);

  /// No description provided for @distanceKmAway.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String distanceKmAway(String km);

  /// No description provided for @adviceWatch.
  ///
  /// In en, this message translates to:
  /// **'Get ready. Pack your go-bag and listen for updates.'**
  String get adviceWatch;

  /// No description provided for @adviceFlooding.
  ///
  /// In en, this message translates to:
  /// **'Flooding is reported. Move to higher ground if water rises.'**
  String get adviceFlooding;

  /// No description provided for @advicePreemptive.
  ///
  /// In en, this message translates to:
  /// **'Preemptive evacuation: go to your evacuation center now.'**
  String get advicePreemptive;

  /// No description provided for @adviceForced.
  ///
  /// In en, this message translates to:
  /// **'Forced evacuation: leave now and go to your evacuation center.'**
  String get adviceForced;

  /// No description provided for @adviceNormal.
  ///
  /// In en, this message translates to:
  /// **'No action needed. Stay alert.'**
  String get adviceNormal;

  /// No description provided for @registerWhereStaying.
  ///
  /// In en, this message translates to:
  /// **'Where is the family staying?'**
  String get registerWhereStaying;

  /// No description provided for @registerInCenter.
  ///
  /// In en, this message translates to:
  /// **'In a center'**
  String get registerInCenter;

  /// No description provided for @registerPrivateHouse.
  ///
  /// In en, this message translates to:
  /// **'Private house'**
  String get registerPrivateHouse;

  /// No description provided for @registerPrivateHouseHint.
  ///
  /// In en, this message translates to:
  /// **'Staying with relatives or friends.'**
  String get registerPrivateHouseHint;

  /// No description provided for @registerHostName.
  ///
  /// In en, this message translates to:
  /// **'Name of the relative or friend'**
  String get registerHostName;

  /// No description provided for @registerHostPurok.
  ///
  /// In en, this message translates to:
  /// **'Purok of the house'**
  String get registerHostPurok;

  /// No description provided for @registerHostAddress.
  ///
  /// In en, this message translates to:
  /// **'Address of the house'**
  String get registerHostAddress;

  /// No description provided for @registerHostWhere.
  ///
  /// In en, this message translates to:
  /// **'Enter the address or choose the purok.'**
  String get registerHostWhere;

  /// No description provided for @privateHouseWith.
  ///
  /// In en, this message translates to:
  /// **'Private house, with {host}'**
  String privateHouseWith(String host);

  /// No description provided for @privateHousesTitle.
  ///
  /// In en, this message translates to:
  /// **'Private houses'**
  String get privateHousesTitle;

  /// No description provided for @privateHousesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Families staying with relatives or friends'**
  String get privateHousesSubtitle;

  /// No description provided for @privateHousesSummary.
  ///
  /// In en, this message translates to:
  /// **'{families}, {persons}'**
  String privateHousesSummary(String families, String persons);

  /// No description provided for @privateHousesNone.
  ///
  /// In en, this message translates to:
  /// **'No family is staying in a private house.'**
  String get privateHousesNone;

  /// No description provided for @privateHouseDetailsPending.
  ///
  /// In en, this message translates to:
  /// **'Details pending'**
  String get privateHouseDetailsPending;

  /// No description provided for @cswdPrivateHouseFamilies.
  ///
  /// In en, this message translates to:
  /// **'Families in private houses'**
  String get cswdPrivateHouseFamilies;

  /// No description provided for @eventSwitchCurrent.
  ///
  /// In en, this message translates to:
  /// **'Event: {name}'**
  String eventSwitchCurrent(String name);

  /// No description provided for @eventSwitchChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get eventSwitchChange;

  /// No description provided for @eventSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Work on which event?'**
  String get eventSwitchTitle;

  /// No description provided for @eventSwitchOpen.
  ///
  /// In en, this message translates to:
  /// **'Open events'**
  String get eventSwitchOpen;

  /// No description provided for @eventSwitchClosedEvents.
  ///
  /// In en, this message translates to:
  /// **'Closed events (read-only)'**
  String get eventSwitchClosedEvents;

  /// No description provided for @eventSwitchClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get eventSwitchClosed;

  /// No description provided for @eventSwitchClosedReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Closed: read-only'**
  String get eventSwitchClosedReadOnly;

  /// No description provided for @eventSwitchNowWorkingOn.
  ///
  /// In en, this message translates to:
  /// **'Now working on \"{name}\".'**
  String eventSwitchNowWorkingOn(String name);

  /// No description provided for @eventSwitchNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Changing the event needs a connection.'**
  String get eventSwitchNeedsConnection;

  /// No description provided for @registerSavesTo.
  ///
  /// In en, this message translates to:
  /// **'Saves to: {name}'**
  String registerSavesTo(String name);

  /// No description provided for @registerClosedEvent.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is closed. A closed event is read-only. Change the event to register a family.'**
  String registerClosedEvent(String name);

  /// No description provided for @lateEntriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 late entry} other{{count} late entries}}'**
  String lateEntriesCount(int count);

  /// No description provided for @lateEntriesAdded.
  ///
  /// In en, this message translates to:
  /// **'Added: {families}, {persons}'**
  String lateEntriesAdded(String families, String persons);

  /// No description provided for @lateEntriesRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed: {families}, {persons}'**
  String lateEntriesRemoved(String families, String persons);

  /// No description provided for @lateEntriesSince.
  ///
  /// In en, this message translates to:
  /// **'since {time}'**
  String lateEntriesSince(String time);

  /// No description provided for @lateEntriesNotInValidated.
  ///
  /// In en, this message translates to:
  /// **'Not in the validated count, which never changes. Submit an updated count to include them.'**
  String get lateEntriesNotInValidated;

  /// No description provided for @lateEntriesNotInCount.
  ///
  /// In en, this message translates to:
  /// **'Not in your final count yet. Submit an updated count to include them.'**
  String get lateEntriesNotInCount;

  /// No description provided for @lateEntriesTodo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 late entry, not yet in your final count} other{{count} late entries, not yet in your final count}}'**
  String lateEntriesTodo(int count);

  /// No description provided for @cswdLateEntriesPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 late entry pending, not yet in a final count} other{{count} late entries pending, not yet in a final count}}'**
  String cswdLateEntriesPending(int count);

  /// No description provided for @finalCountValidatedAsOf.
  ///
  /// In en, this message translates to:
  /// **'Validated: {families}, report as of {time}'**
  String finalCountValidatedAsOf(String families, String time);

  /// No description provided for @finalCountCentersPrivate.
  ///
  /// In en, this message translates to:
  /// **'In centers: {centers} · In private houses: {private}'**
  String finalCountCentersPrivate(String centers, String private);

  /// No description provided for @finalCountCheckIncomplete.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Check: 1 family has incomplete details.} other{Check: {count} families have incomplete details.}}'**
  String finalCountCheckIncomplete(int count);

  /// No description provided for @finalCountCheckDuplicates.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Check: 1 possible duplicate.} other{Check: {count} possible duplicates.}}'**
  String finalCountCheckDuplicates(int count);

  /// No description provided for @finalCountAfterThis.
  ///
  /// In en, this message translates to:
  /// **'After this, new evacuees are marked as late entries.'**
  String get finalCountAfterThis;

  /// No description provided for @finalCountReviewFirst.
  ///
  /// In en, this message translates to:
  /// **'Review first'**
  String get finalCountReviewFirst;

  /// No description provided for @finalCountSubmitShort.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get finalCountSubmitShort;

  /// No description provided for @orderedByAt.
  ///
  /// In en, this message translates to:
  /// **'Ordered by {who}, {time}'**
  String orderedByAt(String who, String time);

  /// No description provided for @cswdOrderRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Record a {status} order for {name} in {event}?'**
  String cswdOrderRecordTitle(String status, String name, String event);

  /// No description provided for @cswdOrderWhoOrdered.
  ///
  /// In en, this message translates to:
  /// **'Who ordered it?'**
  String get cswdOrderWhoOrdered;

  /// No description provided for @cswdOrderByMayor.
  ///
  /// In en, this message translates to:
  /// **'The City Mayor'**
  String get cswdOrderByMayor;

  /// No description provided for @cswdOrderByCdrrmo.
  ///
  /// In en, this message translates to:
  /// **'CDRRMO'**
  String get cswdOrderByCdrrmo;

  /// No description provided for @cswdOrderByOther.
  ///
  /// In en, this message translates to:
  /// **'Someone else'**
  String get cswdOrderByOther;

  /// No description provided for @cswdOrderByOtherName.
  ///
  /// In en, this message translates to:
  /// **'Name who ordered it'**
  String get cswdOrderByOtherName;

  /// No description provided for @cswdOrderWhen.
  ///
  /// In en, this message translates to:
  /// **'When?'**
  String get cswdOrderWhen;

  /// No description provided for @cswdOrderNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get cswdOrderNow;

  /// No description provided for @cswdOrderChangeTime.
  ///
  /// In en, this message translates to:
  /// **'Earlier today'**
  String get cswdOrderChangeTime;

  /// No description provided for @cswdOrderRecord.
  ///
  /// In en, this message translates to:
  /// **'Record order'**
  String get cswdOrderRecord;

  /// No description provided for @cswdRegisteredNow.
  ///
  /// In en, this message translates to:
  /// **'Registered now: {families}, {persons}'**
  String cswdRegisteredNow(String families, String persons);

  /// No description provided for @cswdSubmitForBarangay.
  ///
  /// In en, this message translates to:
  /// **'Submit for this barangay'**
  String get cswdSubmitForBarangay;

  /// No description provided for @cswdSubmitForTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit the final count for {name}?'**
  String cswdSubmitForTitle(String name);

  /// No description provided for @cswdSubmitForBody.
  ///
  /// In en, this message translates to:
  /// **'The system\'s count at this moment, labelled \"Submitted by CSWD for the barangay\". After this, new evacuees are marked as late entries.'**
  String get cswdSubmitForBody;

  /// No description provided for @cswdSubmitForDone.
  ///
  /// In en, this message translates to:
  /// **'Final count submitted for {name}.'**
  String cswdSubmitForDone(String name);

  /// No description provided for @cswdSubmitNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Submitting for a barangay needs a connection.'**
  String get cswdSubmitNeedsConnection;

  /// No description provided for @cswdOfficialSubmits.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s official submits the count.'**
  String cswdOfficialSubmits(String name);

  /// No description provided for @transfersTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get transfersTitle;

  /// No description provided for @transfersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Moving families to another barangay\'s center'**
  String get transfersSubtitle;

  /// No description provided for @transfersWaitingAnswer.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 request waiting for an answer} other{{count} requests waiting for an answer}}'**
  String transfersWaitingAnswer(int count);

  /// No description provided for @transfersAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get transfersAll;

  /// No description provided for @transfersNone.
  ///
  /// In en, this message translates to:
  /// **'No transfer requests.'**
  String get transfersNone;

  /// No description provided for @transferPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get transferPending;

  /// No description provided for @transferAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get transferAccepted;

  /// No description provided for @transferDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get transferDeclined;

  /// No description provided for @transferEscalated.
  ///
  /// In en, this message translates to:
  /// **'Escalated to CSWD'**
  String get transferEscalated;

  /// No description provided for @transferIncoming.
  ///
  /// In en, this message translates to:
  /// **'From {barangay}'**
  String transferIncoming(String barangay);

  /// No description provided for @transferOutgoing.
  ///
  /// In en, this message translates to:
  /// **'To {barangay}'**
  String transferOutgoing(String barangay);

  /// No description provided for @transferBetween.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String transferBetween(String from, String to);

  /// No description provided for @transferMoveSummary.
  ///
  /// In en, this message translates to:
  /// **'{families} ({persons}) from {from} to {to}'**
  String transferMoveSummary(
    String families,
    String persons,
    String from,
    String to,
  );

  /// No description provided for @transferFamilyLine.
  ///
  /// In en, this message translates to:
  /// **'{head}: {persons}'**
  String transferFamilyLine(String head, String persons);

  /// No description provided for @transferReasonLine.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String transferReasonLine(String reason);

  /// No description provided for @transferRequestedBy.
  ///
  /// In en, this message translates to:
  /// **'Asked by {who}, {time}'**
  String transferRequestedBy(String who, String time);

  /// No description provided for @transferEscalatedNote.
  ///
  /// In en, this message translates to:
  /// **'No answer in 30 minutes: CSWD was told at {time} and can decide it.'**
  String transferEscalatedNote(String time);

  /// No description provided for @transferDecidedBy.
  ///
  /// In en, this message translates to:
  /// **'Answered by {who}, {time}'**
  String transferDecidedBy(String who, String time);

  /// No description provided for @transferByCswd.
  ///
  /// In en, this message translates to:
  /// **'{name} (CSWD)'**
  String transferByCswd(String name);

  /// No description provided for @transferDeclineReasonLine.
  ///
  /// In en, this message translates to:
  /// **'Why declined: {reason}'**
  String transferDeclineReasonLine(String reason);

  /// No description provided for @transferAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get transferAccept;

  /// No description provided for @transferDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get transferDecline;

  /// No description provided for @transferAcceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept these families?'**
  String get transferAcceptTitle;

  /// No description provided for @transferDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline this request?'**
  String get transferDeclineTitle;

  /// No description provided for @transferDeclineReason.
  ///
  /// In en, this message translates to:
  /// **'Why? (the sender sees this)'**
  String get transferDeclineReason;

  /// No description provided for @transferNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Needs a connection. Transfers are never saved to send later.'**
  String get transferNeedsConnection;

  /// No description provided for @transferAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask another barangay\'s center'**
  String get transferAskTitle;

  /// No description provided for @transferFromCenter.
  ///
  /// In en, this message translates to:
  /// **'From {center}'**
  String transferFromCenter(String center);

  /// No description provided for @transferStepFamilies.
  ///
  /// In en, this message translates to:
  /// **'Families to move'**
  String get transferStepFamilies;

  /// No description provided for @transferStepFamiliesHint.
  ///
  /// In en, this message translates to:
  /// **'Your barangay\'s families at this center.'**
  String get transferStepFamiliesHint;

  /// No description provided for @transferStepCenter.
  ///
  /// In en, this message translates to:
  /// **'Move them to'**
  String get transferStepCenter;

  /// No description provided for @transferPickFamiliesFirst.
  ///
  /// In en, this message translates to:
  /// **'Tick the families first.'**
  String get transferPickFamiliesFirst;

  /// No description provided for @transferNoCenterWithSpace.
  ///
  /// In en, this message translates to:
  /// **'No other barangay\'s center has space.'**
  String get transferNoCenterWithSpace;

  /// No description provided for @transferStepReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get transferStepReason;

  /// No description provided for @transferReason.
  ///
  /// In en, this message translates to:
  /// **'Why are they moving?'**
  String get transferReason;

  /// No description provided for @transferReasonHint.
  ///
  /// In en, this message translates to:
  /// **'The receiving barangay sees this.'**
  String get transferReasonHint;

  /// No description provided for @transferRoomFor.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Room for 1} other{Room for {count}}}'**
  String transferRoomFor(int count);

  /// No description provided for @transferAboutKm.
  ///
  /// In en, this message translates to:
  /// **'about {km} km'**
  String transferAboutKm(String km);

  /// No description provided for @capacityUnknownTag.
  ///
  /// In en, this message translates to:
  /// **'Capacity unknown'**
  String get capacityUnknownTag;

  /// No description provided for @capacityEstimatedShort.
  ///
  /// In en, this message translates to:
  /// **'est.'**
  String get capacityEstimatedShort;

  /// No description provided for @transferSend.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get transferSend;

  /// No description provided for @transferSendTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask {barangay} to take these families?'**
  String transferSendTitle(String barangay);

  /// No description provided for @transferStayUntilAccepted.
  ///
  /// In en, this message translates to:
  /// **'The families stay at their center until it is accepted.'**
  String get transferStayUntilAccepted;

  /// No description provided for @transferSent.
  ///
  /// In en, this message translates to:
  /// **'Transfer request sent.'**
  String get transferSent;

  /// No description provided for @cswdMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get cswdMove;

  /// No description provided for @cswdMoveHint.
  ///
  /// In en, this message translates to:
  /// **'Move a family to any center. A reason is required.'**
  String get cswdMoveHint;

  /// No description provided for @cswdMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move {family}?'**
  String cswdMoveTitle(String family);

  /// No description provided for @cswdMoveReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get cswdMoveReason;

  /// No description provided for @cswdMoveReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required. Saved in the activity log.'**
  String get cswdMoveReasonRequired;

  /// No description provided for @cswdMoved.
  ///
  /// In en, this message translates to:
  /// **'{family} moved to {center}.'**
  String cswdMoved(String family, String center);

  /// No description provided for @capacityEstimated.
  ///
  /// In en, this message translates to:
  /// **'{figure} est.'**
  String capacityEstimated(String figure);

  /// No description provided for @capacityResidentEstimated.
  ///
  /// In en, this message translates to:
  /// **'{figure} (estimated)'**
  String capacityResidentEstimated(String figure);

  /// No description provided for @capacityOccupancyUnknown.
  ///
  /// In en, this message translates to:
  /// **'{occupancy} / – (capacity unknown)'**
  String capacityOccupancyUnknown(int occupancy);

  /// No description provided for @capacityBasisPeak.
  ///
  /// In en, this message translates to:
  /// **'Estimated from the 2025 peak'**
  String get capacityBasisPeak;

  /// No description provided for @capacityBasisMedian.
  ///
  /// In en, this message translates to:
  /// **'Estimated: median of the same type of center'**
  String get capacityBasisMedian;

  /// No description provided for @cswdTransfersWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transfer request waiting} other{{count} transfer requests waiting}}'**
  String cswdTransfersWaiting(int count);

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackAgainToExit;

  /// No description provided for @yourAreaTitle.
  ///
  /// In en, this message translates to:
  /// **'Your area: Brgy. {name}'**
  String yourAreaTitle(String name);

  /// No description provided for @yourAreaStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Status not available yet. Pull down to refresh when online.'**
  String get yourAreaStatusUnavailable;

  /// No description provided for @staffBannerSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in as staff: {name}'**
  String staffBannerSignedIn(String name);

  /// No description provided for @staffBannerBack.
  ///
  /// In en, this message translates to:
  /// **'Staff Mode'**
  String get staffBannerBack;

  /// No description provided for @noSavedCopyYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing is saved on this phone yet: connect once to save it for offline use.'**
  String get noSavedCopyYet;

  /// No description provided for @situationEvacuationOrdered.
  ///
  /// In en, this message translates to:
  /// **'Evacuation ordered'**
  String get situationEvacuationOrdered;

  /// No description provided for @situationEvacuatingBarangays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 barangay is under preemptive or forced evacuation.} other{{count} barangays are under preemptive or forced evacuation.}}'**
  String situationEvacuatingBarangays(int count);

  /// No description provided for @situationOnWatch.
  ///
  /// In en, this message translates to:
  /// **'On watch'**
  String get situationOnWatch;

  /// No description provided for @situationWatchingBarangays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 barangay is on watch or has flooding reported.} other{{count} barangays are on watch or have flooding reported.}}'**
  String situationWatchingBarangays(int count);

  /// No description provided for @situationMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Being monitored'**
  String get situationMonitoring;

  /// No description provided for @situationNoEvacuation.
  ///
  /// In en, this message translates to:
  /// **'No barangay has to evacuate.'**
  String get situationNoEvacuation;

  /// No description provided for @statusNearlyFull.
  ///
  /// In en, this message translates to:
  /// **'Nearly full'**
  String get statusNearlyFull;

  /// No description provided for @requestStatusSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get requestStatusSent;

  /// No description provided for @requestStatusReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get requestStatusReceived;

  /// No description provided for @lockTitle.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lockTitle;

  /// No description provided for @lockAvailableWhenActive.
  ///
  /// In en, this message translates to:
  /// **'Available when the event is Active'**
  String get lockAvailableWhenActive;

  /// No description provided for @lockClosedEvent.
  ///
  /// In en, this message translates to:
  /// **'This event is closed. It is read-only.'**
  String get lockClosedEvent;

  /// No description provided for @durationLessThanMinute.
  ///
  /// In en, this message translates to:
  /// **'less than a minute'**
  String get durationLessThanMinute;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String durationMinutes(int count);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String durationHours(int count);

  /// No description provided for @durationDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String durationDays(int count);

  /// No description provided for @durationAgo.
  ///
  /// In en, this message translates to:
  /// **'{duration} ago'**
  String durationAgo(String duration);

  /// No description provided for @waitingDuration.
  ///
  /// In en, this message translates to:
  /// **'Waiting {duration}'**
  String waitingDuration(String duration);

  /// No description provided for @arrivingButton.
  ///
  /// In en, this message translates to:
  /// **'Families are arriving'**
  String get arrivingButton;

  /// No description provided for @arrivingTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell CSWD that families are arriving?'**
  String get arrivingTitle;

  /// No description provided for @arrivingBody.
  ///
  /// In en, this message translates to:
  /// **'CSWD is told right away. Nothing else changes: registration opens when CSWD starts the evacuation.'**
  String get arrivingBody;

  /// No description provided for @arrivingNote.
  ///
  /// In en, this message translates to:
  /// **'Note for CSWD (optional)'**
  String get arrivingNote;

  /// No description provided for @arrivingSend.
  ///
  /// In en, this message translates to:
  /// **'Tell CSWD'**
  String get arrivingSend;

  /// No description provided for @arrivingSent.
  ///
  /// In en, this message translates to:
  /// **'CSWD was told.'**
  String get arrivingSent;

  /// No description provided for @arrivingNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Needs a connection. CSWD has to hear this now, so it is not saved for later.'**
  String get arrivingNeedsConnection;

  /// No description provided for @registrationOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration is open'**
  String get registrationOpenTitle;

  /// No description provided for @registrationOpenBody.
  ///
  /// In en, this message translates to:
  /// **'{event} is now Active. Register families, check in your listed families and give relief.'**
  String registrationOpenBody(String event);

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planTitle;

  /// No description provided for @planForTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan for'**
  String get planForTitle;

  /// No description provided for @planForRange.
  ///
  /// In en, this message translates to:
  /// **'Forecast {low} to {high} families'**
  String planForRange(String low, String high);

  /// No description provided for @planAboveSeen.
  ///
  /// In en, this message translates to:
  /// **'Above anything seen before'**
  String get planAboveSeen;

  /// No description provided for @planNoForecast.
  ///
  /// In en, this message translates to:
  /// **'No forecast for this event yet.'**
  String get planNoForecast;

  /// No description provided for @planNoForecastVolcanic.
  ///
  /// In en, this message translates to:
  /// **'No forecast for volcanic events yet. Plan using the barangays inside the danger zone.'**
  String get planNoForecastVolcanic;

  /// No description provided for @planYourList.
  ///
  /// In en, this message translates to:
  /// **'Your list'**
  String get planYourList;

  /// No description provided for @planListNone.
  ///
  /// In en, this message translates to:
  /// **'No families listed yet'**
  String get planListNone;

  /// No description provided for @planListAdd.
  ///
  /// In en, this message translates to:
  /// **'List the families you expect to evacuate.'**
  String get planListAdd;

  /// No description provided for @planListCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'{checkedIn} of {families} checked in'**
  String planListCheckedIn(String checkedIn, String families);

  /// No description provided for @planSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Center space vs forecast'**
  String get planSpaceTitle;

  /// No description provided for @planSpaceFigure.
  ///
  /// In en, this message translates to:
  /// **'{space} spaces for {needed} persons'**
  String planSpaceFigure(String space, String needed);

  /// No description provided for @planSpaceShort.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Short of 1 space} other{Short of {count} spaces}}'**
  String planSpaceShort(int count);

  /// No description provided for @planSpaceEnough.
  ///
  /// In en, this message translates to:
  /// **'Enough space for the forecast'**
  String get planSpaceEnough;

  /// No description provided for @planSpaceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Space unknown: enter your centers\' capacities.'**
  String get planSpaceUnknown;

  /// No description provided for @planCentersWithoutCapacity.
  ///
  /// In en, this message translates to:
  /// **'{centers} without a capacity'**
  String planCentersWithoutCapacity(String centers);

  /// No description provided for @planCentersReady.
  ///
  /// In en, this message translates to:
  /// **'Centers ready'**
  String get planCentersReady;

  /// No description provided for @planOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total}'**
  String planOfTotal(String count, String total);

  /// No description provided for @statusUpdatedAgo.
  ///
  /// In en, this message translates to:
  /// **'Updated {ago}'**
  String statusUpdatedAgo(String ago);

  /// No description provided for @statusChange.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get statusChange;

  /// No description provided for @todoRequestSupplies.
  ///
  /// In en, this message translates to:
  /// **'Request supplies'**
  String get todoRequestSupplies;

  /// No description provided for @todoOpenCenters.
  ///
  /// In en, this message translates to:
  /// **'Open centers'**
  String get todoOpenCenters;

  /// No description provided for @listTitle.
  ///
  /// In en, this message translates to:
  /// **'Families to evacuate'**
  String get listTitle;

  /// No description provided for @listNotEvacuees.
  ///
  /// In en, this message translates to:
  /// **'A listed family is not an evacuee: it counts only once it is checked in.'**
  String get listNotEvacuees;

  /// No description provided for @listAdd.
  ///
  /// In en, this message translates to:
  /// **'Add family'**
  String get listAdd;

  /// No description provided for @listAdded.
  ///
  /// In en, this message translates to:
  /// **'Family added to the list.'**
  String get listAdded;

  /// No description provided for @listFromPast.
  ///
  /// In en, this message translates to:
  /// **'From past events'**
  String get listFromPast;

  /// No description provided for @listNewFamily.
  ///
  /// In en, this message translates to:
  /// **'New family'**
  String get listNewFamily;

  /// No description provided for @listSearchPast.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get listSearchPast;

  /// No description provided for @listNoPastFamilies.
  ///
  /// In en, this message translates to:
  /// **'No family from past events matches.'**
  String get listNoPastFamilies;

  /// No description provided for @listFromPastEvent.
  ///
  /// In en, this message translates to:
  /// **'From a past event'**
  String get listFromPastEvent;

  /// No description provided for @listHeadFirstName.
  ///
  /// In en, this message translates to:
  /// **'Head\'s first name'**
  String get listHeadFirstName;

  /// No description provided for @listHeadLastName.
  ///
  /// In en, this message translates to:
  /// **'Head\'s last name'**
  String get listHeadLastName;

  /// No description provided for @listMembersCount.
  ///
  /// In en, this message translates to:
  /// **'Members, with the head'**
  String get listMembersCount;

  /// No description provided for @listPurok.
  ///
  /// In en, this message translates to:
  /// **'Purok'**
  String get listPurok;

  /// No description provided for @listContactNumber.
  ///
  /// In en, this message translates to:
  /// **'Contact number (optional)'**
  String get listContactNumber;

  /// No description provided for @listNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get listNote;

  /// No description provided for @listCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get listCheckedIn;

  /// No description provided for @listCheckedInTag.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get listCheckedInTag;

  /// No description provided for @listCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get listCheckIn;

  /// No description provided for @listCheckInTitle.
  ///
  /// In en, this message translates to:
  /// **'Check in {head}'**
  String listCheckInTitle(String head);

  /// No description provided for @listCheckInQueued.
  ///
  /// In en, this message translates to:
  /// **'{head}: check-in saved. It is sent when online.'**
  String listCheckInQueued(String head);

  /// No description provided for @listedCheckInSummary.
  ///
  /// In en, this message translates to:
  /// **'Check in {head} at {place}'**
  String listedCheckInSummary(String head, String place);

  /// No description provided for @listAtCenter.
  ///
  /// In en, this message translates to:
  /// **'Evacuation center'**
  String get listAtCenter;

  /// No description provided for @listHostName.
  ///
  /// In en, this message translates to:
  /// **'Host\'s name'**
  String get listHostName;

  /// No description provided for @listHostPurok.
  ///
  /// In en, this message translates to:
  /// **'Host\'s purok'**
  String get listHostPurok;

  /// No description provided for @listHostAddress.
  ///
  /// In en, this message translates to:
  /// **'Host\'s address'**
  String get listHostAddress;

  /// No description provided for @listHighRisk.
  ///
  /// In en, this message translates to:
  /// **'High risk'**
  String get listHighRisk;

  /// No description provided for @listHighRiskPuroks.
  ///
  /// In en, this message translates to:
  /// **'High-risk puroks'**
  String get listHighRiskPuroks;

  /// No description provided for @listHighRiskHint.
  ///
  /// In en, this message translates to:
  /// **'Mark the puroks at high risk. Their families come first on the list.'**
  String get listHighRiskHint;

  /// No description provided for @listRiskFlood.
  ///
  /// In en, this message translates to:
  /// **'High risk of flooding'**
  String get listRiskFlood;

  /// No description provided for @listRiskLandslide.
  ///
  /// In en, this message translates to:
  /// **'High risk of landslide'**
  String get listRiskLandslide;

  /// No description provided for @listRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from the list'**
  String get listRemove;

  /// No description provided for @listRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {head} from the list?'**
  String listRemoveTitle(String head);

  /// No description provided for @listNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Needs a connection.'**
  String get listNeedsConnection;

  /// No description provided for @pendingCswdApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending CSWD approval'**
  String get pendingCswdApproval;

  /// No description provided for @centerNeedsDetails.
  ///
  /// In en, this message translates to:
  /// **'Needs details:'**
  String get centerNeedsDetails;

  /// No description provided for @centerNeedCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get centerNeedCapacity;

  /// No description provided for @centerNeedCapacityEst.
  ///
  /// In en, this message translates to:
  /// **'Capacity is an estimate'**
  String get centerNeedCapacityEst;

  /// No description provided for @centerNeedLocation.
  ///
  /// In en, this message translates to:
  /// **'Map location'**
  String get centerNeedLocation;

  /// No description provided for @centerNeedChecklist.
  ///
  /// In en, this message translates to:
  /// **'Facilities checklist'**
  String get centerNeedChecklist;

  /// No description provided for @centerLocationUseMine.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get centerLocationUseMine;

  /// No description provided for @centerLocationPickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on the map'**
  String get centerLocationPickOnMap;

  /// No description provided for @centerLocationCswdSaves.
  ///
  /// In en, this message translates to:
  /// **'As CSWD, the location is saved at once.'**
  String get centerLocationCswdSaves;

  /// No description provided for @centerMapPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Center location'**
  String get centerMapPickerTitle;

  /// No description provided for @centerMapPickerHint.
  ///
  /// In en, this message translates to:
  /// **'Move the map until the pin is on {center}\'s entrance.'**
  String centerMapPickerHint(String center);

  /// No description provided for @centerMapPickerUse.
  ///
  /// In en, this message translates to:
  /// **'Use this point'**
  String get centerMapPickerUse;

  /// No description provided for @centerMapPickerPin.
  ///
  /// In en, this message translates to:
  /// **'The chosen point'**
  String get centerMapPickerPin;

  /// No description provided for @centerMapPickerSatellite.
  ///
  /// In en, this message translates to:
  /// **'Switch map or satellite'**
  String get centerMapPickerSatellite;

  /// No description provided for @pendingCenterWarning.
  ///
  /// In en, this message translates to:
  /// **'Pending CSWD approval. You can register families here while the event is Active; CSWD is told at once.'**
  String get pendingCenterWarning;

  /// No description provided for @familyTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get familyTransfer;

  /// No description provided for @familyTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer {family}'**
  String familyTransferTitle(String family);

  /// No description provided for @familyMoveOurCenters.
  ///
  /// In en, this message translates to:
  /// **'To another of our centers'**
  String get familyMoveOurCenters;

  /// No description provided for @familyMoveNoOtherCenter.
  ///
  /// In en, this message translates to:
  /// **'Your barangay has no other center open.'**
  String get familyMoveNoOtherCenter;

  /// No description provided for @familyMoveOtherBarangay.
  ///
  /// In en, this message translates to:
  /// **'Another barangay\'s center accepts or declines.'**
  String get familyMoveOtherBarangay;

  /// No description provided for @familyMoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Move {family} ({members}) to {center}?'**
  String familyMoveConfirm(String family, String members, String center);

  /// No description provided for @familyMoveReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get familyMoveReason;

  /// No description provided for @familyMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get familyMove;

  /// No description provided for @familyMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved to {center}.'**
  String familyMoved(String center);

  /// No description provided for @centerAlmostFull.
  ///
  /// In en, this message translates to:
  /// **'This center is {percent}% full.'**
  String centerAlmostFull(int percent);

  /// No description provided for @askAnotherCenterForSpace.
  ///
  /// In en, this message translates to:
  /// **'Ask another center for space'**
  String get askAnotherCenterForSpace;

  /// No description provided for @reliefPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority: {label}'**
  String reliefPriority(String label);

  /// No description provided for @reliefFromBarangay.
  ///
  /// In en, this message translates to:
  /// **'From {barangay}'**
  String reliefFromBarangay(String barangay);

  /// No description provided for @reliefNotOurs.
  ///
  /// In en, this message translates to:
  /// **'Given by the barangay where they stay'**
  String get reliefNotOurs;

  /// No description provided for @reliefNeedRegistered.
  ///
  /// In en, this message translates to:
  /// **'Need (registered)'**
  String get reliefNeedRegistered;

  /// No description provided for @reliefNeedRegisteredBasis.
  ///
  /// In en, this message translates to:
  /// **'Need based on the registered count, not yet validated. Boxes can already be given.'**
  String get reliefNeedRegisteredBasis;

  /// No description provided for @reliefRoundOnePlan.
  ///
  /// In en, this message translates to:
  /// **'Round 1 plan'**
  String get reliefRoundOnePlan;

  /// No description provided for @reliefRoundOneFromList.
  ///
  /// In en, this message translates to:
  /// **'One box per family on your list.'**
  String get reliefRoundOneFromList;

  /// No description provided for @reliefRoundOneFromForecast.
  ///
  /// In en, this message translates to:
  /// **'One box per family at the high end of the forecast.'**
  String get reliefRoundOneFromForecast;

  /// No description provided for @reliefRoundOneOneBox.
  ///
  /// In en, this message translates to:
  /// **'One box per family: your list or the forecast, whichever is more.'**
  String get reliefRoundOneOneBox;

  /// No description provided for @quantityWithUnit.
  ///
  /// In en, this message translates to:
  /// **'{quantity} {unit}'**
  String quantityWithUnit(String quantity, String unit);

  /// No description provided for @facilityApprovedOf.
  ///
  /// In en, this message translates to:
  /// **'Approved {approved} of {asked}'**
  String facilityApprovedOf(String approved, String asked);

  /// No description provided for @facilityMarkReceived.
  ///
  /// In en, this message translates to:
  /// **'Mark received'**
  String get facilityMarkReceived;

  /// No description provided for @facilityReceiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark this request received?'**
  String get facilityReceiveTitle;

  /// No description provided for @facilityReceiveSummary.
  ///
  /// In en, this message translates to:
  /// **'Received: {what} at {center}'**
  String facilityReceiveSummary(String what, String center);

  /// No description provided for @facilityRequestAgain.
  ///
  /// In en, this message translates to:
  /// **'Request again'**
  String get facilityRequestAgain;

  /// No description provided for @facilityRequestUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit (optional)'**
  String get facilityRequestUnit;

  /// No description provided for @facilityRequestUnitHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. pieces, boxes, liters'**
  String get facilityRequestUnitHint;

  /// No description provided for @facilitySuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested for your centers'**
  String get facilitySuggested;

  /// No description provided for @facilitySuggestedHint.
  ///
  /// In en, this message translates to:
  /// **'What each center is short of for a full center, minus what you already asked.'**
  String get facilitySuggestedHint;

  /// No description provided for @facilitySuggestedNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing to suggest: your centers have what the standards ask, or it is already requested.'**
  String get facilitySuggestedNone;

  /// No description provided for @facilityYourRequests.
  ///
  /// In en, this message translates to:
  /// **'Your requests'**
  String get facilityYourRequests;

  /// No description provided for @facilityRequestWhichCenter.
  ///
  /// In en, this message translates to:
  /// **'For which center?'**
  String get facilityRequestWhichCenter;

  /// No description provided for @finalCountNothingNew.
  ///
  /// In en, this message translates to:
  /// **'Nothing new since your validated count.'**
  String get finalCountNothingNew;

  /// No description provided for @alertLevelEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get alertLevelEmergency;

  /// No description provided for @alertLevelAdvisory.
  ///
  /// In en, this message translates to:
  /// **'Advisory'**
  String get alertLevelAdvisory;

  /// No description provided for @alertLevelInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get alertLevelInfo;

  /// No description provided for @alertLevelAllClear.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get alertLevelAllClear;

  /// No description provided for @alertNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get alertNew;

  /// No description provided for @passwordChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your password'**
  String get passwordChangeTitle;

  /// No description provided for @passwordChangeBody.
  ///
  /// In en, this message translates to:
  /// **'You signed in with a temporary password. Choose your own before you continue. Your other sign-ins on other phones end.'**
  String get passwordChangeBody;

  /// No description provided for @passwordCurrent.
  ///
  /// In en, this message translates to:
  /// **'Temporary (current) password'**
  String get passwordCurrent;

  /// No description provided for @passwordNew.
  ///
  /// In en, this message translates to:
  /// **'New password (at least 10 characters)'**
  String get passwordNew;

  /// No description provided for @passwordConfirm.
  ///
  /// In en, this message translates to:
  /// **'New password again'**
  String get passwordConfirm;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters.'**
  String get passwordTooShort;

  /// No description provided for @passwordSameAsOld.
  ///
  /// In en, this message translates to:
  /// **'Choose a password different from the temporary one.'**
  String get passwordSameAsOld;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two passwords are not the same.'**
  String get passwordMismatch;

  /// No description provided for @passwordSave.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get passwordSave;

  /// No description provided for @passwordShow.
  ///
  /// In en, this message translates to:
  /// **'Show or hide the password'**
  String get passwordShow;

  /// No description provided for @maintenanceDefault.
  ///
  /// In en, this message translates to:
  /// **'E-LIKAS is being updated. Try again later.'**
  String get maintenanceDefault;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportTitle;

  /// No description provided for @reportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell the administrator what went wrong'**
  String get reportSubtitle;

  /// No description provided for @reportIntro.
  ///
  /// In en, this message translates to:
  /// **'The administrator reads every report and answers here.'**
  String get reportIntro;

  /// No description provided for @reportWhatHappened.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get reportWhatHappened;

  /// No description provided for @reportWhatHappenedHint.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters. What you did, what you expected, what you saw.'**
  String get reportWhatHappenedHint;

  /// No description provided for @reportScreen.
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get reportScreen;

  /// No description provided for @reportPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo (optional)'**
  String get reportPhoto;

  /// No description provided for @reportPhotoPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Do not include evacuees\' names or details in the photo.'**
  String get reportPhotoPrivacy;

  /// No description provided for @reportPhotoCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get reportPhotoCamera;

  /// No description provided for @reportPhotoGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get reportPhotoGallery;

  /// No description provided for @reportPhotoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove the photo'**
  String get reportPhotoRemove;

  /// No description provided for @reportPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get the photo.'**
  String get reportPhotoFailed;

  /// No description provided for @reportSend.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get reportSend;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent. The administrator will answer here.'**
  String get reportSent;

  /// No description provided for @reportNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Needs a connection.'**
  String get reportNeedsConnection;

  /// No description provided for @reportYours.
  ///
  /// In en, this message translates to:
  /// **'Your reports'**
  String get reportYours;

  /// No description provided for @reportNone.
  ///
  /// In en, this message translates to:
  /// **'No reports yet.'**
  String get reportNone;

  /// No description provided for @reportReply.
  ///
  /// In en, this message translates to:
  /// **'Reply from {name}: {reply}'**
  String reportReply(String name, String reply);

  /// No description provided for @cswdNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Needs a connection. This tells people now, so it is not saved for later.'**
  String get cswdNeedsConnection;

  /// No description provided for @cswdStartTitle.
  ///
  /// In en, this message translates to:
  /// **'{event} is being monitored'**
  String cswdStartTitle(String event);

  /// No description provided for @cswdStartHint.
  ///
  /// In en, this message translates to:
  /// **'Registration, relief, transfers and final counts open when you start the evacuation.'**
  String get cswdStartHint;

  /// No description provided for @cswdStartEvacuation.
  ///
  /// In en, this message translates to:
  /// **'Start evacuation'**
  String get cswdStartEvacuation;

  /// No description provided for @cswdStartConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Start the evacuation for {event}?'**
  String cswdStartConfirmTitle(String event);

  /// No description provided for @cswdStartConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The event becomes Active. Every barangay official is told that registration is open. This cannot be undone from the app.'**
  String get cswdStartConfirmBody;

  /// No description provided for @cswdStartDone.
  ///
  /// In en, this message translates to:
  /// **'{event} is now Active.'**
  String cswdStartDone(String event);

  /// No description provided for @cswdAskUpdate.
  ///
  /// In en, this message translates to:
  /// **'Ask barangay to update'**
  String get cswdAskUpdate;

  /// No description provided for @cswdAskUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask {barangay} to update its status?'**
  String cswdAskUpdateTitle(String barangay);

  /// No description provided for @cswdAskUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'The barangay\'s officials get a notification. Their status stays theirs to set.'**
  String get cswdAskUpdateBody;

  /// No description provided for @cswdAskUpdateDone.
  ///
  /// In en, this message translates to:
  /// **'{barangay} was asked to update.'**
  String cswdAskUpdateDone(String barangay);

  /// No description provided for @cswdRemind.
  ///
  /// In en, this message translates to:
  /// **'Remind'**
  String get cswdRemind;

  /// No description provided for @cswdRemindFinalCount.
  ///
  /// In en, this message translates to:
  /// **'Remind final count'**
  String get cswdRemindFinalCount;

  /// No description provided for @cswdRemindTitle.
  ///
  /// In en, this message translates to:
  /// **'Remind {barangay} to send its final count?'**
  String cswdRemindTitle(String barangay);

  /// No description provided for @cswdRemindBody.
  ///
  /// In en, this message translates to:
  /// **'The barangay\'s officials get a notification.'**
  String get cswdRemindBody;

  /// No description provided for @cswdRemindDone.
  ///
  /// In en, this message translates to:
  /// **'{barangay} was reminded.'**
  String cswdRemindDone(String barangay);

  /// No description provided for @cswdProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Evacuation progress'**
  String get cswdProgressTitle;

  /// No description provided for @cswdProgressHint.
  ///
  /// In en, this message translates to:
  /// **'Registered families against each barangay\'s list of families to evacuate. Behind first.'**
  String get cswdProgressHint;

  /// No description provided for @cswdProgressLine.
  ///
  /// In en, this message translates to:
  /// **'{registered} of {expected} expected families registered'**
  String cswdProgressLine(String registered, String expected);

  /// No description provided for @cswdProgressNoList.
  ///
  /// In en, this message translates to:
  /// **'{families} registered · no list'**
  String cswdProgressNoList(String families);

  /// No description provided for @cswdProgressListCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'{checkedIn} of {listed} listed families checked in'**
  String cswdProgressListCheckedIn(String checkedIn, String listed);

  /// No description provided for @cswdProgressNone.
  ///
  /// In en, this message translates to:
  /// **'No barangay figures yet.'**
  String get cswdProgressNone;

  /// No description provided for @orderForcedTitle.
  ///
  /// In en, this message translates to:
  /// **'Forced evacuation: {barangay}'**
  String orderForcedTitle(String barangay);

  /// No description provided for @orderPreemptiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Preemptive evacuation: {barangay}'**
  String orderPreemptiveTitle(String barangay);

  /// No description provided for @orderForcedBody.
  ///
  /// In en, this message translates to:
  /// **'Leave now. Go to the nearest open evacuation center and follow your barangay officials.'**
  String get orderForcedBody;

  /// No description provided for @orderPreemptiveBody.
  ///
  /// In en, this message translates to:
  /// **'Prepare to leave and go to the nearest open evacuation center. Bring your go-bag.'**
  String get orderPreemptiveBody;

  /// No description provided for @orderGoToCenter.
  ///
  /// In en, this message translates to:
  /// **'Nearest open centers'**
  String get orderGoToCenter;

  /// No description provided for @safeCentersTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearest safe centers'**
  String get safeCentersTitle;

  /// No description provided for @safeCentersHint.
  ///
  /// In en, this message translates to:
  /// **'Open centers only: never full, closed or inside Mayon\'s permanent danger zone.'**
  String get safeCentersHint;

  /// No description provided for @safeCentersHintVolcanic.
  ///
  /// In en, this message translates to:
  /// **'Volcanic event: centers within 7 km of Mayon\'s summit are left out.'**
  String get safeCentersHintVolcanic;

  /// No description provided for @hazardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hazards'**
  String get hazardsTitle;

  /// No description provided for @hazardsTitleFor.
  ///
  /// In en, this message translates to:
  /// **'Hazards in {barangay}'**
  String hazardsTitleFor(String barangay);

  /// No description provided for @mayonInsidePermanent.
  ///
  /// In en, this message translates to:
  /// **'Mayon: part of your barangay is inside the 6 km permanent danger zone.'**
  String get mayonInsidePermanent;

  /// No description provided for @mayonInsideExtended.
  ///
  /// In en, this message translates to:
  /// **'Mayon: part of your barangay is inside the 7 km extended danger zone.'**
  String get mayonInsideExtended;

  /// No description provided for @mayonDistance.
  ///
  /// In en, this message translates to:
  /// **'Mayon: your barangay is {km} km from the summit, outside the danger zones.'**
  String mayonDistance(String km);

  /// No description provided for @mayonZoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Approximate zone based on distance from the summit. Follow PHIVOLCS bulletins.'**
  String get mayonZoneLabel;

  /// No description provided for @hazardsWhatToDo.
  ///
  /// In en, this message translates to:
  /// **'What to do'**
  String get hazardsWhatToDo;

  /// No description provided for @hazardsWhatToDoHint.
  ///
  /// In en, this message translates to:
  /// **'Typhoon, flood and volcano: short steps, checklists and your family plan.'**
  String get hazardsWhatToDoHint;

  /// No description provided for @prepTitle.
  ///
  /// In en, this message translates to:
  /// **'Be prepared'**
  String get prepTitle;

  /// No description provided for @prepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Go-bag, checklists and your family plan, also offline'**
  String get prepSubtitle;

  /// No description provided for @prepUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The checklists could not be opened.'**
  String get prepUnavailable;

  /// No description provided for @prepChecklists.
  ///
  /// In en, this message translates to:
  /// **'Checklists'**
  String get prepChecklists;

  /// No description provided for @prepProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} ready'**
  String prepProgress(int done, int total);

  /// No description provided for @prepSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {agency} guidance · for team review'**
  String prepSource(String agency);

  /// No description provided for @familyPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Family emergency plan'**
  String get familyPlanTitle;

  /// No description provided for @familyPlanPhoneOnly.
  ///
  /// In en, this message translates to:
  /// **'Kept on this phone only. Never sent anywhere.'**
  String get familyPlanPhoneOnly;

  /// No description provided for @familyPlanMeetingPoint.
  ///
  /// In en, this message translates to:
  /// **'Meeting point'**
  String get familyPlanMeetingPoint;

  /// No description provided for @familyPlanMeetingPointHint.
  ///
  /// In en, this message translates to:
  /// **'Where the family meets if you are apart.'**
  String get familyPlanMeetingPointHint;

  /// No description provided for @familyPlanContacts.
  ///
  /// In en, this message translates to:
  /// **'Contact numbers'**
  String get familyPlanContacts;

  /// No description provided for @familyPlanName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get familyPlanName;

  /// No description provided for @familyPlanNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get familyPlanNumber;

  /// No description provided for @familyPlanAddContact.
  ///
  /// In en, this message translates to:
  /// **'Add a contact'**
  String get familyPlanAddContact;

  /// No description provided for @familyPlanSpecialNeeds.
  ///
  /// In en, this message translates to:
  /// **'Members with special needs'**
  String get familyPlanSpecialNeeds;

  /// No description provided for @familyPlanSpecialNeedsHint.
  ///
  /// In en, this message translates to:
  /// **'Babies, older people, persons with disability, someone who needs medicine.'**
  String get familyPlanSpecialNeedsHint;

  /// No description provided for @familyPlanNeed.
  ///
  /// In en, this message translates to:
  /// **'What they need'**
  String get familyPlanNeed;

  /// No description provided for @familyPlanAddPerson.
  ///
  /// In en, this message translates to:
  /// **'Add a person'**
  String get familyPlanAddPerson;

  /// No description provided for @familyPlanSave.
  ///
  /// In en, this message translates to:
  /// **'Save on this phone'**
  String get familyPlanSave;

  /// No description provided for @familyPlanSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone.'**
  String get familyPlanSaved;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @textSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get textSizeNormal;

  /// No description provided for @textSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeLarge;

  /// No description provided for @textSizeLarger.
  ///
  /// In en, this message translates to:
  /// **'Larger'**
  String get textSizeLarger;

  /// No description provided for @pushPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency notifications'**
  String get pushPermissionTitle;

  /// No description provided for @pushPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'E-LIKAS tells you about emergency alerts and evacuation orders for your barangay.'**
  String get pushPermissionBody;

  /// No description provided for @pushPermissionAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get pushPermissionAllow;

  /// No description provided for @pushPermissionLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get pushPermissionLater;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @pushTestRevealed.
  ///
  /// In en, this message translates to:
  /// **'Test notifications option shown.'**
  String get pushTestRevealed;

  /// No description provided for @pushTestOption.
  ///
  /// In en, this message translates to:
  /// **'Receive test notifications'**
  String get pushTestOption;

  /// No description provided for @pushTestOptionHint.
  ///
  /// In en, this message translates to:
  /// **'For demonstrations: only the administrator\'s test push.'**
  String get pushTestOptionHint;

  /// No description provided for @planSpaceEstimated.
  ///
  /// In en, this message translates to:
  /// **'Part of this room is only an estimate'**
  String get planSpaceEstimated;

  /// No description provided for @planReadyBelow.
  ///
  /// In en, this message translates to:
  /// **'{count} short of the standard'**
  String planReadyBelow(String count);

  /// No description provided for @planReadyNoChecklist.
  ///
  /// In en, this message translates to:
  /// **'{count} without a checklist'**
  String planReadyNoChecklist(String count);

  /// No description provided for @planReadyNoCapacity.
  ///
  /// In en, this message translates to:
  /// **'{count} without a capacity'**
  String planReadyNoCapacity(String count);

  /// No description provided for @centerNeedSupplies.
  ///
  /// In en, this message translates to:
  /// **'Supplies short'**
  String get centerNeedSupplies;

  /// No description provided for @centerReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get centerReady;

  /// No description provided for @facilityForCenter.
  ///
  /// In en, this message translates to:
  /// **'For {center}'**
  String facilityForCenter(String center);

  /// No description provided for @facilityShowAllCenters.
  ///
  /// In en, this message translates to:
  /// **'Show all centers'**
  String get facilityShowAllCenters;

  /// No description provided for @facilityEditSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Change before sending'**
  String get facilityEditSuggestion;

  /// No description provided for @reliefOutOfOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Give a box to this family?'**
  String get reliefOutOfOrderTitle;

  /// No description provided for @reliefOutOfOrderBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 higher-priority family has not received a box yet. Continue?} other{{count} higher-priority families have not received a box yet. Continue?}}'**
  String reliefOutOfOrderBody(int count);

  /// No description provided for @reliefStayingElsewhereTitle.
  ///
  /// In en, this message translates to:
  /// **'Staying in another barangay'**
  String get reliefStayingElsewhereTitle;

  /// No description provided for @reliefStayingElsewhereNote.
  ///
  /// In en, this message translates to:
  /// **'Your families staying in another barangay\'s center. That barangay gives their box.'**
  String get reliefStayingElsewhereNote;

  /// No description provided for @reliefStayingIn.
  ///
  /// In en, this message translates to:
  /// **'Staying in {place}'**
  String reliefStayingIn(String place);

  /// No description provided for @reliefBoxFrom.
  ///
  /// In en, this message translates to:
  /// **'{barangay} gives the box'**
  String reliefBoxFrom(String barangay);

  /// No description provided for @reliefNotGivenYet.
  ///
  /// In en, this message translates to:
  /// **'No box yet'**
  String get reliefNotGivenYet;

  /// No description provided for @reliefPrivateHouse.
  ///
  /// In en, this message translates to:
  /// **'Private house ({host})'**
  String reliefPrivateHouse(String host);

  /// No description provided for @listAddSummary.
  ///
  /// In en, this message translates to:
  /// **'Add {name} to the families to evacuate'**
  String listAddSummary(String name);

  /// No description provided for @listAddQueued.
  ///
  /// In en, this message translates to:
  /// **'Added. It is sent to the list when there is a connection.'**
  String get listAddQueued;

  /// No description provided for @listAddsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Added on this phone, waiting to sync'**
  String get listAddsWaiting;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bcl', 'en', 'fil'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bcl':
      return AppLocalizationsBcl();
    case 'en':
      return AppLocalizationsEn();
    case 'fil':
      return AppLocalizationsFil();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
