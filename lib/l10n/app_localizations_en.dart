// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navMap => 'GIS Map';

  @override
  String get navNearestCenter => 'Nearest Center';

  @override
  String get navAlerts => 'Alerts';

  @override
  String get navHotlines => 'Hotlines';

  @override
  String get navSettings => 'Settings';

  @override
  String get online => 'Online';

  @override
  String get offlineModeLabel => 'Offline mode';

  @override
  String get offline => 'Offline';

  @override
  String get live => 'Live';

  @override
  String get cached => 'Cached';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get freshnessCaution => 'Caution';

  @override
  String get freshnessSavedVerb => 'Saved';

  @override
  String get freshnessLastUpdatedVerb => 'Last updated';

  @override
  String get viewAlertsTooltip => 'View alerts';

  @override
  String get couldNotLoadCenters => 'Could not load centers';

  @override
  String get viewRoute => 'View route';

  @override
  String get invalidAlertLink => 'That alert link isn\'t valid.';

  @override
  String callNumberTooltip(String number) {
    return 'Call $number';
  }

  @override
  String copyNumberTooltip(String number) {
    return 'Copy $number to clipboard';
  }

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get viewAll => 'View all';

  @override
  String get viewDetails => 'View details';

  @override
  String get getDirections => 'Get directions';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get copy => 'Copy';

  @override
  String get call => 'Call';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get view => 'View';

  @override
  String get tryAgain => 'Try again';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFilipino => 'Filipino';

  @override
  String get languageBikolLigao => 'Bikol (Ligao)';

  @override
  String get preparingEmergencyInfo => 'Preparing emergency information…';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get stayInformedSubtitle => 'Stay informed and prepared.';

  @override
  String get dashboardSummary => 'Dashboard summary';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get viewAllEvacuationCenters => 'View All Evacuation Centers';

  @override
  String get refreshData => 'Refresh Data';

  @override
  String get emergencyHotlines => 'Emergency Hotlines';

  @override
  String get statEvacuationCenters => 'Evacuation centers';

  @override
  String get statPublicAlerts => 'Public alerts';

  @override
  String get statDataStatus => 'Data status';

  @override
  String get noDataYet => 'No data yet';

  @override
  String get nearestEvacuationCenterHeading => 'Nearest evacuation center';

  @override
  String get recentAlerts => 'Recent alerts';

  @override
  String get safetyTips => 'Safety tips';

  @override
  String get noActiveAlerts => 'No active alerts';

  @override
  String get noActiveEmergencyAlerts => 'No active emergency alerts';

  @override
  String get normalMonitoring =>
      'Ligao City is currently under normal monitoring.';

  @override
  String get liveDataUnavailable => 'Live data is temporarily unavailable';

  @override
  String get showingSavedInfo => 'Showing the latest saved information.';

  @override
  String get nearestCenterUnavailable => 'Nearest center unavailable';

  @override
  String get enableLocationServices =>
      'Enable location services or try again later.';

  @override
  String get noNearbyEvacuationCenters =>
      'No nearby evacuation centers to show yet.';

  @override
  String get youAreViewingLiveData => 'You\'re viewing live data.';

  @override
  String get checkingForAlerts => 'Checking for emergency alerts…';

  @override
  String get alertsTitle => 'Alerts';

  @override
  String get alertDetailsTitle => 'Alert details';

  @override
  String get noPublicAlerts => 'No public alerts to show yet.';

  @override
  String get dateUnavailable => 'Date unavailable';

  @override
  String get sentBy => 'Sent by';

  @override
  String get sentTo => 'Sent to';

  @override
  String get evacuationEvent => 'Evacuation event';

  @override
  String get couldNotLoadAlerts => 'Could not load alerts';

  @override
  String get newAlertReceived => 'New alert received';

  @override
  String get newAdvisoryReceived => 'New advisory received';

  @override
  String get emergencyAlertReceived => 'Emergency alert received';

  @override
  String get newInformationAlert => 'New information alert';

  @override
  String get allClearUpdateReceived => 'All-clear update received';

  @override
  String get severityMandatory => 'Mandatory';

  @override
  String get severityAdvisory => 'Advisory';

  @override
  String get severityInfo => 'Info';

  @override
  String get severityAllClear => 'All clear';

  @override
  String get statusActive => 'Active';

  @override
  String get statusFull => 'Full';

  @override
  String get statusClosed => 'Closed';

  @override
  String get statusOnStandby => 'On standby';

  @override
  String get evacuationCentersTitle => 'Evacuation centers';

  @override
  String get noEvacuationCenters => 'No evacuation centers to show yet.';

  @override
  String evacuationCentersCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString evacuation centers',
      one: '1 evacuation center',
    );
    return '$_temp0';
  }

  @override
  String publicAlertsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString public alerts',
      one: '1 public alert',
    );
    return '$_temp0';
  }

  @override
  String get nearestCenterTitle => 'Nearest center';

  @override
  String get locationPermissionDenied => 'Location permission was denied.';

  @override
  String get locationServicesOff => 'Location services are turned off.';

  @override
  String get locationPermanentlyDenied =>
      'Location permission is permanently denied — enable it in system settings.';

  @override
  String get couldNotDetermineLocation =>
      'Could not determine current location.';

  @override
  String get couldNotLoadNearbyCenters => 'Could not load nearby centers';

  @override
  String get emergencyHotlinesTitle => 'Emergency Hotlines';

  @override
  String get hotlinesOfflineNote =>
      'These numbers are saved on your device and work even without internet.';

  @override
  String get couldNotOpenDialer =>
      'Could not open the phone dialer — use Copy Number to dial manually.';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get weatherNotYetAvailable =>
      'Weather updates are not yet available in this app.';

  @override
  String get cancel => 'Cancel';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionOfflineData => 'Offline & Data';

  @override
  String get settingsOfflineData => 'Offline Data';

  @override
  String get settingsOfflineDataSubtitle =>
      'Manage saved data for offline access';

  @override
  String get settingsSyncNow => 'Sync Now';

  @override
  String get settingsSyncButton => 'Sync';

  @override
  String get settingsSyncNeverRun => 'Not yet synced';

  @override
  String get settingsConnectivity => 'Connectivity';

  @override
  String get settingsSectionPreferences => 'Preferences';

  @override
  String get appAppearance => 'App Appearance';

  @override
  String get appearanceSystem => 'System default';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get settingsSectionStaff => 'Staff';

  @override
  String get settingsStaffAccess => 'Staff Access';

  @override
  String get settingsStaffAccessSubtitle =>
      'Register families and manage evacuation records';

  @override
  String get staffDashboardTitle => 'Staff Dashboard';

  @override
  String get staffDashboardSubtitle =>
      'Register families, evacuees, centers, and more';

  @override
  String staffIdentityWithBarangay(String role, String barangay) {
    return '$role · Brgy. $barangay';
  }

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get pushNotificationsTitle => 'Push Notifications';

  @override
  String get pushNotificationsSubtitle =>
      'Not yet available — no notification service is set up on the backend. This currently saves your preference on this device.';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get aboutTagline => 'Electronic Ligao Kaligtasan Sistema';

  @override
  String get syncCompleted => 'Information updated.';

  @override
  String get syncPartialFailure =>
      'Some information could not be updated. Showing the latest saved data.';

  @override
  String get offlineDataManagementTitle => 'Offline Data Management';

  @override
  String get offlineDataManagementSubtitle =>
      'Manage saved information for offline access';

  @override
  String get couldNotLoadOfflineData => 'Could not load offline data details';

  @override
  String get offlineOverviewCachedRecords => 'Cached Records';

  @override
  String get offlineOverviewStorageUsed => 'Storage Used';

  @override
  String get offlineOverviewLastUpdated => 'Last Updated';

  @override
  String get cachedDataCategoriesTitle => 'Cached Data Categories';

  @override
  String cachedItemsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString cached items',
      one: '1 cached item',
    );
    return '$_temp0';
  }

  @override
  String get noSavedDataForCategory => 'No saved data';

  @override
  String get updateAllData => 'Update All Data';

  @override
  String get clearCachedData => 'Clear Cached Data';

  @override
  String get clearCacheDialogTitle => 'Clear saved offline data?';

  @override
  String get clearCacheDialogBody =>
      'This will remove saved alerts, evacuation centers, and map information from this device. New information can be downloaded again when internet access is available.';

  @override
  String get clearCacheDialogConfirm => 'Clear Data';

  @override
  String get cacheCleared => 'Offline data cleared.';

  @override
  String get hazardMapTitle => 'Hazard map';

  @override
  String get noMapData => 'No map data available yet.';

  @override
  String get couldNotLoadMapData => 'Could not load map data';

  @override
  String get legendEvacuationCenter => 'Evacuation center';

  @override
  String get legendHazardArea => 'Hazard area';

  @override
  String get showMyLocation => 'Show my location';

  @override
  String get unableToOpenMaps =>
      'Unable to open a maps application on this device.';

  @override
  String get refreshing => 'Refreshing…';

  @override
  String get alertsAndNoticesTitle => 'Alerts & Notices';

  @override
  String get alertsAndNoticesSubtitle => 'Real-time updates for Ligao City';

  @override
  String get dateGroupToday => 'Today';

  @override
  String get dateGroupYesterday => 'Yesterday';

  @override
  String filteredAlertsCount(int count, String severity) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString $severity alerts',
      one: '1 $severity alert',
    );
    return '$_temp0';
  }

  @override
  String get searchAlertsHint => 'Search alerts';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get filterAll => 'All';

  @override
  String get noAlertsMatchFilter => 'No alerts match your search or filter.';

  @override
  String get sortAlertsTooltip => 'Sort alerts';

  @override
  String get sortNewestFirst => 'Newest first';

  @override
  String get sortOldestFirst => 'Oldest first';

  @override
  String get sortBySeverity => 'Severity';

  @override
  String get latestAlertLabel => 'Latest';

  @override
  String get shareAlert => 'Share alert';

  @override
  String get additionalInformation => 'Additional information';

  @override
  String get severityLabel => 'Severity';

  @override
  String get alertTypeLabel => 'Type';

  @override
  String get receivedLabel => 'Received';

  @override
  String get viewEvacuationCenters => 'View evacuation centers';

  @override
  String get invalidCenterLink => 'That center link isn\'t valid.';

  @override
  String get viewOnMap => 'View on map';

  @override
  String get refreshLocation => 'Refresh location';

  @override
  String get otherNearbyCenters => 'Other nearby centers';

  @override
  String get evacuationCentersSubtitle => 'Find nearby and available centers';

  @override
  String get searchCentersHint => 'Search centers';

  @override
  String get searchMyEvacuationCentersHint => 'Search my evacuation centers...';

  @override
  String get staffCentersCitywideNotice =>
      'Showing centers citywide so you can help register residents temporarily in your area.';

  @override
  String get centersYourBarangaySection => 'Your barangay';

  @override
  String get centersOtherBarangaysSection => 'Other barangays';

  @override
  String get noCentersMatchFilter => 'No centers match your search or filter.';

  @override
  String filteredCentersCount(int count, String status) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString $status centers',
      one: '1 $status center',
    );
    return '$_temp0';
  }

  @override
  String get sortCentersTooltip => 'Sort centers';

  @override
  String get sortByName => 'Name';

  @override
  String get sortByOccupancy => 'Occupancy';

  @override
  String get sortByCapacity => 'Capacity';

  @override
  String get centerDetailsTitle => 'Center details';

  @override
  String get centerNotFound => 'This evacuation center could not be found.';

  @override
  String get overviewSectionTitle => 'Overview';

  @override
  String get overviewCapacity => 'Capacity';

  @override
  String get overviewCurrentOccupancy => 'Current occupancy';

  @override
  String get overviewAvailableSlots => 'Available slots';

  @override
  String get overviewOccupancyPercent => 'Occupancy';

  @override
  String get locationSectionTitle => 'Location';

  @override
  String get addressUnavailable => 'Address unavailable';

  @override
  String get centerMapLocationUnavailable =>
      'Map location is not available for this center yet.';

  @override
  String get centerPhotoUnavailable => 'No photo available';

  @override
  String get centerPhotoUnavailableOffline => 'Photo unavailable offline';

  @override
  String get facilitiesSectionTitle => 'Facilities';

  @override
  String get couldNotLoadFacilities => 'Could not load facilities';

  @override
  String get facilitiesNotAvailable =>
      'Facilities information is not available.';

  @override
  String get facilityAvailable => 'Available';

  @override
  String get facilityUnavailable => 'Unavailable';

  @override
  String get facilityNotRecorded => 'Not available';

  @override
  String facilityQuantityAvailable(int quantity) {
    final intl.NumberFormat quantityNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String quantityString = quantityNumberFormat.format(quantity);

    String _temp0 = intl.Intl.pluralLogic(
      quantity,
      locale: localeName,
      other: '$quantityString available',
      one: '1 available',
    );
    return '$_temp0';
  }

  @override
  String get facilityTypeLatrineCompostPit => 'Compost Pit Latrine';

  @override
  String get facilityTypeLatrineSealed => 'Sealed Latrine';

  @override
  String get facilityTypeToiletMale => 'Male Toilet';

  @override
  String get facilityTypeToiletFemale => 'Female Toilet';

  @override
  String get facilityTypeToiletCommon => 'Common Toilet';

  @override
  String get facilityTypeBathingAreaMale => 'Male Bathing Area';

  @override
  String get facilityTypeBathingAreaFemale => 'Female Bathing Area';

  @override
  String get facilityTypeBathingAreaCommon => 'Common Bathing Area';

  @override
  String get facilityTypeHandwashingFacility => 'Handwashing Facility';

  @override
  String get facilityTypeLaundrySpace => 'Laundry Space';

  @override
  String get facilityTypeWomenFriendlySpace => 'Women-Friendly Space';

  @override
  String get facilityTypeChildFriendlySpace => 'Child-Friendly Space';

  @override
  String get facilityTypeHealthFacility => 'Health Facility';

  @override
  String get facilityTypePrayerRoom => 'Prayer Room';

  @override
  String get facilityTypeCommunityKitchen => 'Community Kitchen';

  @override
  String get facilityTypeLivestockArea => 'Livestock Area';

  @override
  String get facilityTypeCampManagementDesk => 'Camp Management Desk';

  @override
  String get facilityTypeInfoBoard => 'Info / Help Desk';

  @override
  String get facilityTypeStorageArea => 'Storage Area';

  @override
  String get centerTypeSchool => 'School';

  @override
  String get centerTypeCoveredCourt => 'Covered Court';

  @override
  String get centerTypeChurch => 'Church';

  @override
  String get centerTypeBarangayHall => 'Barangay Hall';

  @override
  String get centerTypeGymnasium => 'Gymnasium';

  @override
  String get centerTypeOther => 'Other';

  @override
  String get centerNoLocationSet => 'No location set';

  @override
  String get centerChooseLocation => 'Choose Location';

  @override
  String get centerChangeLocation => 'Change';

  @override
  String get centerPasteCoordinatesLabel => 'Or paste coordinates (lat, long)';

  @override
  String get centerSetCoordinates => 'Set';

  @override
  String get centerInvalidCoordinates => 'Invalid latitude or longitude.';

  @override
  String get centerClearLocation => 'Clear Location';

  @override
  String get centerUseThisLocation => 'Use This Location';

  @override
  String get centerSaveWithoutLocation => 'Save Without Location';

  @override
  String get centerFieldCapacityFamilies => 'Capacity (Families)';

  @override
  String get centerFieldCampManager => 'Camp Manager';

  @override
  String get centerFieldCampManagerName => 'Camp Manager Name';

  @override
  String get centerFieldCampManagerContact => 'Camp Manager Contact';

  @override
  String get centerFieldPhoto => 'Photo';

  @override
  String get centerFieldName => 'Center Name';

  @override
  String get centerFieldType => 'Center Type';

  @override
  String get centerFieldAddress => 'Address';

  @override
  String get centerFieldStatus => 'Status';

  @override
  String get centerFieldBarangay => 'Barangay';

  @override
  String get centerBarangayLockedHelper => 'Locked to your assigned barangay';

  @override
  String get centerSectionInformation => 'Center Information';

  @override
  String get centerSectionLocation => 'Location';

  @override
  String get centerSectionCapacity => 'Capacity';

  @override
  String get centerEditEvacuationCenter => 'Edit Evacuation Center';

  @override
  String get centerEditNotAllowed =>
      'You may only edit evacuation centers you created yourself.';

  @override
  String get centerCreateEvacuationCenter => 'Create Evacuation Center';

  @override
  String get centerSaveChanges => 'Save Changes';

  @override
  String get centerCreateSuccessMessage =>
      'Evacuation center created successfully.';

  @override
  String get centerUpdateSuccessMessage =>
      'Evacuation center updated successfully.';

  @override
  String get centerValidationBanner =>
      'Check the highlighted fields and try again.';

  @override
  String get centerOfflineRequired =>
      'Internet connection is required to add or edit evacuation centers.';

  @override
  String get centerTakePhoto => 'Take Photo';

  @override
  String get centerChooseFromGallery => 'Choose from Gallery';

  @override
  String get centerChoosePhoto => 'Choose Photo';

  @override
  String get centerChangePhoto => 'Change Photo';

  @override
  String get centerDiscardDialogTitle => 'Discard changes?';

  @override
  String get centerDiscardDialogBody =>
      'You have unsaved changes to this evacuation center. If you leave now, they\'ll be lost.';

  @override
  String get centerDiscardDialogConfirm => 'Discard';

  @override
  String get layersTooltip => 'Layers';

  @override
  String get mapLayersTitle => 'Layers';

  @override
  String get mapLegendTitle => 'Map Legend';

  @override
  String get fitMapTooltip => 'Fit map';

  @override
  String get showEvacuationCenters => 'Show evacuation centers';

  @override
  String get centerStatusLayerLabel => 'Center Status';

  @override
  String get hazardAreasLabel => 'Hazard Areas';

  @override
  String get showHazardAreas => 'Show hazard areas';

  @override
  String get resetFilters => 'Reset filters';

  @override
  String get yourLocationLegend => 'Your location';

  @override
  String get hazardTypeFlood => 'Flood';

  @override
  String get hazardTypeLandslide => 'Landslide';

  @override
  String get hazardTypeLahar => 'Lahar';

  @override
  String get hazardTypeStormSurge => 'Storm surge';

  @override
  String get hazardTypeVolcanicDangerZone => 'Volcanic danger zone';

  @override
  String get mapBaseLayerLabel => 'Base Map';

  @override
  String get mapBaseLayerStreet => 'Street';

  @override
  String get mapBaseLayerSatellite => 'Satellite';

  @override
  String get mapSatelliteOfflineNotice =>
      'Satellite imagery needs an internet connection — it isn\'t saved for offline use.';

  @override
  String get mapAttributionOpenStreetMap => '© OpenStreetMap contributors';

  @override
  String get mapAttributionEsri => 'Esri World Imagery';

  @override
  String get hazardOverlaysSectionTitle => 'Hazard susceptibility (MGB)';

  @override
  String get hazardOverlayFloodName => 'Flood susceptibility';

  @override
  String get hazardOverlayLandslideName =>
      'Rain-induced landslide susceptibility';

  @override
  String get hazardOverlaysOnlineNotice =>
      'Hazard susceptibility layers need an internet connection — they aren\'t saved for offline use.';

  @override
  String get hazardOverlayFloodNote =>
      'Flood susceptibility: Mines and Geosciences Bureau via GeoRiskPH (service metadata: as of July 2018). Susceptibility, not a flood forecast.';

  @override
  String get hazardOverlayLandslideNote =>
      'Rain-induced landslide susceptibility only: Mines and Geosciences Bureau via GeoRiskPH (service metadata: dated 2012). Susceptibility, not a landslide forecast. Lahar is not mapped.';

  @override
  String hazardOverlayLoadFailed(String layer) {
    return '$layer could not be loaded from GeoRiskPH right now. Switch it off and on to retry.';
  }

  @override
  String get hazardOverlayAttribution => 'MGB via GeoRiskPH';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String updateVersionReady(String version) {
    return 'Version $version is ready';
  }

  @override
  String get updateRequiredBody =>
      'This version of E-LIKAS is out of date. Please update so your alerts and evacuation information stay accurate.';

  @override
  String updateSizeWifi(String size) {
    return '$size MB · Wi-Fi recommended';
  }

  @override
  String get updateWifiRecommended => 'Wi-Fi recommended';

  @override
  String get updateWhatsNew => 'What\'s new';

  @override
  String get updateLater => 'Later';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateDownloading => 'Downloading update…';

  @override
  String get updateVerifying => 'Checking the download…';

  @override
  String get updateReadyToInstall =>
      'Download verified. Opening the installer…';

  @override
  String get updateInstallHint =>
      'If Android asks you to allow installs from E-LIKAS, turn it on, then come back and tap Install.';

  @override
  String get updateInstall => 'Install';

  @override
  String get updateCancel => 'Cancel';

  @override
  String get updateFailedTitle => 'Update failed';

  @override
  String get updateFailedBody =>
      'The update could not be downloaded or did not pass the safety check. Check your connection and try again.';

  @override
  String get updateTryAgain => 'Try again';

  @override
  String get updateOpenInBrowser => 'Open in browser';

  @override
  String get settingsCheckForUpdates => 'Check for updates';

  @override
  String settingsVersionBuild(String version, String build) {
    return 'Version $version (build $build)';
  }

  @override
  String get updateChecking => 'Checking…';

  @override
  String get updateUpToDate => 'E-LIKAS is up to date.';

  @override
  String get updateCheckFailed => 'Could not check for updates right now.';

  @override
  String get normalMonitoringTitle => 'Normal Monitoring';

  @override
  String get viewAlert => 'View Alert';

  @override
  String get findNearestCenterAction => 'Find Nearest Center';

  @override
  String get showingSavedAlertInfo => 'Showing saved alert information';

  @override
  String get emergencyHotlinesSubtitle =>
      'These are the official emergency services of Ligao City.';

  @override
  String get hotlineNumberNotSet => 'Not set';

  @override
  String get emergencyCallNowNote =>
      'For life-threatening emergencies, call the appropriate emergency service immediately.';

  @override
  String get hotlineCategoryNationalEmergency => 'National Emergency';

  @override
  String get hotlineCategoryDisasterResponse => 'Disaster Response';

  @override
  String get hotlineCategoryFire => 'Fire';

  @override
  String get hotlineCategoryPolice => 'Police';

  @override
  String get hotlineCategoryRescue => 'Rescue';

  @override
  String get hotlineCategoryMedical => 'Medical';

  @override
  String get hotlineCategorySocialWelfare => 'Social Welfare';

  @override
  String get hotlineCategoryUtility => 'Utilities';

  @override
  String get favoritesSectionTitle => 'Favorites';

  @override
  String addToFavoritesTooltip(String name) {
    return 'Add $name to favorites';
  }

  @override
  String removeFromFavoritesTooltip(String name) {
    return 'Remove $name from favorites';
  }

  @override
  String numberCopiedFor(String name) {
    return '$name\'s number copied';
  }

  @override
  String get staffLogoutDialogTitle => 'Sign out?';

  @override
  String get staffLogoutDialogBody =>
      'You\'ll need to sign in again to access staff features.';

  @override
  String get staffLogoutDialogConfirm => 'Sign out';

  @override
  String get staffWorkspaceTitle => 'Staff Dashboard';

  @override
  String get staffWorkspaceRoleLabel => 'Role';

  @override
  String get staffWorkspaceBarangayLabel => 'Barangay';

  @override
  String get staffWorkspacePendingCount => 'Pending';

  @override
  String get staffWorkspaceNeedsAttentionCount => 'Needs Attention';

  @override
  String get staffWorkspaceEvacuationCentersSection => 'Evacuation Centers';

  @override
  String get staffWorkspaceRecordsSection => 'Records';

  @override
  String get staffWorkspaceRegisterFamily => 'Register a Family';

  @override
  String get staffWorkspaceRegisterFamilySubtitle =>
      'Works offline — syncs when you\'re ready';

  @override
  String get staffWorkspacePendingRegistrations => 'Pending Registrations';

  @override
  String get staffWorkspaceAllEvacuees => 'Evacuees';

  @override
  String get staffWorkspaceAllEvacueesSubtitle =>
      'Synced families in your area';

  @override
  String get registeredFamiliesTitle => 'Registered Families';

  @override
  String get registeredFamiliesWorkspaceSubtitle =>
      'This device\'s saved records — synced or not';

  @override
  String get registeredFamiliesSubtitle =>
      'Every family record saved on this device, from any barangay. Records from other barangays only appear here — Evacuees shows your own barangay\'s synced roster.';

  @override
  String get registeredFamiliesNotSyncedSection => 'Not yet synced';

  @override
  String get registeredFamiliesSyncedSection => 'Synced';

  @override
  String get staffWorkspaceSyncNow => 'Sync Now';

  @override
  String get staffWorkspaceLogout => 'Staff Logout';

  @override
  String get staffWorkspaceLogoutSubtitle =>
      'Return to the resident-only experience';

  @override
  String get staffAddEvacuationCenter => 'Add Evacuation Center';

  @override
  String get staffAddEvacuationCenterSubtitle =>
      'Online only — not queued offline';

  @override
  String get staffManageEvacuationCenters => 'My Evacuation Centers';

  @override
  String get staffManageEvacuationCentersSubtitle =>
      'View and edit centers you can manage';

  @override
  String get staffSessionOfflineBanner =>
      'Working from a saved sign-in. Some actions need a connection.';

  @override
  String get staffFamiliesEmptyState => 'No families have been registered yet.';

  @override
  String get staffFamiliesNoCacheMessage =>
      'No saved family information yet — connect to the internet at least once to load it.';

  @override
  String get staffFamiliesLoadError => 'Could not load registered families.';

  @override
  String staffFamiliesShowingAsOf(String date) {
    return 'Showing data as of $date';
  }

  @override
  String get staffFamiliesShowingSaved => 'Showing saved data';

  @override
  String get staffFamiliesUnknownBarangay => 'Unknown barangay';

  @override
  String get staffFamiliesUnnamedFamily => 'Unnamed family';

  @override
  String staffFamiliesMemberCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String staffFamiliesRegisteredIn(String barangay) {
    return 'Registered in $barangay';
  }

  @override
  String get staffFamiliesMembersSectionTitle => 'Members';

  @override
  String get staffSyncStoppedForAuthMessage =>
      'Your session expired. Sign in again to keep syncing.';

  @override
  String get staffSyncRequiresConnectionMessage =>
      'Sync requires an internet connection.';

  @override
  String staffSyncCompletedMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString registrations synced.',
      one: '1 registration synced.',
      zero: 'No registrations were synced.',
    );
    return '$_temp0';
  }

  @override
  String get staffPendingListEmpty =>
      'No pending registrations. Everything is synced.';

  @override
  String get staffPendingListError => 'Could not load pending registrations.';

  @override
  String get staffPendingNoHeadName => 'No head of family set';

  @override
  String staffPendingSubtitle(int count, String barangay, String date) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString members',
      one: '1 member',
    );
    return '$_temp0 • $barangay • $date';
  }

  @override
  String get staffStatusPending => 'Pending';

  @override
  String get staffStatusSyncing => 'Syncing';

  @override
  String get staffStatusNeedsAttention => 'Needs Attention';

  @override
  String get staffRegDiscardDialogTitle => 'Discard changes?';

  @override
  String get staffRegDiscardDialogBody =>
      'You have unsaved changes to this registration. If you leave now, they\'ll be lost.';

  @override
  String get staffRegDiscardDialogConfirm => 'Discard';

  @override
  String get staffRegExactlyOneHeadError =>
      'Select exactly one family member as the head of family.';

  @override
  String get staffRegValidationBanner =>
      'Check the highlighted fields and try again.';

  @override
  String get staffRegSavedOfflineMessage =>
      'Saved offline. It will sync automatically once you\'re back online.';

  @override
  String get staffRegSuccessMessage => 'Family registered successfully.';

  @override
  String get staffRegAmbiguousMessage =>
      'The connection dropped while submitting. Saved to Pending Registrations so you can confirm before resubmitting.';

  @override
  String get staffRegisterFamilyTitle => 'Register a Family';

  @override
  String get staffRegEditRegistrationTitle => 'Review Registration';

  @override
  String get staffRegLookupUnavailable =>
      'Not available offline. Connect to load this list.';

  @override
  String get staffReg4psBeneficiaryLabel => '4Ps beneficiary family';

  @override
  String get staffRegMembersSectionTitle => 'Family Members';

  @override
  String get staffRegAddMemberButton => 'Add Member';

  @override
  String get staffRegSubmitButton => 'Submit Registration';

  @override
  String get staffRegFieldBarangay => 'Barangay';

  @override
  String get staffRegFieldHomeAddress => 'Street / Sitio Address';

  @override
  String get staffRegFieldHomeAddressHint => 'e.g. Purok 3, Sitio Mabuhay';

  @override
  String get staffRegFieldEvacuationEvent => 'Evacuation Event';

  @override
  String get staffRegFieldDisplacementType => 'Displacement Type';

  @override
  String get staffRegDisplacementInsideCenter => 'Inside evacuation center';

  @override
  String get staffRegDisplacementOutsideCenter => 'Private house';

  @override
  String get staffRegFieldEvacuationCenter => 'Evacuation Center';

  @override
  String staffRegMemberCardTitle(int number) {
    return 'Member $number';
  }

  @override
  String get staffRegHeadOfFamilyBadge => 'Head of Family';

  @override
  String get staffRegSetAsHead => 'Set as head';

  @override
  String get staffRegRemoveMember => 'Remove member';

  @override
  String get staffRegFieldFirstName => 'First Name';

  @override
  String get staffRegFieldMiddleName => 'Middle Name';

  @override
  String get staffRegFieldLastName => 'Last Name';

  @override
  String get staffRegFieldSuffix => 'Suffix';

  @override
  String get staffRegFieldSex => 'Sex';

  @override
  String get staffRegSexMale => 'Male';

  @override
  String get staffRegSexFemale => 'Female';

  @override
  String get staffRegFieldDateOfBirth => 'Date of Birth';

  @override
  String get staffRegSelectDate => 'Select date';

  @override
  String get staffRegFieldCivilStatus => 'Civil Status';

  @override
  String get staffRegNotSpecified => 'Not specified';

  @override
  String get staffRegCivilStatusSingle => 'Single';

  @override
  String get staffRegCivilStatusMarried => 'Married';

  @override
  String get staffRegCivilStatusWidowed => 'Widowed';

  @override
  String get staffRegCivilStatusSeparated => 'Separated';

  @override
  String get staffRegCivilStatusDivorced => 'Divorced';

  @override
  String get staffRegFieldContactNumber => 'Contact Number';

  @override
  String get staffRegContactRequired => 'Contact number is required.';

  @override
  String get staffRegContactInvalid =>
      'Enter a valid Philippine mobile number (09XXXXXXXXX or +639XXXXXXXXX).';

  @override
  String get staffRegSameAsHead => 'Same as head of family';

  @override
  String get staffRegHeadContactMissing =>
      'Enter the head of family\'s contact number first.';

  @override
  String get staffRegPossibleDuplicateTitle => 'Possible existing match';

  @override
  String get staffRegViewRecord => 'View record';

  @override
  String get staffRegIsPwd => 'PWD';

  @override
  String get staffRegIsPregnant => 'Pregnant';

  @override
  String get staffRegIsLactating => 'Lactating';

  @override
  String get staffRegIsSoloParent => 'Solo Parent';

  @override
  String get staffRegIsIndigenous => 'Indigenous Person';

  @override
  String get staffRegIs4psMember => '4Ps Beneficiary';

  @override
  String get staffRegFieldPwdType => 'Type of Disability';

  @override
  String get staffLoginOfflineTitle => 'You\'re offline. Connect to sign in.';

  @override
  String get staffLoginTitle => 'Staff Sign In';

  @override
  String get staffLoginEmailLabel => 'Email or username';

  @override
  String get staffLoginPasswordLabel => 'Password';

  @override
  String get staffLoginButton => 'Sign In';

  @override
  String get staffPendingDetailTitle => 'Registration Details';

  @override
  String get staffPendingDetailNotFound =>
      'This registration is no longer in the queue. It may have already synced.';

  @override
  String get staffPendingDetailLoadError => 'Could not load this registration.';

  @override
  String get staffPendingDetailSummarySectionTitle => 'Summary';

  @override
  String get staffPendingDetailErrorSectionTitle => 'Needs Attention';

  @override
  String get staffPendingDetailFieldErrorsTitle => 'Fields to review';

  @override
  String staffPendingDetailAttemptCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString attempts',
      one: '1 attempt',
    );
    return '$_temp0';
  }

  @override
  String staffPendingDetailLastAttempt(String date) {
    return 'Last attempt: $date';
  }

  @override
  String staffPendingDetailCreatedAt(String date) {
    return 'Created $date';
  }

  @override
  String staffPendingDetailUpdatedAt(String date) {
    return 'Updated $date';
  }

  @override
  String get staffPendingErrorCategoryValidation =>
      'Needs correction before resubmitting';

  @override
  String get staffPendingErrorCategoryForbidden =>
      'Not permitted for your account';

  @override
  String get staffPendingErrorCategoryAmbiguous => 'Uncertain outcome';

  @override
  String get staffPendingErrorCategoryServer => 'Server error';

  @override
  String get staffPendingAmbiguousHint =>
      'The server may have already received this registration before the connection dropped. Confirm the family isn\'t already registered before resubmitting, to avoid creating a duplicate.';

  @override
  String get staffPendingDetailReviewButton => 'Review & Resubmit';

  @override
  String get staffPendingDetailEditButton => 'Edit';

  @override
  String get staffPendingDetailDeleteButton => 'Delete';

  @override
  String get staffPendingDetailDeleteDialogTitle => 'Delete this registration?';

  @override
  String get staffPendingDetailDeleteDialogBody =>
      'This removes it from the offline queue permanently. This cannot be undone.';

  @override
  String get staffPendingDetailSyncingNotice =>
      'This registration is currently syncing. Please wait.';

  @override
  String get staffPendingDetailDeletedMessage =>
      'Registration removed from the queue.';

  @override
  String get ecBoardTitle => 'EC Information Board';

  @override
  String get ecBoardWorkspaceActionSubtitle =>
      'Add evacuees and view the age/sex breakdown for a center';

  @override
  String get ecBoardAddEvacueeTitle => 'Add Evacuee';

  @override
  String get ecBoardEditEvacueeTitle => 'Edit Evacuee Entry';

  @override
  String get ecBoardEntryDetailTitle => 'Evacuee Entry';

  @override
  String get ecBoardFieldSex => 'Sex';

  @override
  String get ecBoardFieldAgeBracket => 'Age group';

  @override
  String get ecBoardFieldHousehold => 'Family';

  @override
  String get ecBoardHouseholdExisting => 'Already here';

  @override
  String get ecBoardHouseholdNew => 'New family';

  @override
  String get ecBoardSelectHouseholdButton => 'Select family';

  @override
  String get ecBoardHouseholdSearchHint => 'Search by head of family name';

  @override
  String get ecBoardRefreshHouseholdsTooltip => 'Refresh family list';

  @override
  String get ecBoardHouseholdsUpToDate => 'Up to date';

  @override
  String get ecBoardPendingHouseholdBadge => 'Pending — not yet synced';

  @override
  String get ecBoardPendingNewHouseholdBadge =>
      'New family from this device — not yet synced';

  @override
  String get ecBoardPendingHouseholdNotice =>
      'This family hasn\'t synced yet. This entry will sync automatically once it does.';

  @override
  String get ecBoardNewHouseholdHeadName => 'Family name';

  @override
  String get ecBoardSubmitButton => 'Save Evacuee';

  @override
  String get ecBoardValidationBanner =>
      'Please complete sex, age group, and family before saving.';

  @override
  String get ecBoardSavedOfflineMessage =>
      'Saved offline. It will sync when you\'re back online.';

  @override
  String get ecBoardSavedPendingHouseholdMessage =>
      'Saved — waiting for the selected family to sync first.';

  @override
  String get ecBoardSuccessMessage => 'Evacuee added successfully.';

  @override
  String get ecBoardNoEventsAvailable =>
      'No open event yet. CSWDO opens an event when a threat is announced.';

  @override
  String get ecBoardAgeSexSectionTitle => 'Age & Sex Disaggregation';

  @override
  String get ecBoardSectoralSectionTitle => 'Sectoral Group';

  @override
  String get ecBoardLastKnownFromCacheNotice =>
      'Offline — showing the last confirmed figures saved on this device.';

  @override
  String get ecBoardUnclassifiedLabel => 'Not yet classified';

  @override
  String get ecBoardPendingSectionTitle => 'Added on this device';

  @override
  String get ecBoardPendingSectionSubtitle =>
      'Not yet synced, so shown here only — never added into the board\'s figures. Sync Now sends them, with their sectoral details and family answers.';

  @override
  String get ecBoardSyncNowInlineButton => 'Sync Now';

  @override
  String get ecBoardPendingListEmpty => 'No pending entries on this device.';

  @override
  String get ecBoardTotalLabel => 'Total';

  @override
  String get ecBoardBracketInfant => 'Infant (0-6 mo)';

  @override
  String get ecBoardBracketToddler => 'Toddler (7-24 mo)';

  @override
  String get ecBoardBracketPreschooler => 'Preschooler';

  @override
  String get ecBoardBracketSchoolAge => 'School Age';

  @override
  String get ecBoardBracketTeenage => 'Teenage';

  @override
  String get ecBoardBracketAdult => 'Adult';

  @override
  String get ecBoardBracketSeniorCitizen => 'Senior Citizen';

  @override
  String get ecBoardSectoralPwd => 'Persons with Disability';

  @override
  String get ecBoardSectoralChildHeadedFamily => 'Child-Headed Family';

  @override
  String get ecBoardSectoralSingleHeadedFamily => 'Single-Headed Family';

  @override
  String get ecBoardSectoralSoloParent => 'Solo Parent';

  @override
  String get ecBoardSectoralPregnantWomen => 'Pregnant Women';

  @override
  String get ecBoardSectoralLactatingMothers => 'Lactating Mothers';

  @override
  String get ecBoardSectoralFourPsBeneficiary => '4Ps Beneficiary';

  @override
  String get ecBoardSectoralIndigenousPeoples => 'Indigenous Peoples';

  @override
  String get ecBoardSectoralFlagsTitle => 'Sectoral details (optional)';

  @override
  String get ecBoardSectoralFlagsHelp =>
      'Tick only what you know. Leaving a box unticked records nothing — it doesn\'t mean \"no\".';

  @override
  String ecBoardSectoralFlagsTicked(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString ticked';
  }

  @override
  String get ecBoardFourPsBeneficiaryFamilies => '4Ps Beneficiary Families';

  @override
  String get ecBoardAddEvacueeIntro =>
      'Name and birthdate can be added later on the web dashboard\'s Evacuees page.';

  @override
  String get ecBoardSectionWhoIsThisPerson => 'Who is this person?';

  @override
  String get ecBoardHeadNote =>
      'This person\'s age and sex will be used for the family head.';

  @override
  String get ecBoardThisPersonIsHead => 'This person is the family head';

  @override
  String get ecBoardNoHeadLinkedYet => 'This family has no head linked yet.';

  @override
  String get ecBoardSingleHeadedQuestion =>
      'Only one family head? (single-headed)';

  @override
  String get ecBoardAnswerNotYetKnown => 'Not yet known';

  @override
  String get ecBoardAnswerYes => 'Yes';

  @override
  String get ecBoardAnswerNo => 'No';

  @override
  String get ecBoardAnswerYesUnder18 => 'Yes (under 18)';

  @override
  String get ecBoardHeadSectionTitle => 'About the actual family head';

  @override
  String get ecBoardHeadSectionSubtitle =>
      'Someone other than the person you\'re adding. Used until they\'re added and linked.';

  @override
  String get ecBoardHeadSexLabel => 'Head\'s sex';

  @override
  String get ecBoardHeadIsMinorLabel => 'Head is a minor?';

  @override
  String get ecBoardWillBeRecordedTitle => 'Will be recorded';

  @override
  String ecBoardSummaryAdding(String sex, String ageGroup) {
    return 'Adding 1 $sex, $ageGroup.';
  }

  @override
  String get ecBoardSummaryChooseAgeSex =>
      'Choose this person\'s age group and sex.';

  @override
  String ecBoardSummaryJoinsHousehold(String household) {
    return 'Joins the family already here: $household.';
  }

  @override
  String get ecBoardSummaryChooseHousehold =>
      'Choose the family this person belongs to.';

  @override
  String ecBoardSummaryBecomesHead(String minor) {
    return 'Becomes that family\'s head ($minor).';
  }

  @override
  String ecBoardSummaryNewHousehold(String name, String barangay) {
    return 'New family: $name, $barangay.';
  }

  @override
  String get ecBoardSummaryNoHeadName => '(family name not entered yet)';

  @override
  String get ecBoardSummaryNoBarangay => '(home barangay not chosen yet)';

  @override
  String get ecBoardHomeBarangayLabel => 'Home barangay';

  @override
  String get ecBoardHomeBarangayHint => 'Choose the family\'s home barangay...';

  @override
  String get ecBoardHomeBarangayHelp =>
      'Where the family lives -- not necessarily where this center is.';

  @override
  String ecBoardHomeBarangaySameAsCenter(String barangay) {
    return 'Same as this center ($barangay)';
  }

  @override
  String get ecBoardHomeBarangayRequired =>
      'Choose the family\'s home barangay.';

  @override
  String ecBoardFamilyHereGeneric(int id, String barangay, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Family #$id · $barangay · $countString here';
  }

  @override
  String ecBoardFamilyNumber(int id) {
    return 'Family #$id';
  }

  @override
  String get ecBoardNoFamiliesHere => 'No families here right now.';

  @override
  String get ecBoardFamiliesHereOffline =>
      'Offline: showing the families saved on this phone. One that has left this center will be refused when it syncs.';

  @override
  String ecBoardOtherBarangayNote(String barangay) {
    return 'This center is in $barangay. Add only people who are staying at this center.';
  }

  @override
  String ecBoardEventClosedName(String name) {
    return '$name (closed)';
  }

  @override
  String get ecBoardClosedEventNote =>
      'This event is closed. Evacuees can no longer be added to it.';

  @override
  String get ecBoardClosedEventWaitingNote =>
      'Entries still waiting on this phone for it can\'t sync. Check them, then delete them from this phone.';

  @override
  String ecBoardSummaryHeadIsThisPerson(String minor) {
    return 'Head: this person ($minor).';
  }

  @override
  String ecBoardSummaryHeadIsSomeoneElse(String sex, String minor) {
    return 'Head: someone else, $sex, $minor.';
  }

  @override
  String get ecBoardSummarySexNotYetKnown => 'sex not yet known';

  @override
  String get ecBoardSummaryMinorUnknown => 'minor or not: not yet known';

  @override
  String get ecBoardSummaryMinor => 'a minor';

  @override
  String get ecBoardSummaryNotMinor => 'not a minor';

  @override
  String ecBoardSummarySingleHeaded(String answer) {
    return 'Single-headed: $answer.';
  }

  @override
  String get ecBoardSummaryAnswerUnknown => 'not yet known';

  @override
  String get ecBoardSummaryAnswerYes => 'yes';

  @override
  String get ecBoardSummaryAnswerNo => 'no';

  @override
  String get ecBoardSummaryMale => 'male';

  @override
  String get ecBoardSummaryFemale => 'female';

  @override
  String ecBoardSummarySectoral(String flags) {
    return 'Sectoral: $flags.';
  }

  @override
  String get ecBoardSummaryNoSectoral => 'No sectoral details.';

  @override
  String get ecBoardSectoralLiveExplanation =>
      'Counted from each evacuee\'s sectoral details. Child- and single-headed families are counted once per family, by the head\'s sex, from the answers given when the family was added.';

  @override
  String familyMemberDetailsPending(int index) {
    return 'Member $index — details pending';
  }

  @override
  String familyMemberCheckedInAt(String center) {
    return 'Checked in at $center';
  }

  @override
  String get familyMemberCheckedInUnspecified =>
      'Checked in at unspecified location';

  @override
  String get familyMemberCheckedOut => 'Checked out';

  @override
  String get familyMembersNeedConnection =>
      'Connect to the internet to see who\'s still checked in and to check someone out.';

  @override
  String familyHeadNotLinked(String answers) {
    return 'Head not yet linked. Counts use the answers given for the head ($answers) until a member is linked. When the head arrives, add them with Add Evacuee → Already here and tick \"This person is the family head\".';
  }

  @override
  String get familyHeadNotLinkedNothingKnown =>
      'Head not yet linked. Nothing is known about the head yet until a member is linked. When the head arrives, add them with Add Evacuee → Already here and tick \"This person is the family head\".';

  @override
  String get familyLegacyBulkEntryNotice =>
      'Legacy bulk entry — needs manual review. Anonymous people from an old headcount, not a real family.';

  @override
  String get checkOutButton => 'Check out';

  @override
  String checkOutDialogTitle(String name) {
    return 'Check out $name';
  }

  @override
  String checkOutDialogSubtitle(String center) {
    return 'Closes their stay at $center, so they no longer count as here now.';
  }

  @override
  String get checkOutTheirCurrentLocation => 'their current location';

  @override
  String get checkOutReasonLabel => 'Reason';

  @override
  String get checkOutReturnedHome => 'Returned home';

  @override
  String get checkOutTransferred => 'Transferred elsewhere';

  @override
  String get checkOutReturnedHomeLower => 'returned home';

  @override
  String get checkOutTransferredLower => 'transferred elsewhere';

  @override
  String checkOutConfirm(String name, String reason) {
    return 'Check out $name as $reason? They\'ll no longer count as here now.';
  }

  @override
  String checkOutMemberPendingName(int index) {
    return 'Member $index (details pending)';
  }

  @override
  String checkOutSucceeded(String name) {
    return '$name checked out.';
  }

  @override
  String get checkOutOther => 'Others';

  @override
  String get checkOutOtherLower => 'departed for another reason';

  @override
  String get markFamilyDepartedButton => 'Mark family as departed';

  @override
  String get markFamilyDepartedSubtitle =>
      'Checks out everyone ticked, with one reason for all of them. Members already checked out aren\'t listed.';

  @override
  String get markFamilyDepartedWho => 'Who is leaving';

  @override
  String get markFamilyDepartedReasonHelp =>
      'Applies to everyone ticked above.';

  @override
  String markFamilyDepartedSubmit(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Mark $countString as departed';
  }

  @override
  String markFamilyDepartedConfirmTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mark $countString members as departed?',
      one: 'Mark 1 member as departed?',
    );
    return '$_temp0';
  }

  @override
  String markFamilyDepartedConfirmMessage(String reason) {
    return 'They\'ll be recorded as $reason and no longer count as here now.';
  }

  @override
  String get markFamilyDepartedConfirmButton => 'Mark as departed';

  @override
  String get markFamilyDepartedWorking => 'Marking…';

  @override
  String markFamilyDepartedDone(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString members marked as departed.',
      one: '1 member marked as departed.',
    );
    return '$_temp0';
  }

  @override
  String markFamilyDepartedPartialTitle(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$doneString of $totalString marked as departed';
  }

  @override
  String get markFamilyDepartedPartialBody => 'These weren\'t checked out:';

  @override
  String get ecBoardHeaderCenter => 'Evacuation center';

  @override
  String get ecBoardAsOf => 'As of';

  @override
  String get ecBoardAsOfNotYetFetched => 'Not yet fetched';

  @override
  String get ecBoardNotYetFetchedHelp =>
      'This board hasn\'t been loaded on this device yet, so every figure shows a dash. Connect to the internet and try again.';

  @override
  String get ecBoardHeaderFamilies => 'Families (Cum/Now)';

  @override
  String get ecBoardHeaderPersons => 'Persons (Cum/Now)';

  @override
  String get staffUseTheWebTitle => 'Use the web';

  @override
  String get staffUseTheWebBody =>
      'Administrator accounts manage users, logs and backups on the E-LIKAS website. The mobile app is for barangay field work and CSWD monitoring.';

  @override
  String get staffOpenWebsite => 'Open the E-LIKAS website';

  @override
  String get staffSignOut => 'Sign out';

  @override
  String get centerApprovalUnverified => 'Unverified';

  @override
  String get centerApprovalRejected => 'Rejected';

  @override
  String get centerApprovalEditWaiting => 'Edit waiting for CSWD';

  @override
  String get centerRejectedNotUsable =>
      'Rejected by CSWD. Not usable on the EC Board.';

  @override
  String get staffOwnCentersEmpty =>
      'No evacuation centers in your barangay yet';

  @override
  String get residentBarangayTitle => 'Your barangay';

  @override
  String get residentBarangayNotSet => 'Not chosen yet';

  @override
  String get residentBarangayPickerTitle => 'Choose your barangay';

  @override
  String get residentBarangaySearchHint => 'Search barangays';

  @override
  String get residentBarangayListUnavailable =>
      'The barangay list needs an internet connection the first time.';

  @override
  String get residentBarangayWhy =>
      'See your barangay\'s status and its evacuation centers first.';

  @override
  String residentBarangayStatusOf(Object barangay) {
    return 'Brgy. $barangay';
  }

  @override
  String get residentNoOpenEvent => 'No disaster event is open.';

  @override
  String residentStatusSavedCopy(Object age) {
    return 'As of $age';
  }

  @override
  String get showBarangayStatus => 'Barangay status';

  @override
  String get barangayBoundariesAttribution =>
      'Barangay boundaries: PSA-NAMRIA via HDX (CC BY-IGO)';

  @override
  String barangayStatusTapped(Object barangay, Object status) {
    return '$barangay: $status';
  }

  @override
  String centersInYourBarangay(Object barangay) {
    return 'Centers in Brgy. $barangay';
  }

  @override
  String get centerNoMapLocationYet =>
      'No map location yet. Ask your barangay for directions.';

  @override
  String get staffTabCenters => 'Centers';

  @override
  String get staffTabMore => 'More';

  @override
  String get staffTabResidentApp => 'Resident app';

  @override
  String get staffSignInButton => 'Staff sign in';

  @override
  String get staffModeButton => 'Staff Mode';

  @override
  String get syncTitle => 'Sync';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncAllDone => 'Everything is synced';

  @override
  String syncWaitingCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString waiting to sync',
      one: '1 waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String syncAttentionCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString need a look',
      one: '1 needs a look',
    );
    return '$_temp0';
  }

  @override
  String syncSentMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString sent.',
      one: '1 sent.',
      zero: 'Nothing new to send.',
    );
    return '$_temp0';
  }

  @override
  String get syncNeedsAttention => 'Needs a look';

  @override
  String get syncWaiting => 'Waiting to sync';

  @override
  String get syncFamilyRegistrations => 'Family registrations';

  @override
  String get syncTryAgain => 'Try again';

  @override
  String get syncDiscardTitle => 'Discard this action?';

  @override
  String syncDiscardBody(Object summary) {
    return '\"$summary\" will not be sent. This cannot be undone.';
  }

  @override
  String get syncDiscardConfirm => 'Discard';

  @override
  String get syncDiscarded => 'Action discarded';

  @override
  String get syncCouldNotRead => 'Could not read the queue on this device.';

  @override
  String get moreActions => 'More actions';

  @override
  String get staffSyncRow => 'Sync';

  @override
  String get purokOptionalLabel => 'Purok (optional)';

  @override
  String get purokNone => 'No purok';

  @override
  String get ecBoardFamiliesHereTitle => 'Families here now';

  @override
  String get ecBoardFamiliesHereEmpty =>
      'No family is checked in here for this event.';

  @override
  String ecBoardFamilyMembers(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String showAllCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Show all $countString';
  }

  @override
  String get returningFamiliesTitle => 'Returning families';

  @override
  String get returningFamiliesOfflineButton =>
      'Returning families (needs a connection)';

  @override
  String get returningFamiliesNeedsConnection =>
      'Returning families need an internet connection.';

  @override
  String get returningFamiliesNoPastEvents =>
      'No family of your barangay from a past event can be entered here.';

  @override
  String get returningFamiliesPastEvent => 'Past event';

  @override
  String get returningFamiliesSearchHint => 'Family or member name';

  @override
  String get returningFamiliesNone => 'No family found.';

  @override
  String get returningFamilyAlreadyIn => 'Already in this event';

  @override
  String get returningFamilyWhoArrived => 'Who arrived?';

  @override
  String returningFamilyUnnamed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString members without a name are not listed.',
      one: '1 member without a name is not listed.',
    );
    return '$_temp0';
  }

  @override
  String get returningMemberCheckedIn => 'Already checked in this event';

  @override
  String returningMemberAge(int age) {
    final intl.NumberFormat ageNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String ageString = ageNumberFormat.format(age);

    String _temp0 = intl.Intl.pluralLogic(
      age,
      locale: localeName,
      other: '$ageString years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String get returningMemberAgeGroup => 'Age group (no birthdate on record)';

  @override
  String get returningMemberStillPregnant => 'Pregnant now';

  @override
  String get returningMemberStillLactating => 'Lactating now';

  @override
  String returningFamilyEnroll(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Enter $countString people',
      one: 'Enter 1 person',
    );
    return '$_temp0';
  }

  @override
  String returningFamilyDone(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString people entered',
      one: '1 person entered',
    );
    return '$_temp0';
  }

  @override
  String get returningFamilyDuplicateTitle => 'Same family?';

  @override
  String get returningFamilyDuplicateBody =>
      'A family that may be the same one is already in this event.';

  @override
  String returningFamilyLinkTo(String name, String center, String members) {
    return 'Same family, link it: $name · $center · $members';
  }

  @override
  String get returningFamilyDifferent => 'Different family, add as new';

  @override
  String get centerLocationTitle => 'Location on the map';

  @override
  String get centerLocationOnMap => 'On the map';

  @override
  String get centerLocationWaitingForCswd =>
      'A location you sent is waiting for CSWD.';

  @override
  String get centerLocationWaitingToSync =>
      'A location is saved on this phone and will be sent when online.';

  @override
  String get centerLocationSetFromPhone => 'Set location from this phone';

  @override
  String get centerLocationConfirmTitle => 'Use this location?';

  @override
  String centerLocationAccuracy(int meters) {
    final intl.NumberFormat metersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String metersString = metersNumberFormat.format(meters);

    return 'Accurate to about $metersString m';
  }

  @override
  String get centerLocationLowAccuracy =>
      'Low accuracy. Step outside or wait a moment, then try again.';

  @override
  String get centerLocationGoesToCswd =>
      'Stand at the center\'s entrance. CSWD approves the location before it appears on the map.';

  @override
  String get centerLocationSend => 'Send to CSWD';

  @override
  String centerLocationSummary(Object center) {
    return 'Location of $center';
  }

  @override
  String get centerLocationQueued =>
      'Location sent for CSWD approval (or kept until you are online).';

  @override
  String get facilityRequestsTitle => 'Facility requests';

  @override
  String get facilityRequestsNone => 'No request yet.';

  @override
  String get facilityRequestsNeedConnection =>
      'The requests sent before need a connection to show.';

  @override
  String get facilityRequestsAsk => 'Request what\'s missing';

  @override
  String get facilityRequestWhat => 'What is missing';

  @override
  String get facilityRequestOther => 'Something else (type it)';

  @override
  String get facilityRequestItem => 'What is needed';

  @override
  String get facilityRequestQuantity => 'How many';

  @override
  String get facilityRequestReason => 'Why (optional)';

  @override
  String get facilityRequestSend => 'Send to CSWD';

  @override
  String get facilityRequestSent =>
      'Request sent to CSWD (or kept until you are online).';

  @override
  String facilityRequestSummary(String what, int count, String center) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$what × $countString for $center';
  }

  @override
  String get requestStatusWaiting => 'Waiting';

  @override
  String get requestStatusApproved => 'Approved';

  @override
  String get requestStatusRejected => 'Rejected';

  @override
  String get decrease => 'Decrease';

  @override
  String get increase => 'Increase';

  @override
  String get reliefTitle => 'Relief boxes';

  @override
  String get staffTabRelief => 'Relief';

  @override
  String get reliefNeedsConnectionFirst =>
      'Relief boxes need a connection the first time.';

  @override
  String get staffNoOpenEvent =>
      'No open event yet. CSWDO opens an event when a threat is announced.';

  @override
  String savedCopyAge(Object age) {
    return 'As of $age';
  }

  @override
  String get reliefNoRoundYet => 'No relief round yet.';

  @override
  String reliefRound(int number) {
    return 'Round $number';
  }

  @override
  String get reliefNeed => 'Need';

  @override
  String get reliefReceived => 'Received';

  @override
  String get reliefGiven => 'Given';

  @override
  String get reliefShort => 'Short';

  @override
  String get reliefBoxesToConfirm => 'Boxes to confirm';

  @override
  String get reliefGiveBoxes => 'Give boxes';

  @override
  String reliefGivenOfReceived(int given, int received) {
    final intl.NumberFormat givenNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String givenString = givenNumberFormat.format(given);
    final intl.NumberFormat receivedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String receivedString = receivedNumberFormat.format(received);

    return '$givenString given of $receivedString received';
  }

  @override
  String reliefBoxesSent(String boxes, int round) {
    return '$boxes sent, round $round';
  }

  @override
  String get reliefConfirmArrived => 'Confirm what arrived';

  @override
  String get reliefHowManyArrived => 'How many boxes arrived?';

  @override
  String reliefBoxesArrived(int sent) {
    final intl.NumberFormat sentNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String sentString = sentNumberFormat.format(sent);

    return 'Boxes received (of $sentString sent)';
  }

  @override
  String get reliefFewerNote => 'Why fewer? (required)';

  @override
  String get reliefConfirm => 'Confirm';

  @override
  String reliefConfirmSummary(String boxes, int round) {
    return '$boxes received, round $round';
  }

  @override
  String get reliefLeftToGive => 'Left to give';

  @override
  String get reliefByPriority => 'By priority';

  @override
  String get reliefByName => 'By name';

  @override
  String get reliefSuggestedOrderNote =>
      'Priority order: give to the families at the top first.';

  @override
  String reliefPurokHeading(String purok, int given, int total) {
    final intl.NumberFormat givenNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String givenString = givenNumberFormat.format(given);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$purok · $givenString of $totalString given';
  }

  @override
  String get reliefGiveBox => 'Give box';

  @override
  String get reliefGivenWaiting => 'Given, waiting to sync';

  @override
  String get reliefVoidWaiting => 'Void waiting to sync';

  @override
  String get reliefVoidHandout => 'Void handout';

  @override
  String reliefVoidTitle(Object family) {
    return 'Void the box for $family?';
  }

  @override
  String get reliefVoidBody =>
      'The family will show as not given yet. This cannot be undone.';

  @override
  String get reliefVoidReason => 'Reason (required)';

  @override
  String reliefGiveSummary(String family, int round) {
    return 'Box for $family, round $round';
  }

  @override
  String reliefVoidSummary(Object family) {
    return 'Void box for $family';
  }

  @override
  String get staffTabBarangay => 'Barangay';

  @override
  String get barangayStatusNeedsConnection =>
      'The barangay status needs a connection the first time.';

  @override
  String barangayStatusSetBy(Object name, Object when) {
    return 'Set by $name, $when';
  }

  @override
  String get barangayStatusReadOnly =>
      'The event is closed. The status can only be changed during an open event.';

  @override
  String barangayStatusCswdOrder(Object status) {
    return 'Under \"$status\", ordered by CSWD. Only CSWD can change it.';
  }

  @override
  String get barangayStatusChange => 'Change status';

  @override
  String get barangayStatusNote =>
      'Note (optional; required to update the same status)';

  @override
  String get barangayStatusSave => 'Save status';

  @override
  String barangayStatusSaved(Object status) {
    return 'Marked \"$status\" (sent when online).';
  }

  @override
  String get finalCountTitle => 'Final count';

  @override
  String finalCountFigures(String families, String persons) {
    return '$families · $persons';
  }

  @override
  String finalCountInsideOutside(int inside, int outside) {
    final intl.NumberFormat insideNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String insideString = insideNumberFormat.format(inside);
    final intl.NumberFormat outsideNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String outsideString = outsideNumberFormat.format(outside);

    return '$insideString inside centers · $outsideString outside';
  }

  @override
  String finalCountNoStay(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString with no stay recorded';
  }

  @override
  String get finalCountNotSubmitted => 'Not submitted yet';

  @override
  String get finalCountWaiting => 'Submitted, waiting for CSWD';

  @override
  String get finalCountReturned => 'Returned by CSWD';

  @override
  String finalCountValidated(String families) {
    return 'Validated: $families (the relief need)';
  }

  @override
  String get finalCountChanged =>
      'The count has changed since the last submission.';

  @override
  String get finalCountSubmit => 'Submit final count';

  @override
  String get finalCountSubmitUpdated => 'Submit updated count';

  @override
  String get finalCountSubmitTitle => 'Submit this final count?';

  @override
  String get finalCountComputedNote =>
      'The system computes these numbers from the families registered in this event; they are not typed in.';

  @override
  String get finalCountNote => 'Note for CSWD (optional)';

  @override
  String finalCountSummary(String families, String persons) {
    return 'Final count: $families, $persons';
  }

  @override
  String reliefShortfallTitle(int round) {
    return 'Request more boxes for round $round';
  }

  @override
  String get reliefShortfallSend => 'Send request';

  @override
  String reliefShortfallAsk(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Request up to $countString more boxes',
      one: 'Request 1 more box',
    );
    return '$_temp0';
  }

  @override
  String reliefShortfallRow(int count, String status) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Requested $countString more: $status';
  }

  @override
  String reliefShortfallSummary(int count, int round) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Request $countString more boxes, round $round',
      one: 'Request 1 more box, round $round',
    );
    return '$_temp0';
  }

  @override
  String get staffMyCentersSubtitle =>
      'Set a location, request what is missing';

  @override
  String get pendingRegistrationsRetiring =>
      'Full registrations are no longer started on the phone; families are entered on the EC Board. Sync or fix the ones below. This screen goes away once they are done.';

  @override
  String get monitoringTitle => 'Monitoring';

  @override
  String get staffTabMonitoring => 'Monitoring';

  @override
  String get monitoringOverview => 'Overview';

  @override
  String get monitoringCenters => 'Centers';

  @override
  String get monitoringBarangays => 'Barangays';

  @override
  String get monitoringRequests => 'Requests';

  @override
  String get monitoringPersons => 'Persons';

  @override
  String get monitoringFamilies => 'Families';

  @override
  String get monitoringInside => 'Inside centers';

  @override
  String get monitoringCentersInUse => 'Centers in use';

  @override
  String monitoringArrivedLastHour(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString arrived in the last hour';
  }

  @override
  String get monitoringNeedsAttention => 'Needs attention';

  @override
  String get monitoringNothingUrgent => 'Nothing needs attention now.';

  @override
  String monitoringCentersSummary(int inUse, String centers, int noCapacity) {
    final intl.NumberFormat inUseNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String inUseString = inUseNumberFormat.format(inUse);
    final intl.NumberFormat noCapacityNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String noCapacityString = noCapacityNumberFormat.format(noCapacity);

    return '$inUseString of $centers in use · $noCapacityString without capacity';
  }

  @override
  String monitoringShort(Object items) {
    return 'Short: $items';
  }

  @override
  String get monitoringNoChecklist => 'No facilities checklist';

  @override
  String monitoringInsideNoCapacity(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString inside · capacity not set';
  }

  @override
  String get monitoringNotNormal => 'Not normal';

  @override
  String get monitoringAllNormal => 'Every barangay is normal.';

  @override
  String get monitoringLatestChanges => 'Latest changes';

  @override
  String get monitoringNoRequests => 'No request is waiting.';

  @override
  String get monitoringNeedsConnection =>
      'Monitoring needs a connection the first time.';

  @override
  String monitoringUpdated(Object age) {
    return 'Updated $age';
  }

  @override
  String get reliefNextInLine => 'Next in line';

  @override
  String get reliefWaitingForBoxes => 'Waiting for more boxes';

  @override
  String reliefOutOfOrderTitle(Object family) {
    return 'Give a box to $family now?';
  }

  @override
  String reliefOutOfOrderBody(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString families with a higher priority are still waiting.',
      one: '1 family with a higher priority is still waiting.',
    );
    return '$_temp0';
  }

  @override
  String countFamilies(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString families',
      one: '1 family',
    );
    return '$_temp0';
  }

  @override
  String countPersons(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString persons',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String countBoxes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString boxes',
      one: '1 box',
    );
    return '$_temp0';
  }

  @override
  String countCenters(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString centers',
      one: '1 center',
    );
    return '$_temp0';
  }

  @override
  String countEvacuees(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString evacuees',
      one: '1 evacuee',
    );
    return '$_temp0';
  }

  @override
  String get registerTitle => 'Register family';

  @override
  String get registerStepHead => 'Head of family';

  @override
  String get registerStepMembers => 'Members';

  @override
  String get registerStepPlace => 'Purok and center';

  @override
  String get registerStepReview => 'Review';

  @override
  String registerStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get registerBack => 'Back';

  @override
  String get registerNext => 'Next';

  @override
  String get registerSave => 'Save';

  @override
  String registerSaved(Object name) {
    return '$name\'s family saved. It is sent now, or when you are back online.';
  }

  @override
  String get registerDiscardDraft => 'Discard this draft';

  @override
  String get registerFirstName => 'First name';

  @override
  String get registerMiddleName => 'Middle name (optional)';

  @override
  String get registerLastName => 'Last name';

  @override
  String get registerSex => 'Sex';

  @override
  String get registerBirthdate => 'Choose the date of birth';

  @override
  String registerBirthdateValue(Object date) {
    return 'Born $date';
  }

  @override
  String get registerMobile => 'Mobile number';

  @override
  String get registerMobileInvalid => '11 digits starting with 09 (or +639)';

  @override
  String get registerPwd => 'Person with disability (PWD)';

  @override
  String get registerPwdType => 'Type of disability';

  @override
  String get registerSoloParent => 'Solo parent';

  @override
  String get registerIndigenous => 'Indigenous person';

  @override
  String get register4ps => '4Ps beneficiary';

  @override
  String get registerMembersHint =>
      'Add the other people of the family. Each one uses the head\'s mobile number unless they have their own.';

  @override
  String get registerAddMember => 'Add member';

  @override
  String get registerEditMember => 'Edit member';

  @override
  String get registerRemoveMember => 'Remove member';

  @override
  String get registerSaveMember => 'Save member';

  @override
  String get registerBarangay => 'Barangay';

  @override
  String get registerCenter => 'Evacuation center';

  @override
  String get registerHomeAddress => 'Home address (optional)';

  @override
  String get registerSaveNote =>
      'Saved on this phone first and sent to the server; nothing is lost offline.';

  @override
  String get sexFemaleShort => 'Female';

  @override
  String get sexMaleShort => 'Male';

  @override
  String get staffTabHome => 'Home';

  @override
  String get homeEvacueesHere => 'Evacuees in my centers';

  @override
  String get homeWithoutBox => 'Families without a box';

  @override
  String get homeBoxesLeft => 'Boxes left';

  @override
  String get homeEvacuees => 'Evacuees';

  @override
  String get homeNoOccupancyYet => 'No count yet';

  @override
  String get homeCheckInOut => 'Check in / Check out';

  @override
  String get homeGiveBox => 'Give relief box';

  @override
  String get homeTodo => 'To do';

  @override
  String get homeTodoNone => 'Nothing to do right now.';

  @override
  String homeTodoWithoutBox(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count families are waiting for boxes',
      one: '1 family is waiting for a box',
    );
    return '$_temp0';
  }

  @override
  String get homeTodoFinalCountNotSent => 'Final count not sent';

  @override
  String get homeBarangayStatus => 'Barangay status';

  @override
  String get homeAllHotlines => 'All hotlines';

  @override
  String get syncAllSent => 'All sent';

  @override
  String syncWaitingToSend(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waiting to send',
      one: '1 waiting to send',
    );
    return '$_temp0';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsNeedConnection =>
      'Notifications need a connection the first time.';

  @override
  String get notificationsNone => 'No notifications yet.';

  @override
  String get cswdHomeTitle => 'City overview';

  @override
  String get eventStatusActive => 'Active';

  @override
  String get eventStatusMonitoring => 'Monitoring';

  @override
  String get cswdBarangaysByStatus => 'Barangays per status';

  @override
  String cswdCenterNearlyFull(String name, int percent) {
    return '$name is $percent% full';
  }

  @override
  String cswdBarangayShortBoxes(String name, String boxes) {
    return '$name is short $boxes';
  }

  @override
  String countBarangays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count barangays',
      one: '1 barangay',
    );
    return '$_temp0';
  }

  @override
  String cswdFinalCountsNotSent(String barangays, String names) {
    return 'Final count not sent: $barangays ($names)';
  }

  @override
  String get cswdDoThisOnTheWeb =>
      'Other changes (events, centers, accounts, relief stock): do this on the web.';

  @override
  String get cswdOpenMonitoring => 'Open monitoring';

  @override
  String get cswdReadiness => 'Readiness';

  @override
  String cswdReadyCenters(String centers, int approved) {
    return '$centers ready of $approved approved';
  }

  @override
  String cswdBelowStandards(String centers) {
    return 'Below standards: $centers';
  }

  @override
  String cswdBoxStock(String boxes) {
    return 'City box stock: $boxes';
  }

  @override
  String cswdWatchedBarangays(String names) {
    return 'Watched: $names';
  }

  @override
  String get cswdOrderNeedsConnection =>
      'An evacuation order needs a connection. It is never saved to send later.';

  @override
  String cswdOrderTitle(String status, String name) {
    return 'Order $status for $name?';
  }

  @override
  String get cswdOrderBody => 'This notifies the barangay.';

  @override
  String cswdOrderConfirm(String status) {
    return 'Order $status';
  }

  @override
  String barangayStatusOrdered(String status, String name) {
    return '$status ordered for $name.';
  }

  @override
  String get cswdOrderEvacuation => 'Evacuation order';

  @override
  String get staffMorePublic => 'Public';

  @override
  String get staffMorePublicSubtitle =>
      'The resident app: alerts, centers, hotlines';

  @override
  String distanceMetersAway(int meters) {
    return '$meters m away';
  }

  @override
  String distanceKmAway(String km) {
    return '$km km away';
  }

  @override
  String get adviceWatch =>
      'Get ready. Pack your go-bag and listen for updates.';

  @override
  String get adviceFlooding =>
      'Flooding is reported. Move to higher ground if water rises.';

  @override
  String get advicePreemptive =>
      'Preemptive evacuation: go to your evacuation center now.';

  @override
  String get adviceForced =>
      'Forced evacuation: leave now and go to your evacuation center.';

  @override
  String get adviceNormal => 'No action needed. Stay alert.';

  @override
  String get registerWhereStaying => 'Where is the family staying?';

  @override
  String get registerInCenter => 'In a center';

  @override
  String get registerPrivateHouse => 'Private house';

  @override
  String get registerPrivateHouseHint => 'Staying with relatives or friends.';

  @override
  String get registerHostName => 'Name of the relative or friend';

  @override
  String get registerHostPurok => 'Purok of the house';

  @override
  String get registerHostAddress => 'Address of the house';

  @override
  String get registerHostWhere => 'Enter the address or choose the purok.';

  @override
  String privateHouseWith(String host) {
    return 'Private house, with $host';
  }

  @override
  String get privateHousesTitle => 'Private houses';

  @override
  String get privateHousesSubtitle =>
      'Families staying with relatives or friends';

  @override
  String privateHousesSummary(String families, String persons) {
    return '$families, $persons';
  }

  @override
  String get privateHousesNone => 'No family is staying in a private house.';

  @override
  String get privateHouseDetailsPending => 'Details pending';

  @override
  String get cswdPrivateHouseFamilies => 'Families in private houses';

  @override
  String eventSwitchCurrent(String name) {
    return 'Event: $name';
  }

  @override
  String get eventSwitchChange => 'Change';

  @override
  String get eventSwitchTitle => 'Work on which event?';

  @override
  String get eventSwitchOpen => 'Open events';

  @override
  String get eventSwitchClosedEvents => 'Closed events (read-only)';

  @override
  String get eventSwitchClosed => 'Closed';

  @override
  String get eventSwitchClosedReadOnly => 'Closed: read-only';

  @override
  String eventSwitchNowWorkingOn(String name) {
    return 'Now working on \"$name\".';
  }

  @override
  String get eventSwitchNeedsConnection =>
      'Changing the event needs a connection.';

  @override
  String registerSavesTo(String name) {
    return 'Saves to: $name';
  }

  @override
  String registerClosedEvent(String name) {
    return '\"$name\" is closed. A closed event is read-only. Change the event to register a family.';
  }

  @override
  String lateEntriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count late entries',
      one: '1 late entry',
    );
    return '$_temp0';
  }

  @override
  String lateEntriesAdded(String families, String persons) {
    return 'Added: $families, $persons';
  }

  @override
  String lateEntriesRemoved(String families, String persons) {
    return 'Removed: $families, $persons';
  }

  @override
  String lateEntriesSince(String time) {
    return 'since $time';
  }

  @override
  String get lateEntriesNotInValidated =>
      'Not in the validated count, which never changes. Submit an updated count to include them.';

  @override
  String get lateEntriesNotInCount =>
      'Not in your final count yet. Submit an updated count to include them.';

  @override
  String lateEntriesTodo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count late entries, not yet in your final count',
      one: '1 late entry, not yet in your final count',
    );
    return '$_temp0';
  }

  @override
  String cswdLateEntriesPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count late entries pending, not yet in a final count',
      one: '1 late entry pending, not yet in a final count',
    );
    return '$_temp0';
  }

  @override
  String finalCountValidatedAsOf(String families, String time) {
    return 'Validated: $families, report as of $time';
  }

  @override
  String finalCountCentersPrivate(String centers, String private) {
    return 'In centers: $centers · In private houses: $private';
  }

  @override
  String finalCountCheckIncomplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Check: $count families have incomplete details.',
      one: 'Check: 1 family has incomplete details.',
    );
    return '$_temp0';
  }

  @override
  String finalCountCheckDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Check: $count possible duplicates.',
      one: 'Check: 1 possible duplicate.',
    );
    return '$_temp0';
  }

  @override
  String get finalCountAfterThis =>
      'After this, new evacuees are marked as late entries.';

  @override
  String get finalCountReviewFirst => 'Review first';

  @override
  String get finalCountSubmitShort => 'Submit';

  @override
  String orderedByAt(String who, String time) {
    return 'Ordered by $who, $time';
  }

  @override
  String cswdOrderRecordTitle(String status, String name, String event) {
    return 'Record a $status order for $name in $event?';
  }

  @override
  String get cswdOrderWhoOrdered => 'Who ordered it?';

  @override
  String get cswdOrderByMayor => 'The City Mayor';

  @override
  String get cswdOrderByCdrrmo => 'CDRRMO';

  @override
  String get cswdOrderByOther => 'Someone else';

  @override
  String get cswdOrderByOtherName => 'Name who ordered it';

  @override
  String get cswdOrderWhen => 'When?';

  @override
  String get cswdOrderNow => 'Now';

  @override
  String get cswdOrderChangeTime => 'Earlier today';

  @override
  String get cswdOrderRecord => 'Record order';

  @override
  String cswdRegisteredNow(String families, String persons) {
    return 'Registered now: $families, $persons';
  }

  @override
  String get cswdSubmitForBarangay => 'Submit for this barangay';

  @override
  String cswdSubmitForTitle(String name) {
    return 'Submit the final count for $name?';
  }

  @override
  String get cswdSubmitForBody =>
      'The system\'s count at this moment, labelled \"Submitted by CSWD for the barangay\". After this, new evacuees are marked as late entries.';

  @override
  String cswdSubmitForDone(String name) {
    return 'Final count submitted for $name.';
  }

  @override
  String get cswdSubmitNeedsConnection =>
      'Submitting for a barangay needs a connection.';

  @override
  String cswdOfficialSubmits(String name) {
    return '$name\'s official submits the count.';
  }

  @override
  String get transfersTitle => 'Transfers';

  @override
  String get transfersSubtitle =>
      'Moving families to another barangay\'s center';

  @override
  String transfersWaitingAnswer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count requests waiting for an answer',
      one: '1 request waiting for an answer',
    );
    return '$_temp0';
  }

  @override
  String get transfersAll => 'All';

  @override
  String get transfersNone => 'No transfer requests.';

  @override
  String get transferPending => 'Pending';

  @override
  String get transferAccepted => 'Accepted';

  @override
  String get transferDeclined => 'Declined';

  @override
  String get transferEscalated => 'Escalated to CSWD';

  @override
  String transferIncoming(String barangay) {
    return 'From $barangay';
  }

  @override
  String transferOutgoing(String barangay) {
    return 'To $barangay';
  }

  @override
  String transferBetween(String from, String to) {
    return '$from to $to';
  }

  @override
  String transferMoveSummary(
    String families,
    String persons,
    String from,
    String to,
  ) {
    return '$families ($persons) from $from to $to';
  }

  @override
  String transferFamilyLine(String head, String persons) {
    return '$head: $persons';
  }

  @override
  String transferReasonLine(String reason) {
    return 'Reason: $reason';
  }

  @override
  String transferRequestedBy(String who, String time) {
    return 'Asked by $who, $time';
  }

  @override
  String transferEscalatedNote(String time) {
    return 'No answer in 30 minutes: CSWD was told at $time and can decide it.';
  }

  @override
  String transferDecidedBy(String who, String time) {
    return 'Answered by $who, $time';
  }

  @override
  String transferByCswd(String name) {
    return '$name (CSWD)';
  }

  @override
  String transferDeclineReasonLine(String reason) {
    return 'Why declined: $reason';
  }

  @override
  String get transferAccept => 'Accept';

  @override
  String get transferDecline => 'Decline';

  @override
  String get transferAcceptTitle => 'Accept these families?';

  @override
  String get transferDeclineTitle => 'Decline this request?';

  @override
  String get transferDeclineReason => 'Why? (the sender sees this)';

  @override
  String get transferNeedsConnection =>
      'Needs a connection. Transfers are never saved to send later.';

  @override
  String get transferAskTitle => 'Ask another barangay\'s center';

  @override
  String transferFromCenter(String center) {
    return 'From $center';
  }

  @override
  String get transferStepFamilies => 'Families to move';

  @override
  String get transferStepFamiliesHint =>
      'Your barangay\'s families at this center.';

  @override
  String get transferStepCenter => 'Move them to';

  @override
  String get transferPickFamiliesFirst => 'Tick the families first.';

  @override
  String get transferNoCenterWithSpace =>
      'No other barangay\'s center has space.';

  @override
  String get transferStepReason => 'Reason';

  @override
  String get transferReason => 'Why are they moving?';

  @override
  String get transferReasonHint => 'The receiving barangay sees this.';

  @override
  String transferRoomFor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Room for $count',
      one: 'Room for 1',
    );
    return '$_temp0';
  }

  @override
  String transferAboutKm(String km) {
    return 'about $km km';
  }

  @override
  String get capacityUnknownTag => 'Capacity unknown';

  @override
  String get capacityEstimatedShort => 'est.';

  @override
  String get transferSend => 'Send request';

  @override
  String transferSendTitle(String barangay) {
    return 'Ask $barangay to take these families?';
  }

  @override
  String get transferStayUntilAccepted =>
      'The families stay at their center until it is accepted.';

  @override
  String get transferSent => 'Transfer request sent.';

  @override
  String get cswdMove => 'Move';

  @override
  String get cswdMoveHint =>
      'Move a family to any center. A reason is required.';

  @override
  String cswdMoveTitle(String family) {
    return 'Move $family?';
  }

  @override
  String get cswdMoveReason => 'Reason';

  @override
  String get cswdMoveReasonRequired => 'Required. Saved in the activity log.';

  @override
  String cswdMoved(String family, String center) {
    return '$family moved to $center.';
  }

  @override
  String capacityEstimated(String figure) {
    return '$figure est.';
  }

  @override
  String capacityResidentEstimated(String figure) {
    return '$figure (estimated)';
  }

  @override
  String capacityOccupancyUnknown(int occupancy) {
    return '$occupancy / – (capacity unknown)';
  }

  @override
  String get capacityBasisPeak => 'Estimated from the 2025 peak';

  @override
  String get capacityBasisMedian =>
      'Estimated: median of the same type of center';

  @override
  String cswdTransfersWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfer requests waiting',
      one: '1 transfer request waiting',
    );
    return '$_temp0';
  }

  @override
  String get pressBackAgainToExit => 'Press back again to exit';

  @override
  String yourAreaTitle(String name) {
    return 'Your area: Brgy. $name';
  }

  @override
  String get yourAreaStatusUnavailable =>
      'Status not available yet. Pull down to refresh when online.';

  @override
  String staffBannerSignedIn(String name) {
    return 'Signed in as staff: $name';
  }

  @override
  String get staffBannerBack => 'Staff Mode';

  @override
  String get noSavedCopyYet =>
      'Nothing is saved on this phone yet: connect once to save it for offline use.';

  @override
  String get situationEvacuationOrdered => 'Evacuation ordered';

  @override
  String situationEvacuatingBarangays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count barangays are under preemptive or forced evacuation.',
      one: '1 barangay is under preemptive or forced evacuation.',
    );
    return '$_temp0';
  }

  @override
  String get situationOnWatch => 'On watch';

  @override
  String situationWatchingBarangays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count barangays are on watch or have flooding reported.',
      one: '1 barangay is on watch or has flooding reported.',
    );
    return '$_temp0';
  }

  @override
  String get situationMonitoring => 'Being monitored';

  @override
  String get situationNoEvacuation => 'No barangay has to evacuate.';

  @override
  String get statusNearlyFull => 'Nearly full';

  @override
  String get requestStatusSent => 'Sent';

  @override
  String get requestStatusReceived => 'Received';

  @override
  String get lockTitle => 'Locked';

  @override
  String get lockAvailableWhenActive => 'Available when the event is Active';

  @override
  String get lockClosedEvent => 'This event is closed. It is read-only.';

  @override
  String get durationLessThanMinute => 'less than a minute';

  @override
  String durationMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String durationDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String durationAgo(String duration) {
    return '$duration ago';
  }

  @override
  String waitingDuration(String duration) {
    return 'Waiting $duration';
  }

  @override
  String get arrivingButton => 'Families are arriving';

  @override
  String get arrivingTitle => 'Tell CSWD that families are arriving?';

  @override
  String get arrivingBody =>
      'CSWD is told right away. Nothing else changes: registration opens when CSWD starts the evacuation.';

  @override
  String get arrivingNote => 'Note for CSWD (optional)';

  @override
  String get arrivingSend => 'Tell CSWD';

  @override
  String get arrivingSent => 'CSWD was told.';

  @override
  String get arrivingNeedsConnection =>
      'Needs a connection. CSWD has to hear this now, so it is not saved for later.';

  @override
  String get registrationOpenTitle => 'Registration is open';

  @override
  String registrationOpenBody(String event) {
    return '$event is now Active. Register families, check in your listed families and give relief.';
  }

  @override
  String get planTitle => 'Plan';

  @override
  String get planForTitle => 'Plan for';

  @override
  String planForRange(String low, String high) {
    return 'Forecast $low to $high families';
  }

  @override
  String get planAboveSeen => 'Above anything seen before';

  @override
  String get planNoForecast => 'No forecast for this event yet.';

  @override
  String get planNoForecastVolcanic =>
      'No forecast for volcanic events yet. Plan using the barangays inside the danger zone.';

  @override
  String get planYourList => 'Your list';

  @override
  String get planListNone => 'No families listed yet';

  @override
  String get planListAdd => 'List the families you expect to evacuate.';

  @override
  String planListCheckedIn(String checkedIn, String families) {
    return '$checkedIn of $families checked in';
  }

  @override
  String get planSpaceTitle => 'Center space vs forecast';

  @override
  String planSpaceFigure(String space, String needed) {
    return '$space spaces for $needed persons';
  }

  @override
  String planSpaceShort(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Short of $countString spaces',
      one: 'Short of 1 space',
    );
    return '$_temp0';
  }

  @override
  String get planSpaceEnough => 'Enough space for the forecast';

  @override
  String get planSpaceUnknown =>
      'Space unknown: enter your centers\' capacities.';

  @override
  String planCentersWithoutCapacity(String centers) {
    return '$centers without a capacity';
  }

  @override
  String get planCentersReady => 'Centers ready';

  @override
  String planOfTotal(String count, String total) {
    return '$count of $total';
  }

  @override
  String statusUpdatedAgo(String ago) {
    return 'Updated $ago';
  }

  @override
  String get statusChange => 'Change status';

  @override
  String get todoRequestSupplies => 'Request supplies';

  @override
  String get todoOpenCenters => 'Open centers';

  @override
  String get listTitle => 'Families to evacuate';

  @override
  String get listNotEvacuees =>
      'A listed family is not an evacuee: it counts only once it is checked in.';

  @override
  String get listAdd => 'Add family';

  @override
  String get listAdded => 'Family added to the list.';

  @override
  String get listFromPast => 'From past events';

  @override
  String get listNewFamily => 'New family';

  @override
  String get listSearchPast => 'Search by name';

  @override
  String get listNoPastFamilies => 'No family from past events matches.';

  @override
  String get listFromPastEvent => 'From a past event';

  @override
  String get listHeadFirstName => 'Head\'s first name';

  @override
  String get listHeadLastName => 'Head\'s last name';

  @override
  String get listMembersCount => 'Members, with the head';

  @override
  String get listPurok => 'Purok';

  @override
  String get listContactNumber => 'Contact number (optional)';

  @override
  String get listNote => 'Note (optional)';

  @override
  String get listCheckedIn => 'Checked in';

  @override
  String get listCheckedInTag => 'Checked in';

  @override
  String get listCheckIn => 'Check in';

  @override
  String listCheckInTitle(String head) {
    return 'Check in $head';
  }

  @override
  String listCheckInQueued(String head) {
    return '$head: check-in saved. It is sent when online.';
  }

  @override
  String listedCheckInSummary(String head, String place) {
    return 'Check in $head at $place';
  }

  @override
  String get listAtCenter => 'Evacuation center';

  @override
  String get listHostName => 'Host\'s name';

  @override
  String get listHostPurok => 'Host\'s purok';

  @override
  String get listHostAddress => 'Host\'s address';

  @override
  String get listHighRisk => 'High risk';

  @override
  String get listHighRiskPuroks => 'High-risk puroks';

  @override
  String get listHighRiskHint =>
      'Mark the puroks at high risk. Their families come first on the list.';

  @override
  String get listRiskFlood => 'High risk of flooding';

  @override
  String get listRiskLandslide => 'High risk of landslide';

  @override
  String get listRemove => 'Remove from the list';

  @override
  String listRemoveTitle(String head) {
    return 'Remove $head from the list?';
  }

  @override
  String get listNeedsConnection => 'Needs a connection.';

  @override
  String get pendingCswdApproval => 'Pending CSWD approval';

  @override
  String get centerNeedsDetails => 'Needs details:';

  @override
  String get centerNeedCapacity => 'Capacity';

  @override
  String get centerNeedCapacityEst => 'Capacity is an estimate';

  @override
  String get centerNeedLocation => 'Map location';

  @override
  String get centerNeedChecklist => 'Facilities checklist';

  @override
  String get centerLocationUseMine => 'Use my current location';

  @override
  String get centerLocationPickOnMap => 'Pick on the map';

  @override
  String get centerLocationCswdSaves =>
      'As CSWD, the location is saved at once.';

  @override
  String get centerMapPickerTitle => 'Center location';

  @override
  String centerMapPickerHint(String center) {
    return 'Move the map until the pin is on $center\'s entrance.';
  }

  @override
  String get centerMapPickerUse => 'Use this point';

  @override
  String get centerMapPickerPin => 'The chosen point';

  @override
  String get centerMapPickerSatellite => 'Switch map or satellite';

  @override
  String get pendingCenterWarning =>
      'Pending CSWD approval. You can register families here while the event is Active; CSWD is told at once.';

  @override
  String get familyTransfer => 'Transfer';

  @override
  String familyTransferTitle(String family) {
    return 'Transfer $family';
  }

  @override
  String get familyMoveOurCenters => 'To another of our centers';

  @override
  String get familyMoveNoOtherCenter =>
      'Your barangay has no other center open.';

  @override
  String get familyMoveOtherBarangay =>
      'Another barangay\'s center accepts or declines.';

  @override
  String familyMoveConfirm(String family, String members, String center) {
    return 'Move $family ($members) to $center?';
  }

  @override
  String get familyMoveReason => 'Reason (optional)';

  @override
  String get familyMove => 'Move';

  @override
  String familyMoved(String center) {
    return 'Moved to $center.';
  }

  @override
  String centerAlmostFull(int percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return 'This center is $percentString% full.';
  }

  @override
  String get askAnotherCenterForSpace => 'Ask another center for space';

  @override
  String reliefPriority(String label) {
    return 'Priority: $label';
  }

  @override
  String reliefFromBarangay(String barangay) {
    return 'From $barangay';
  }

  @override
  String reliefGivenByHost(String barangay) {
    return 'Staying in $barangay: they give the box';
  }

  @override
  String get reliefNotOurs => 'Given by the barangay where they stay';

  @override
  String get reliefNeedRegistered => 'Need (registered)';

  @override
  String get reliefNeedRegisteredBasis =>
      'Need based on the registered count, not yet validated. Boxes can already be given.';

  @override
  String get reliefRoundOnePlan => 'Round 1 plan';

  @override
  String get reliefRoundOneFromList => 'One box per family on your list.';

  @override
  String get reliefRoundOneFromForecast =>
      'One box per family at the high end of the forecast.';

  @override
  String get reliefRoundOneOneBox =>
      'One box per family: your list or the forecast, whichever is more.';

  @override
  String quantityWithUnit(String quantity, String unit) {
    return '$quantity $unit';
  }

  @override
  String facilityApprovedOf(String approved, String asked) {
    return 'Approved $approved of $asked';
  }

  @override
  String get facilityMarkReceived => 'Mark received';

  @override
  String get facilityReceiveTitle => 'Mark this request received?';

  @override
  String facilityReceiveSummary(String what, String center) {
    return 'Received: $what at $center';
  }

  @override
  String get facilityRequestAgain => 'Request again';

  @override
  String get facilityRequestUnit => 'Unit (optional)';

  @override
  String get facilityRequestUnitHint => 'e.g. pieces, boxes, liters';

  @override
  String get facilitySuggested => 'Suggested for your centers';

  @override
  String get facilitySuggestedHint =>
      'What each center is short of for a full center, minus what you already asked.';

  @override
  String get facilitySuggestedNone =>
      'Nothing to suggest: your centers have what the standards ask, or it is already requested.';

  @override
  String get facilityYourRequests => 'Your requests';

  @override
  String get facilityRequestWhichCenter => 'For which center?';

  @override
  String get finalCountNothingNew => 'Nothing new since your validated count.';

  @override
  String get alertLevelEmergency => 'Emergency';

  @override
  String get alertLevelAdvisory => 'Advisory';

  @override
  String get alertLevelInfo => 'Info';

  @override
  String get alertLevelAllClear => 'All clear';

  @override
  String get alertNew => 'New';

  @override
  String get passwordChangeTitle => 'Choose your password';

  @override
  String get passwordChangeBody =>
      'You signed in with a temporary password. Choose your own before you continue. Your other sign-ins on other phones end.';

  @override
  String get passwordCurrent => 'Temporary (current) password';

  @override
  String get passwordNew => 'New password (at least 10 characters)';

  @override
  String get passwordConfirm => 'New password again';

  @override
  String get passwordTooShort => 'At least 10 characters.';

  @override
  String get passwordSameAsOld =>
      'Choose a password different from the temporary one.';

  @override
  String get passwordMismatch => 'The two passwords are not the same.';

  @override
  String get passwordSave => 'Save password';

  @override
  String get passwordShow => 'Show or hide the password';

  @override
  String get maintenanceDefault => 'E-LIKAS is being updated. Try again later.';

  @override
  String get reportTitle => 'Report a problem';

  @override
  String get reportSubtitle => 'Tell the administrator what went wrong';

  @override
  String get reportIntro =>
      'The administrator reads every report and answers here.';

  @override
  String get reportWhatHappened => 'What happened?';

  @override
  String get reportWhatHappenedHint =>
      'At least 10 characters. What you did, what you expected, what you saw.';

  @override
  String get reportScreen => 'Screen';

  @override
  String get reportPhoto => 'Photo (optional)';

  @override
  String get reportPhotoPrivacy =>
      'Do not include evacuees\' names or details in the photo.';

  @override
  String get reportPhotoCamera => 'Camera';

  @override
  String get reportPhotoGallery => 'Gallery';

  @override
  String get reportPhotoRemove => 'Remove the photo';

  @override
  String get reportPhotoFailed => 'Could not get the photo.';

  @override
  String get reportSend => 'Send report';

  @override
  String get reportSent => 'Report sent. The administrator will answer here.';

  @override
  String get reportNeedsConnection => 'Needs a connection.';

  @override
  String get reportYours => 'Your reports';

  @override
  String get reportNone => 'No reports yet.';

  @override
  String reportReply(String name, String reply) {
    return 'Reply from $name: $reply';
  }

  @override
  String get cswdNeedsConnection =>
      'Needs a connection. This tells people now, so it is not saved for later.';

  @override
  String cswdStartTitle(String event) {
    return '$event is being monitored';
  }

  @override
  String get cswdStartHint =>
      'Registration, relief, transfers and final counts open when you start the evacuation.';

  @override
  String get cswdStartEvacuation => 'Start evacuation';

  @override
  String cswdStartConfirmTitle(String event) {
    return 'Start the evacuation for $event?';
  }

  @override
  String get cswdStartConfirmBody =>
      'The event becomes Active. Every barangay official is told that registration is open. This cannot be undone from the app.';

  @override
  String cswdStartDone(String event) {
    return '$event is now Active.';
  }

  @override
  String get cswdAskUpdate => 'Ask barangay to update';

  @override
  String cswdAskUpdateTitle(String barangay) {
    return 'Ask $barangay to update its status?';
  }

  @override
  String get cswdAskUpdateBody =>
      'The barangay\'s officials get a notification. Their status stays theirs to set.';

  @override
  String cswdAskUpdateDone(String barangay) {
    return '$barangay was asked to update.';
  }

  @override
  String get cswdRemind => 'Remind';

  @override
  String get cswdRemindFinalCount => 'Remind final count';

  @override
  String cswdRemindTitle(String barangay) {
    return 'Remind $barangay to send its final count?';
  }

  @override
  String get cswdRemindBody => 'The barangay\'s officials get a notification.';

  @override
  String cswdRemindDone(String barangay) {
    return '$barangay was reminded.';
  }

  @override
  String get cswdProgressTitle => 'Evacuation progress';

  @override
  String get cswdProgressHint =>
      'Registered families against each barangay\'s list of families to evacuate. Behind first.';

  @override
  String cswdProgressLine(String registered, String expected) {
    return '$registered of $expected expected families registered';
  }

  @override
  String cswdProgressNoList(String families) {
    return '$families registered · no list';
  }

  @override
  String cswdProgressListCheckedIn(String checkedIn, String listed) {
    return '$checkedIn of $listed listed families checked in';
  }

  @override
  String get cswdProgressNone => 'No barangay figures yet.';
}
