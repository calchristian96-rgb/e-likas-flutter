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
  /// **'Mandatory'**
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

  /// No description provided for @staffWorkspacePendingRegistrationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline queue — review, edit, and sync'**
  String get staffWorkspacePendingRegistrationsSubtitle;

  /// No description provided for @staffWorkspaceAllEvacuees.
  ///
  /// In en, this message translates to:
  /// **'All Evacuees'**
  String get staffWorkspaceAllEvacuees;

  /// No description provided for @staffWorkspaceAllEvacueesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse registered families'**
  String get staffWorkspaceAllEvacueesSubtitle;

  /// No description provided for @staffWorkspaceSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get staffWorkspaceSyncNow;

  /// No description provided for @staffWorkspaceSyncNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Push pending registrations and refresh cached data'**
  String get staffWorkspaceSyncNowSubtitle;

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

  /// No description provided for @staffFamiliesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Registered Families'**
  String get staffFamiliesPageTitle;

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
  /// **'Outside evacuation center'**
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
  /// **'Email'**
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
  /// **'Age Bracket'**
  String get ecBoardFieldAgeBracket;

  /// No description provided for @ecBoardFieldHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get ecBoardFieldHousehold;

  /// No description provided for @ecBoardHouseholdExisting.
  ///
  /// In en, this message translates to:
  /// **'Existing household'**
  String get ecBoardHouseholdExisting;

  /// No description provided for @ecBoardHouseholdNew.
  ///
  /// In en, this message translates to:
  /// **'New household'**
  String get ecBoardHouseholdNew;

  /// No description provided for @ecBoardSelectHouseholdButton.
  ///
  /// In en, this message translates to:
  /// **'Select household'**
  String get ecBoardSelectHouseholdButton;

  /// No description provided for @ecBoardHouseholdSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by head of family name'**
  String get ecBoardHouseholdSearchHint;

  /// No description provided for @ecBoardRefreshHouseholdsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh household list'**
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
  /// **'New household from this device — not yet synced'**
  String get ecBoardPendingNewHouseholdBadge;

  /// No description provided for @ecBoardPendingHouseholdNotice.
  ///
  /// In en, this message translates to:
  /// **'This household hasn\'t synced yet. This entry will sync automatically once it does.'**
  String get ecBoardPendingHouseholdNotice;

  /// No description provided for @ecBoardNewHouseholdHeadName.
  ///
  /// In en, this message translates to:
  /// **'Head of Household Name'**
  String get ecBoardNewHouseholdHeadName;

  /// No description provided for @ecBoardSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Save Evacuee'**
  String get ecBoardSubmitButton;

  /// No description provided for @ecBoardValidationBanner.
  ///
  /// In en, this message translates to:
  /// **'Please complete sex, age bracket, and household before saving.'**
  String get ecBoardValidationBanner;

  /// No description provided for @ecBoardSavedOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved offline. It will sync when you\'re back online.'**
  String get ecBoardSavedOfflineMessage;

  /// No description provided for @ecBoardSavedPendingHouseholdMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved — waiting for the selected household to sync first.'**
  String get ecBoardSavedPendingHouseholdMessage;

  /// No description provided for @ecBoardSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Evacuee added successfully.'**
  String get ecBoardSuccessMessage;

  /// No description provided for @ecBoardNoEventsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No evacuation events are available yet.'**
  String get ecBoardNoEventsAvailable;

  /// No description provided for @ecBoardLastKnownSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Last Known Breakdown'**
  String get ecBoardLastKnownSectionTitle;

  /// No description provided for @ecBoardLastKnownSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live count of evacuees already confirmed on the server.'**
  String get ecBoardLastKnownSectionSubtitle;

  /// No description provided for @ecBoardLastKnownUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not load the last known breakdown.'**
  String get ecBoardLastKnownUnavailable;

  /// No description provided for @ecBoardLastKnownEmpty.
  ///
  /// In en, this message translates to:
  /// **'No evacuees recorded for this center and event yet.'**
  String get ecBoardLastKnownEmpty;

  /// No description provided for @ecBoardLastKnownFromCacheNotice.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing the last confirmed figures saved on this device.'**
  String get ecBoardLastKnownFromCacheNotice;

  /// No description provided for @ecBoardUnclassifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Unclassified'**
  String get ecBoardUnclassifiedLabel;

  /// No description provided for @ecBoardPendingSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'This Device\'s Pending Entries'**
  String get ecBoardPendingSectionTitle;

  /// No description provided for @ecBoardPendingSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Not yet synced — kept separate from the confirmed count above.'**
  String get ecBoardPendingSectionSubtitle;

  /// No description provided for @ecBoardSyncNowInlineButton.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get ecBoardSyncNowInlineButton;

  /// No description provided for @ecBoardPendingListTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Entries'**
  String get ecBoardPendingListTitle;

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

  /// Compact male/female count pair shown next to each age bracket row
  ///
  /// In en, this message translates to:
  /// **'{male}M / {female}F'**
  String ecBoardMaleFemaleCount(int male, int female);

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

  /// No description provided for @ecBoardSectoralGroupsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sectoral Groups'**
  String get ecBoardSectoralGroupsSectionTitle;

  /// No description provided for @ecBoardSectoralGroupsSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Staff-reported totals, entered separately from Add Evacuee.'**
  String get ecBoardSectoralGroupsSectionSubtitle;

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

  /// No description provided for @ecBoardSyncNowExplanation.
  ///
  /// In en, this message translates to:
  /// **'Sync Now sends your offline entries (new evacuees, sectoral updates) to the server.'**
  String get ecBoardSyncNowExplanation;

  /// No description provided for @ecBoardSectoralEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit Sectoral & 4Ps'**
  String get ecBoardSectoralEditButton;

  /// No description provided for @ecBoardFamiliesLabel.
  ///
  /// In en, this message translates to:
  /// **'Families'**
  String get ecBoardFamiliesLabel;

  /// No description provided for @ecBoardPersonsLabel.
  ///
  /// In en, this message translates to:
  /// **'Persons'**
  String get ecBoardPersonsLabel;

  /// No description provided for @ecBoardNowLabel.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get ecBoardNowLabel;

  /// Small caption under a Now figure, e.g. '12 cumulative'
  ///
  /// In en, this message translates to:
  /// **'{count} cumulative'**
  String ecBoardCumulativeValue(int count);

  /// No description provided for @ecBoardFourPsBeneficiaryFamilies.
  ///
  /// In en, this message translates to:
  /// **'4Ps Beneficiary Families'**
  String get ecBoardFourPsBeneficiaryFamilies;

  /// Footer line under the sectoral breakdown naming who last saved it
  ///
  /// In en, this message translates to:
  /// **'Last updated by {name}'**
  String ecBoardSectoralUpdatedBy(String name);

  /// No description provided for @ecBoardPendingSectoralCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending sectoral update'**
  String get ecBoardPendingSectoralCardTitle;

  /// No description provided for @ecBoardPendingSectoralCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Not yet synced — tap to review or edit.'**
  String get ecBoardPendingSectoralCardSubtitle;

  /// No description provided for @ecBoardSectoralFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Sectoral & 4Ps Report'**
  String get ecBoardSectoralFormTitle;

  /// No description provided for @ecBoardSectoralFormSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manually-reported totals for this center and event — separate from Add Evacuee.'**
  String get ecBoardSectoralFormSubtitle;

  /// No description provided for @ecBoardSectoralFormFieldsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the number of people in each category.'**
  String get ecBoardSectoralFormFieldsHint;

  /// No description provided for @ecBoardSectoralSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Sectoral & 4Ps'**
  String get ecBoardSectoralSaveButton;

  /// No description provided for @ecBoardSectoralSavedOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved offline. This will sync when you\'re back online.'**
  String get ecBoardSectoralSavedOfflineMessage;

  /// No description provided for @ecBoardSectoralSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Sectoral & 4Ps report updated successfully.'**
  String get ecBoardSectoralSuccessMessage;

  /// No description provided for @ecBoardQuickDepartureTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Departure'**
  String get ecBoardQuickDepartureTitle;

  /// No description provided for @ecBoardQuickDepartureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mark people currently at this center as departed, by age bracket, sex, and quantity.'**
  String get ecBoardQuickDepartureSubtitle;

  /// No description provided for @ecBoardQuickDepartureQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get ecBoardQuickDepartureQuantity;

  /// No description provided for @ecBoardQuickDepartureStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ecBoardQuickDepartureStatus;

  /// No description provided for @ecBoardQuickDepartureReturnedHome.
  ///
  /// In en, this message translates to:
  /// **'Returned home'**
  String get ecBoardQuickDepartureReturnedHome;

  /// No description provided for @ecBoardQuickDepartureTransferred.
  ///
  /// In en, this message translates to:
  /// **'Transferred'**
  String get ecBoardQuickDepartureTransferred;

  /// No description provided for @ecBoardQuickDepartureSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Mark as Departed'**
  String get ecBoardQuickDepartureSubmitButton;

  /// No description provided for @ecBoardQuickDepartureValidationBanner.
  ///
  /// In en, this message translates to:
  /// **'Please select sex, age bracket, quantity, and status.'**
  String get ecBoardQuickDepartureValidationBanner;

  /// No description provided for @ecBoardQuickDepartureSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Marked as departed.'**
  String get ecBoardQuickDepartureSuccessMessage;

  /// No description provided for @ecBoardQuickDepartureOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'Quick Departure requires an internet connection.'**
  String get ecBoardQuickDepartureOfflineMessage;

  /// No description provided for @ecBoardQuickDepartureOfflineExplanation.
  ///
  /// In en, this message translates to:
  /// **'Quick Departure requires an internet connection, since it needs to check who\'s currently confirmed at this center.'**
  String get ecBoardQuickDepartureOfflineExplanation;
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
