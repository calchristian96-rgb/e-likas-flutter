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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count evacuation centers',
      one: '1 evacuation center',
    );
    return '$_temp0';
  }

  @override
  String publicAlertsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count public alerts',
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cached items',
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count $severity alerts',
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
  String get noCentersMatchFilter => 'No centers match your search or filter.';

  @override
  String filteredCentersCount(int count, String status) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count $status centers',
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
    String _temp0 = intl.Intl.pluralLogic(
      quantity,
      locale: localeName,
      other: '$quantity available',
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
  String get staffWorkspaceRegisterFamily => 'Register a Family';

  @override
  String get staffWorkspaceRegisterFamilySubtitle =>
      'Works offline — syncs when you\'re ready';

  @override
  String get staffWorkspacePendingRegistrations => 'Pending Registrations';

  @override
  String get staffWorkspacePendingRegistrationsSubtitle =>
      'Offline queue — review, edit, and sync';

  @override
  String get staffWorkspaceAllEvacuees => 'All Evacuees';

  @override
  String get staffWorkspaceAllEvacueesSubtitle => 'Browse registered families';

  @override
  String get staffWorkspaceSyncNow => 'Sync Now';

  @override
  String get staffWorkspaceSyncNowSubtitle =>
      'Push pending registrations and refresh cached data';

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
  String get staffFamiliesPageTitle => 'Registered Families';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registrations synced.',
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
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
  String get staffRegDisplacementOutsideCenter => 'Outside evacuation center';

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
  String get staffLoginEmailLabel => 'Email';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts',
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
  String get ecBoardEntryPointSubtitle =>
      'Add evacuees and view the age/sex breakdown for this center';

  @override
  String get ecBoardAddEvacueeTitle => 'Add Evacuee';

  @override
  String get ecBoardEditEvacueeTitle => 'Edit Evacuee Entry';

  @override
  String get ecBoardEntryDetailTitle => 'Evacuee Entry';

  @override
  String get ecBoardFieldSex => 'Sex';

  @override
  String get ecBoardFieldAgeBracket => 'Age Bracket';

  @override
  String get ecBoardFieldHousehold => 'Household';

  @override
  String get ecBoardHouseholdExisting => 'Existing household';

  @override
  String get ecBoardHouseholdNew => 'New household';

  @override
  String get ecBoardSelectHouseholdButton => 'Select household';

  @override
  String get ecBoardHouseholdSearchHint => 'Search by head of family name';

  @override
  String get ecBoardRefreshHouseholdsTooltip => 'Refresh household list';

  @override
  String get ecBoardHouseholdsUpToDate => 'Up to date';

  @override
  String get ecBoardPendingHouseholdBadge => 'Pending — not yet synced';

  @override
  String get ecBoardPendingHouseholdNotice =>
      'This household hasn\'t synced yet. This entry will sync automatically once it does.';

  @override
  String get ecBoardNewHouseholdHeadName => 'Head of Household Name';

  @override
  String get ecBoardSubmitButton => 'Save Evacuee';

  @override
  String get ecBoardValidationBanner =>
      'Please complete sex, age bracket, and household before saving.';

  @override
  String get ecBoardSavedOfflineMessage =>
      'Saved offline. It will sync when you\'re back online.';

  @override
  String get ecBoardSavedPendingHouseholdMessage =>
      'Saved — waiting for the selected household to sync first.';

  @override
  String get ecBoardSuccessMessage => 'Evacuee added successfully.';

  @override
  String get ecBoardNoEventsAvailable =>
      'No evacuation events are available yet.';

  @override
  String get ecBoardLastKnownSectionTitle => 'Last Known Breakdown';

  @override
  String get ecBoardLastKnownSectionSubtitle =>
      'Live count of evacuees already confirmed on the server.';

  @override
  String get ecBoardLastKnownUnavailable =>
      'Could not load the last known breakdown.';

  @override
  String get ecBoardLastKnownEmpty =>
      'No evacuees recorded for this center and event yet.';

  @override
  String get ecBoardUnclassifiedLabel => 'Unclassified';

  @override
  String get ecBoardPendingSectionTitle => 'This Device\'s Pending Entries';

  @override
  String get ecBoardPendingSectionSubtitle =>
      'Not yet synced — kept separate from the confirmed count above.';

  @override
  String get ecBoardPendingListTitle => 'Pending Entries';

  @override
  String get ecBoardPendingListEmpty => 'No pending entries on this device.';

  @override
  String get ecBoardTotalLabel => 'Total';

  @override
  String ecBoardMaleFemaleCount(int male, int female) {
    return '${male}M / ${female}F';
  }

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
  String get ecBoardSectoralGroupsSectionTitle => 'Sectoral Groups';

  @override
  String get ecBoardSectoralGroupsSectionSubtitle =>
      'Staff-reported totals, entered separately from Add Evacuee.';

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
}
