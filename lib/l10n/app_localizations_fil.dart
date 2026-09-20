// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navMap => 'Mapa';

  @override
  String get navNearestCenter => 'Malapit na Center';

  @override
  String get navAlerts => 'Mga Alerto';

  @override
  String get navHotlines => 'Mga Hotline';

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
  String get cached => 'Naka-save';

  @override
  String get unavailable => 'Hindi available';

  @override
  String get freshnessCaution => 'Pansin';

  @override
  String get freshnessSavedVerb => 'Na-save';

  @override
  String get freshnessLastUpdatedVerb => 'Huling na-update';

  @override
  String get viewAlertsTooltip => 'Tingnan ang mga alerto';

  @override
  String get couldNotLoadCenters => 'Hindi na-load ang mga center';

  @override
  String get viewRoute => 'Tingnan ang ruta';

  @override
  String get invalidAlertLink => 'Hindi valid ang link ng alertong ito.';

  @override
  String callNumberTooltip(String number) {
    return 'Tumawag sa $number';
  }

  @override
  String copyNumberTooltip(String number) {
    return 'Kopyahin ang $number sa clipboard';
  }

  @override
  String get retry => 'Subukan Muli';

  @override
  String get refresh => 'I-refresh';

  @override
  String get viewAll => 'Tingnan lahat';

  @override
  String get viewDetails => 'Tingnan ang Detalye';

  @override
  String get getDirections => 'Kumuha ng Direksyon';

  @override
  String get openSettings => 'Buksan ang Settings';

  @override
  String get copy => 'Kopyahin';

  @override
  String get call => 'Tumawag';

  @override
  String get dismiss => 'Isara';

  @override
  String get view => 'Tingnan';

  @override
  String get tryAgain => 'Subukan muli';

  @override
  String get language => 'Wika';

  @override
  String get selectLanguage => 'Pumili ng wika';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFilipino => 'Filipino';

  @override
  String get languageBikolLigao => 'Bikol (Ligao)';

  @override
  String get preparingEmergencyInfo =>
      'Inihahanda ang impormasyong pang-emerhensiya…';

  @override
  String get goodMorning => 'Magandang umaga';

  @override
  String get goodAfternoon => 'Magandang hapon';

  @override
  String get goodEvening => 'Magandang gabi';

  @override
  String get stayInformedSubtitle => 'Manatiling updated at handa.';

  @override
  String get dashboardSummary => 'Buod ng Dashboard';

  @override
  String get quickActions => 'Mabilisang Aksyon';

  @override
  String get viewAllEvacuationCenters => 'Tingnan Lahat ng Evacuation Center';

  @override
  String get refreshData => 'I-refresh ang Datos';

  @override
  String get emergencyHotlines => 'Mga Hotline para sa Emerhensiya';

  @override
  String get statEvacuationCenters => 'Mga evacuation center';

  @override
  String get statPublicAlerts => 'Mga pampublikong alerto';

  @override
  String get statDataStatus => 'Katayuan ng Datos';

  @override
  String get noDataYet => 'Wala pang datos';

  @override
  String get nearestEvacuationCenterHeading =>
      'Pinakamalapit na evacuation center';

  @override
  String get recentAlerts => 'Mga Kamakailang Alerto';

  @override
  String get safetyTips => 'Mga Payo sa Kaligtasan';

  @override
  String get noActiveAlerts => 'Walang aktibong alerto';

  @override
  String get noActiveEmergencyAlerts =>
      'Walang aktibong alerto pang-emerhensiya';

  @override
  String get normalMonitoring =>
      'Normal ang kalagayan sa Ligao City sa ngayon.';

  @override
  String get liveDataUnavailable =>
      'Pansamantalang hindi available ang live data';

  @override
  String get showingSavedInfo =>
      'Ipinapakita ang pinakahuling naka-save na impormasyon.';

  @override
  String get nearestCenterUnavailable =>
      'Hindi available ang pinakamalapit na center';

  @override
  String get enableLocationServices =>
      'I-enable ang location services o subukan muli mamaya.';

  @override
  String get noNearbyEvacuationCenters =>
      'Wala pang malapit na evacuation center na ipapakita.';

  @override
  String get youAreViewingLiveData => 'Nakikita mo ang live data.';

  @override
  String get checkingForAlerts => 'Sinusuri ang mga alertong pang-emerhensiya…';

  @override
  String get alertsTitle => 'Mga Alerto';

  @override
  String get alertDetailsTitle => 'Detalye ng Alerto';

  @override
  String get noPublicAlerts => 'Wala pang pampublikong alerto na ipapakita.';

  @override
  String get dateUnavailable => 'Hindi available ang petsa';

  @override
  String get sentBy => 'Ipinadala ni';

  @override
  String get sentTo => 'Ipinadala kay';

  @override
  String get evacuationEvent => 'Kaganapang pang-evacuation';

  @override
  String get couldNotLoadAlerts => 'Hindi na-load ang mga alerto';

  @override
  String get newAlertReceived => 'May natanggap na bagong alerto';

  @override
  String get newAdvisoryReceived => 'May natanggap na bagong advisory';

  @override
  String get emergencyAlertReceived =>
      'May natanggap na alertong pang-emerhensiya';

  @override
  String get newInformationAlert => 'May bagong impormasyon';

  @override
  String get allClearUpdateReceived => 'May natanggap na all-clear update';

  @override
  String get severityMandatory => 'Sapilitan';

  @override
  String get severityAdvisory => 'Advisory';

  @override
  String get severityInfo => 'Impormasyon';

  @override
  String get severityAllClear => 'Ligtas na';

  @override
  String get statusActive => 'Aktibo';

  @override
  String get statusFull => 'Puno';

  @override
  String get statusClosed => 'Sarado';

  @override
  String get statusOnStandby => 'Nakahanda';

  @override
  String get evacuationCentersTitle => 'Mga Evacuation Center';

  @override
  String get noEvacuationCenters => 'Wala pang evacuation center na ipapakita.';

  @override
  String evacuationCentersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count evacuation center',
      one: '1 evacuation center',
    );
    return '$_temp0';
  }

  @override
  String publicAlertsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pampublikong alerto',
      one: '1 pampublikong alerto',
    );
    return '$_temp0';
  }

  @override
  String get nearestCenterTitle => 'Pinakamalapit na Center';

  @override
  String get locationPermissionDenied =>
      'Hindi pinayagan ang location permission.';

  @override
  String get locationServicesOff => 'Naka-off ang location services.';

  @override
  String get locationPermanentlyDenied =>
      'Permanenteng naka-deny ang location permission — i-enable ito sa system settings.';

  @override
  String get couldNotDetermineLocation =>
      'Hindi matukoy ang kasalukuyang lokasyon.';

  @override
  String get couldNotLoadNearbyCenters =>
      'Hindi na-load ang mga malapit na center';

  @override
  String get emergencyHotlinesTitle => 'Mga Hotline para sa Emerhensiya';

  @override
  String get hotlinesOfflineNote =>
      'Naka-save ang mga numerong ito sa iyong device at gumagana kahit walang internet.';

  @override
  String get couldNotOpenDialer =>
      'Hindi mabuksan ang phone dialer — gamitin ang Kopyahin ang Numero para i-dial nang manu-mano.';

  @override
  String get copiedToClipboard => 'Nakopya sa clipboard';

  @override
  String get weatherNotYetAvailable =>
      'Hindi pa available ang mga update ng panahon sa app na ito.';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionOfflineData => 'Offline at Datos';

  @override
  String get settingsOfflineData => 'Offline na Datos';

  @override
  String get settingsOfflineDataSubtitle =>
      'Pamahalaan ang na-save na datos para sa offline access';

  @override
  String get settingsSyncNow => 'I-sync Ngayon';

  @override
  String get settingsSyncButton => 'I-sync';

  @override
  String get settingsSyncNeverRun => 'Hindi pa na-sync';

  @override
  String get settingsConnectivity => 'Koneksyon';

  @override
  String get settingsSectionPreferences => 'Mga Kagustuhan';

  @override
  String get appAppearance => 'Itsura ng App';

  @override
  String get appearanceSystem => 'Default ng system';

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
      'Magrehistro ng mga pamilya at pamahalaan ang mga rekord ng paglikas';

  @override
  String get staffDashboardTitle => 'Staff Dashboard';

  @override
  String get staffDashboardSubtitle =>
      'Magrehistro ng mga pamilya, evacuee, sentro, at higit pa';

  @override
  String staffIdentityWithBarangay(String role, String barangay) {
    return '$role · Brgy. $barangay';
  }

  @override
  String get settingsSectionNotifications => 'Mga Abiso';

  @override
  String get pushNotificationsTitle => 'Push Notifications';

  @override
  String get pushNotificationsSubtitle =>
      'Hindi pa available — walang notification service na naka-set up sa backend. Sine-save lang nito ang iyong kagustuhan sa device na ito.';

  @override
  String get settingsSectionAbout => 'Tungkol Dito';

  @override
  String get aboutTagline => 'Electronic Ligao Kaligtasan Sistema';

  @override
  String get syncCompleted => 'Na-update ang impormasyon.';

  @override
  String get syncPartialFailure =>
      'May impormasyong hindi na-update. Ipinapakita ang pinakahuling naka-save na datos.';

  @override
  String get offlineDataManagementTitle => 'Pamamahala ng Offline na Datos';

  @override
  String get offlineDataManagementSubtitle =>
      'Pamahalaan ang na-save na impormasyon para sa offline access';

  @override
  String get couldNotLoadOfflineData =>
      'Hindi na-load ang detalye ng offline na datos';

  @override
  String get offlineOverviewCachedRecords => 'Na-cache na Records';

  @override
  String get offlineOverviewStorageUsed => 'Nagamit na Storage';

  @override
  String get offlineOverviewLastUpdated => 'Huling Na-update';

  @override
  String get cachedDataCategoriesTitle => 'Mga Kategorya ng Na-cache na Datos';

  @override
  String cachedItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count na-cache na item',
      one: '1 na-cache na item',
    );
    return '$_temp0';
  }

  @override
  String get noSavedDataForCategory => 'Walang naka-save na datos';

  @override
  String get updateAllData => 'I-update Lahat ng Datos';

  @override
  String get clearCachedData => 'Burahin ang Na-cache na Datos';

  @override
  String get clearCacheDialogTitle =>
      'Burahin ang naka-save na offline na datos?';

  @override
  String get clearCacheDialogBody =>
      'Aalisin nito ang na-save na mga alerto, evacuation center, at impormasyon ng mapa sa device na ito. Maaari itong i-download muli kapag may internet access na.';

  @override
  String get clearCacheDialogConfirm => 'Burahin ang Datos';

  @override
  String get cacheCleared => 'Nabura ang offline na datos.';

  @override
  String get hazardMapTitle => 'Mapa ng Panganib';

  @override
  String get noMapData => 'Wala pang available na map data.';

  @override
  String get couldNotLoadMapData => 'Hindi na-load ang map data';

  @override
  String get legendEvacuationCenter => 'Evacuation center';

  @override
  String get legendHazardArea => 'Lugar na may panganib';

  @override
  String get showMyLocation => 'Ipakita ang aking lokasyon';

  @override
  String get unableToOpenMaps =>
      'Hindi mabuksan ang maps application sa device na ito.';

  @override
  String get refreshing => 'Nire-refresh…';

  @override
  String get alertsAndNoticesTitle => 'Mga Alerto at Paalala';

  @override
  String get alertsAndNoticesSubtitle =>
      'Real-time na updates para sa Ligao City';

  @override
  String get dateGroupToday => 'Ngayon';

  @override
  String get dateGroupYesterday => 'Kahapon';

  @override
  String filteredAlertsCount(int count, String severity) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count $severity na alerto',
      one: '1 $severity na alerto',
    );
    return '$_temp0';
  }

  @override
  String get searchAlertsHint => 'Maghanap ng alerto';

  @override
  String get clearSearch => 'I-clear ang paghahanap';

  @override
  String get filterAll => 'Lahat';

  @override
  String get noAlertsMatchFilter =>
      'Walang alertong tumutugma sa iyong paghahanap o filter.';

  @override
  String get sortAlertsTooltip => 'Ayusin ang mga alerto';

  @override
  String get sortNewestFirst => 'Pinakabago muna';

  @override
  String get sortOldestFirst => 'Pinakaluma muna';

  @override
  String get sortBySeverity => 'Antas ng Severity';

  @override
  String get latestAlertLabel => 'Pinakabago';

  @override
  String get shareAlert => 'I-share ang alerto';

  @override
  String get additionalInformation => 'Karagdagang impormasyon';

  @override
  String get severityLabel => 'Severity';

  @override
  String get alertTypeLabel => 'Uri';

  @override
  String get receivedLabel => 'Natanggap';

  @override
  String get viewEvacuationCenters => 'Tingnan ang mga evacuation center';

  @override
  String get invalidCenterLink => 'Hindi valid ang link ng center na ito.';

  @override
  String get viewOnMap => 'Tingnan sa mapa';

  @override
  String get refreshLocation => 'I-refresh ang lokasyon';

  @override
  String get otherNearbyCenters => 'Iba pang malapit na center';

  @override
  String get evacuationCentersSubtitle =>
      'Maghanap ng malapit at available na center';

  @override
  String get searchCentersHint => 'Maghanap ng center';

  @override
  String get searchMyEvacuationCentersHint =>
      'Maghanap sa aking mga evacuation center...';

  @override
  String get staffCentersCitywideNotice =>
      'Ipinapakita ang mga center sa buong lungsod para matulungan mong irehistro ang mga residenteng pansamantalang nasa lugar mo.';

  @override
  String get centersYourBarangaySection => 'Ang iyong barangay';

  @override
  String get centersOtherBarangaysSection => 'Ibang mga barangay';

  @override
  String get noCentersMatchFilter =>
      'Walang center na tumutugma sa iyong paghahanap o filter.';

  @override
  String filteredCentersCount(int count, String status) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count $status na center',
      one: '1 $status na center',
    );
    return '$_temp0';
  }

  @override
  String get sortCentersTooltip => 'Ayusin ang mga center';

  @override
  String get sortByName => 'Pangalan';

  @override
  String get sortByOccupancy => 'Occupancy';

  @override
  String get sortByCapacity => 'Capacity';

  @override
  String get centerDetailsTitle => 'Detalye ng center';

  @override
  String get centerNotFound => 'Hindi mahanap ang evacuation center na ito.';

  @override
  String get overviewSectionTitle => 'Buod';

  @override
  String get overviewCapacity => 'Capacity';

  @override
  String get overviewCurrentOccupancy => 'Kasalukuyang occupancy';

  @override
  String get overviewAvailableSlots => 'Bakanteng slot';

  @override
  String get overviewOccupancyPercent => 'Occupancy';

  @override
  String get locationSectionTitle => 'Lokasyon';

  @override
  String get addressUnavailable => 'Hindi available ang address';

  @override
  String get centerMapLocationUnavailable =>
      'Wala pang available na lokasyon sa mapa para sa center na ito.';

  @override
  String get centerPhotoUnavailable => 'Walang available na larawan';

  @override
  String get centerPhotoUnavailableOffline =>
      'Hindi available ang larawan offline';

  @override
  String get facilitiesSectionTitle => 'Pasilidad';

  @override
  String get couldNotLoadFacilities => 'Hindi ma-load ang mga pasilidad';

  @override
  String get facilitiesNotAvailable =>
      'Wala pang impormasyon tungkol sa mga pasilidad.';

  @override
  String get facilityAvailable => 'Available';

  @override
  String get facilityUnavailable => 'Hindi available';

  @override
  String get facilityNotRecorded => 'Wala pang datos';

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
  String get facilityTypeToiletMale => 'C.R. ng Lalaki';

  @override
  String get facilityTypeToiletFemale => 'C.R. ng Babae';

  @override
  String get facilityTypeToiletCommon => 'Karaniwang C.R.';

  @override
  String get facilityTypeBathingAreaMale => 'Paliguan ng Lalaki';

  @override
  String get facilityTypeBathingAreaFemale => 'Paliguan ng Babae';

  @override
  String get facilityTypeBathingAreaCommon => 'Karaniwang Paliguan';

  @override
  String get facilityTypeHandwashingFacility => 'Paghuhugasan ng Kamay';

  @override
  String get facilityTypeLaundrySpace => 'Lababuhan';

  @override
  String get facilityTypeWomenFriendlySpace => 'Espasyo Para sa Kababaihan';

  @override
  String get facilityTypeChildFriendlySpace => 'Espasyo Para sa mga Bata';

  @override
  String get facilityTypeHealthFacility => 'Pasilidad Pangkalusugan';

  @override
  String get facilityTypePrayerRoom => 'Silid-Panalangin';

  @override
  String get facilityTypeCommunityKitchen => 'Kusinang Pangkomunidad';

  @override
  String get facilityTypeLivestockArea => 'Lugar Para sa Alagang Hayop';

  @override
  String get facilityTypeCampManagementDesk => 'Camp Management Desk';

  @override
  String get facilityTypeInfoBoard => 'Info / Help Desk';

  @override
  String get facilityTypeStorageArea => 'Bodega';

  @override
  String get centerTypeSchool => 'Paaralan';

  @override
  String get centerTypeCoveredCourt => 'Covered Court';

  @override
  String get centerTypeChurch => 'Simbahan';

  @override
  String get centerTypeBarangayHall => 'Barangay Hall';

  @override
  String get centerTypeGymnasium => 'Gymnasium';

  @override
  String get centerTypeOther => 'Iba pa';

  @override
  String get centerNoLocationSet => 'Walang naitakdang lokasyon';

  @override
  String get centerChooseLocation => 'Pumili ng Lokasyon';

  @override
  String get centerChangeLocation => 'Palitan';

  @override
  String get centerPasteCoordinatesLabel =>
      'O i-paste ang coordinates (lat, long)';

  @override
  String get centerSetCoordinates => 'I-set';

  @override
  String get centerInvalidCoordinates => 'Hindi valid na latitude o longitude.';

  @override
  String get centerClearLocation => 'Alisin ang Lokasyon';

  @override
  String get centerUseThisLocation => 'Gamitin Itong Lokasyon';

  @override
  String get centerSaveWithoutLocation => 'I-save Nang Walang Lokasyon';

  @override
  String get centerFieldCapacityFamilies => 'Kapasidad (Pamilya)';

  @override
  String get centerFieldCampManager => 'Camp Manager';

  @override
  String get centerFieldCampManagerName => 'Pangalan ng Camp Manager';

  @override
  String get centerFieldCampManagerContact => 'Contact ng Camp Manager';

  @override
  String get centerFieldPhoto => 'Larawan';

  @override
  String get centerFieldName => 'Pangalan ng Center';

  @override
  String get centerFieldType => 'Uri ng Center';

  @override
  String get centerFieldAddress => 'Address';

  @override
  String get centerFieldStatus => 'Status';

  @override
  String get centerFieldBarangay => 'Barangay';

  @override
  String get centerBarangayLockedHelper =>
      'Naka-lock sa iyong itinalagang barangay';

  @override
  String get centerSectionInformation => 'Impormasyon ng Center';

  @override
  String get centerSectionLocation => 'Lokasyon';

  @override
  String get centerSectionCapacity => 'Kapasidad';

  @override
  String get centerEditEvacuationCenter => 'I-edit ang Evacuation Center';

  @override
  String get centerEditNotAllowed =>
      'Maaari mo lang i-edit ang mga evacuation center na sarili mong ginawa.';

  @override
  String get centerCreateEvacuationCenter => 'Gumawa ng Evacuation Center';

  @override
  String get centerSaveChanges => 'I-save ang mga Pagbabago';

  @override
  String get centerCreateSuccessMessage =>
      'Matagumpay na nagawa ang evacuation center.';

  @override
  String get centerUpdateSuccessMessage =>
      'Matagumpay na na-update ang evacuation center.';

  @override
  String get centerValidationBanner =>
      'Suriin ang mga naka-highlight na field at subukan muli.';

  @override
  String get centerOfflineRequired =>
      'Kailangan ng internet connection para magdagdag o mag-edit ng evacuation center.';

  @override
  String get centerTakePhoto => 'Kumuha ng Larawan';

  @override
  String get centerChooseFromGallery => 'Pumili mula sa Gallery';

  @override
  String get centerChoosePhoto => 'Pumili ng Larawan';

  @override
  String get centerChangePhoto => 'Palitan ang Larawan';

  @override
  String get centerDiscardDialogTitle => 'Itapon ang mga pagbabago?';

  @override
  String get centerDiscardDialogBody =>
      'May mga hindi na-save na pagbabago sa evacuation center na ito. Kung aalis ka ngayon, mawawala ang mga ito.';

  @override
  String get centerDiscardDialogConfirm => 'Itapon';

  @override
  String get layersTooltip => 'Mga Layer';

  @override
  String get mapLayersTitle => 'Mga Layer';

  @override
  String get mapLegendTitle => 'Legend ng Mapa';

  @override
  String get fitMapTooltip => 'I-fit ang mapa';

  @override
  String get showEvacuationCenters => 'Ipakita ang mga evacuation center';

  @override
  String get centerStatusLayerLabel => 'Katayuan ng Center';

  @override
  String get hazardAreasLabel => 'Mga Lugar na May Panganib';

  @override
  String get showHazardAreas => 'Ipakita ang mga lugar na may panganib';

  @override
  String get resetFilters => 'I-reset ang mga filter';

  @override
  String get yourLocationLegend => 'Ang iyong lokasyon';

  @override
  String get hazardTypeFlood => 'Baha';

  @override
  String get hazardTypeLandslide => 'Landslide';

  @override
  String get hazardTypeLahar => 'Lahar';

  @override
  String get hazardTypeStormSurge => 'Storm surge';

  @override
  String get hazardTypeVolcanicDangerZone => 'Volcanic danger zone';

  @override
  String get mapBaseLayerLabel => 'Batayang Mapa';

  @override
  String get mapBaseLayerStreet => 'Kalye';

  @override
  String get mapBaseLayerSatellite => 'Satellite';

  @override
  String get mapSatelliteOfflineNotice =>
      'Kailangan ng internet connection ang satellite imagery — hindi ito naka-save para sa offline na paggamit.';

  @override
  String get mapAttributionOpenStreetMap => '© OpenStreetMap contributors';

  @override
  String get mapAttributionEsri => 'Esri World Imagery';

  @override
  String get normalMonitoringTitle => 'Normal na Pagmomonitor';

  @override
  String get viewAlert => 'Tingnan ang Alerto';

  @override
  String get findNearestCenterAction => 'Hanapin ang Pinakamalapit na Center';

  @override
  String get showingSavedAlertInfo =>
      'Ipinapakita ang naka-save na impormasyon ng alerto';

  @override
  String get emergencyHotlinesSubtitle =>
      'Ito ang mga opisyal na serbisyong pang-emerhensiya ng Lungsod ng Ligao.';

  @override
  String get hotlineNumberNotSet => 'Hindi pa nakatakda';

  @override
  String get emergencyCallNowNote =>
      'Para sa mga banta sa buhay, tumawag agad sa tamang serbisyong pang-emerhensiya.';

  @override
  String get hotlineCategoryNationalEmergency => 'Pambansang Emerhensiya';

  @override
  String get hotlineCategoryDisasterResponse => 'Disaster Response';

  @override
  String get hotlineCategoryFire => 'Sunog';

  @override
  String get hotlineCategoryPolice => 'Pulisya';

  @override
  String get hotlineCategoryRescue => 'Rescue';

  @override
  String get hotlineCategoryMedical => 'Medikal';

  @override
  String get hotlineCategorySocialWelfare => 'Kagalingang Panlipunan';

  @override
  String get hotlineCategoryUtility => 'Utilidad';

  @override
  String get favoritesSectionTitle => 'Mga Paborito';

  @override
  String addToFavoritesTooltip(String name) {
    return 'Idagdag ang $name sa paborito';
  }

  @override
  String removeFromFavoritesTooltip(String name) {
    return 'Alisin ang $name sa paborito';
  }

  @override
  String numberCopiedFor(String name) {
    return 'Nakopya ang numero ng $name';
  }

  @override
  String get staffLogoutDialogTitle => 'Mag-sign out?';

  @override
  String get staffLogoutDialogBody =>
      'Kailangan mong mag-sign in muli para ma-access ang mga staff feature.';

  @override
  String get staffLogoutDialogConfirm => 'Mag-sign out';

  @override
  String get staffWorkspaceTitle => 'Staff Dashboard';

  @override
  String get staffWorkspaceRoleLabel => 'Tungkulin';

  @override
  String get staffWorkspaceBarangayLabel => 'Barangay';

  @override
  String get staffWorkspacePendingCount => 'Naghihintay';

  @override
  String get staffWorkspaceNeedsAttentionCount => 'Kailangan ng Aksyon';

  @override
  String get staffWorkspaceFamilyRegistrationSection =>
      'Pagpaparehistro ng Pamilya';

  @override
  String get staffWorkspaceEvacuationCentersSection => 'Mga Evacuation Center';

  @override
  String get staffWorkspaceRecordsSection => 'Mga Talaan';

  @override
  String get staffWorkspaceRegisterFamily => 'Magrehistro ng Pamilya';

  @override
  String get staffWorkspaceRegisterFamilySubtitle =>
      'Gumagana offline — nagsi-sync kapag handa ka na';

  @override
  String get staffWorkspacePendingRegistrations =>
      'Mga Naghihintay na Rehistrasyon';

  @override
  String get staffWorkspacePendingRegistrationsSubtitle =>
      'Offline na pila — suriin, i-edit, at i-sync';

  @override
  String get staffWorkspaceAllEvacuees => 'Lahat ng Evacuee';

  @override
  String get staffWorkspaceAllEvacueesSubtitle =>
      'Tingnan ang mga rehistradong pamilya';

  @override
  String get staffWorkspaceSyncNow => 'I-sync Ngayon';

  @override
  String get staffWorkspaceLogout => 'Staff Logout';

  @override
  String get staffWorkspaceLogoutSubtitle =>
      'Bumalik sa karaniwang karanasan ng residente';

  @override
  String get staffAddEvacuationCenter => 'Magdagdag ng Evacuation Center';

  @override
  String get staffAddEvacuationCenterSubtitle =>
      'Online lamang — hindi ini-queue offline';

  @override
  String get staffManageEvacuationCenters => 'Aking mga Evacuation Center';

  @override
  String get staffManageEvacuationCentersSubtitle =>
      'Tingnan at i-edit ang mga sentrong pinamamahalaan mo';

  @override
  String get staffSessionOfflineBanner =>
      'Gumagamit ng naka-save na sign-in. May mga aksyon na nangangailangan ng koneksyon.';

  @override
  String get staffFamiliesPageTitle => 'Mga Rehistradong Pamilya';

  @override
  String get staffFamiliesEmptyState => 'Wala pang nairehistrong pamilya.';

  @override
  String get staffFamiliesNoCacheMessage =>
      'Wala pang naka-save na impormasyon ng pamilya — kumonekta sa internet nang minsan para ma-load ito.';

  @override
  String get staffFamiliesLoadError =>
      'Hindi ma-load ang mga rehistradong pamilya.';

  @override
  String staffFamiliesShowingAsOf(String date) {
    return 'Ipinapakita ang datos noong $date';
  }

  @override
  String get staffFamiliesShowingSaved => 'Ipinapakita ang naka-save na datos';

  @override
  String get staffFamiliesUnknownBarangay => 'Hindi kilalang barangay';

  @override
  String get staffFamiliesUnnamedFamily => 'Walang pangalang pamilya';

  @override
  String staffFamiliesMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count na miyembro',
      one: '1 miyembro',
    );
    return '$_temp0';
  }

  @override
  String staffFamiliesRegisteredIn(String barangay) {
    return 'Nakarehistro sa $barangay';
  }

  @override
  String get staffFamiliesMembersSectionTitle => 'Mga Miyembro';

  @override
  String get staffSyncStoppedForAuthMessage =>
      'Nag-expire ang iyong sesyon. Mag-sign in muli para magpatuloy ang pag-sync.';

  @override
  String get staffSyncRequiresConnectionMessage =>
      'Kailangan ng internet connection para mag-sync.';

  @override
  String staffSyncCompletedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rehistrasyon ang na-sync.',
      one: '1 rehistrasyon ang na-sync.',
      zero: 'Walang na-sync na rehistrasyon.',
    );
    return '$_temp0';
  }

  @override
  String get staffPendingListEmpty =>
      'Walang naghihintay na rehistrasyon. Naka-sync na ang lahat.';

  @override
  String get staffPendingListError =>
      'Hindi na-load ang mga naghihintay na rehistrasyon.';

  @override
  String get staffPendingNoHeadName => 'Walang itinakdang puno ng pamilya';

  @override
  String staffPendingSubtitle(int count, String barangay, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miyembro',
      one: '1 miyembro',
    );
    return '$_temp0 • $barangay • $date';
  }

  @override
  String get staffStatusPending => 'Naghihintay';

  @override
  String get staffStatusSyncing => 'Nagsi-sync';

  @override
  String get staffStatusNeedsAttention => 'Kailangan ng Aksyon';

  @override
  String get staffRegDiscardDialogTitle => 'Itapon ang mga pagbabago?';

  @override
  String get staffRegDiscardDialogBody =>
      'May mga hindi pa na-save na pagbabago sa rehistrasyong ito. Kung aalis ka ngayon, mawawala ang mga ito.';

  @override
  String get staffRegDiscardDialogConfirm => 'Itapon';

  @override
  String get staffRegExactlyOneHeadError =>
      'Pumili ng eksaktong isang miyembro ng pamilya bilang puno ng pamilya.';

  @override
  String get staffRegValidationBanner =>
      'Suriin ang mga naka-highlight na field at subukan muli.';

  @override
  String get staffRegSavedOfflineMessage =>
      'Na-save offline. Awtomatiko itong magsi-sync kapag online ka na muli.';

  @override
  String get staffRegSuccessMessage => 'Matagumpay na narehistro ang pamilya.';

  @override
  String get staffRegAmbiguousMessage =>
      'Naputol ang koneksyon habang nagsu-submit. Na-save sa Pending Registrations para ma-kumpirma mo bago i-resubmit.';

  @override
  String get staffRegisterFamilyTitle => 'Magrehistro ng Pamilya';

  @override
  String get staffRegEditRegistrationTitle => 'Suriin ang Rehistrasyon';

  @override
  String get staffRegLookupUnavailable =>
      'Hindi available offline. Kumonekta para i-load ang listahang ito.';

  @override
  String get staffReg4psBeneficiaryLabel => 'Pamilyang 4Ps beneficiary';

  @override
  String get staffRegMembersSectionTitle => 'Mga Miyembro ng Pamilya';

  @override
  String get staffRegAddMemberButton => 'Magdagdag ng Miyembro';

  @override
  String get staffRegSubmitButton => 'I-submit ang Rehistrasyon';

  @override
  String get staffRegFieldBarangay => 'Barangay';

  @override
  String get staffRegFieldHomeAddress => 'Address sa Kalye / Sitio';

  @override
  String get staffRegFieldHomeAddressHint => 'hal. Purok 3, Sitio Mabuhay';

  @override
  String get staffRegFieldEvacuationEvent => 'Evacuation Event';

  @override
  String get staffRegFieldDisplacementType => 'Uri ng Paglikas';

  @override
  String get staffRegDisplacementInsideCenter =>
      'Nasa loob ng evacuation center';

  @override
  String get staffRegDisplacementOutsideCenter =>
      'Nasa labas ng evacuation center';

  @override
  String get staffRegFieldEvacuationCenter => 'Evacuation Center';

  @override
  String staffRegMemberCardTitle(int number) {
    return 'Miyembro $number';
  }

  @override
  String get staffRegHeadOfFamilyBadge => 'Puno ng Pamilya';

  @override
  String get staffRegSetAsHead => 'Itakda bilang puno';

  @override
  String get staffRegRemoveMember => 'Alisin ang miyembro';

  @override
  String get staffRegFieldFirstName => 'Pangalan';

  @override
  String get staffRegFieldMiddleName => 'Gitnang Pangalan';

  @override
  String get staffRegFieldLastName => 'Apelyido';

  @override
  String get staffRegFieldSuffix => 'Suffix';

  @override
  String get staffRegFieldSex => 'Kasarian';

  @override
  String get staffRegSexMale => 'Lalaki';

  @override
  String get staffRegSexFemale => 'Babae';

  @override
  String get staffRegFieldDateOfBirth => 'Petsa ng Kapanganakan';

  @override
  String get staffRegSelectDate => 'Pumili ng petsa';

  @override
  String get staffRegFieldCivilStatus => 'Katayuang Sibil';

  @override
  String get staffRegNotSpecified => 'Hindi tinukoy';

  @override
  String get staffRegCivilStatusSingle => 'Single';

  @override
  String get staffRegCivilStatusMarried => 'Kasal';

  @override
  String get staffRegCivilStatusWidowed => 'Balo';

  @override
  String get staffRegCivilStatusSeparated => 'Hiwalay';

  @override
  String get staffRegCivilStatusDivorced => 'Diborsiyado';

  @override
  String get staffRegFieldContactNumber => 'Numero ng Contact';

  @override
  String get staffRegContactRequired => 'Kailangan ang numero ng contact.';

  @override
  String get staffRegContactInvalid =>
      'Maglagay ng wastong Philippine mobile number (09XXXXXXXXX o +639XXXXXXXXX).';

  @override
  String get staffRegSameAsHead => 'Kapareho ng puno ng pamilya';

  @override
  String get staffRegHeadContactMissing =>
      'Ilagay muna ang numero ng contact ng puno ng pamilya.';

  @override
  String get staffRegPossibleDuplicateTitle => 'Posibleng katulad na rekord';

  @override
  String get staffRegViewRecord => 'Tingnan ang rekord';

  @override
  String get staffRegIsPwd => 'PWD';

  @override
  String get staffRegIsPregnant => 'Buntis';

  @override
  String get staffRegIsLactating => 'Nagpapasuso';

  @override
  String get staffRegIsSoloParent => 'Solo Parent';

  @override
  String get staffRegIsIndigenous => 'Katutubo';

  @override
  String get staffRegIs4psMember => '4Ps Beneficiary';

  @override
  String get staffRegFieldPwdType => 'Uri ng Kapansanan';

  @override
  String get staffLoginOfflineTitle =>
      'Offline ka. Kumonekta para mag-sign in.';

  @override
  String get staffLoginTitle => 'Staff Sign In';

  @override
  String get staffLoginEmailLabel => 'Email';

  @override
  String get staffLoginPasswordLabel => 'Password';

  @override
  String get staffLoginButton => 'Mag-sign In';

  @override
  String get staffPendingDetailTitle => 'Detalye ng Rehistrasyon';

  @override
  String get staffPendingDetailNotFound =>
      'Wala na ang rehistrasyong ito sa queue. Maaaring na-sync na ito.';

  @override
  String get staffPendingDetailLoadError =>
      'Hindi na-load ang rehistrasyong ito.';

  @override
  String get staffPendingDetailSummarySectionTitle => 'Buod';

  @override
  String get staffPendingDetailErrorSectionTitle => 'Kailangan ng Aksyon';

  @override
  String get staffPendingDetailFieldErrorsTitle => 'Mga field na dapat suriin';

  @override
  String staffPendingDetailAttemptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pagsubok',
      one: '1 pagsubok',
    );
    return '$_temp0';
  }

  @override
  String staffPendingDetailLastAttempt(String date) {
    return 'Huling pagsubok: $date';
  }

  @override
  String staffPendingDetailCreatedAt(String date) {
    return 'Ginawa noong $date';
  }

  @override
  String staffPendingDetailUpdatedAt(String date) {
    return 'Na-update noong $date';
  }

  @override
  String get staffPendingErrorCategoryValidation =>
      'Kailangan ng pagwawasto bago i-resubmit';

  @override
  String get staffPendingErrorCategoryForbidden =>
      'Hindi pinahihintulutan para sa iyong account';

  @override
  String get staffPendingErrorCategoryAmbiguous => 'Hindi tiyak ang resulta';

  @override
  String get staffPendingErrorCategoryServer => 'Error sa server';

  @override
  String get staffPendingAmbiguousHint =>
      'Posibleng natanggap na ng server ang rehistrasyong ito bago naputol ang koneksyon. Kumpirmahin munang hindi pa naka-rehistro ang pamilya bago i-resubmit, para maiwasan ang duplicate.';

  @override
  String get staffPendingDetailReviewButton => 'Suriin at I-resubmit';

  @override
  String get staffPendingDetailEditButton => 'I-edit';

  @override
  String get staffPendingDetailDeleteButton => 'Tanggalin';

  @override
  String get staffPendingDetailDeleteDialogTitle =>
      'Tanggalin ang rehistrasyong ito?';

  @override
  String get staffPendingDetailDeleteDialogBody =>
      'Permanente itong aalisin sa offline queue. Hindi na ito mababawi.';

  @override
  String get staffPendingDetailSyncingNotice =>
      'Kasalukuyang nagsi-sync ang rehistrasyong ito. Mangyaring maghintay.';

  @override
  String get staffPendingDetailDeletedMessage =>
      'Naalis ang rehistrasyon sa queue.';

  @override
  String get ecBoardTitle => 'EC Information Board';

  @override
  String get ecBoardWorkspaceActionSubtitle =>
      'Magdagdag ng mga evacuee at tingnan ang breakdown ng edad/kasarian para sa isang center';

  @override
  String get ecBoardAddEvacueeTitle => 'Magdagdag ng Evacuee';

  @override
  String get ecBoardEditEvacueeTitle => 'I-edit ang Entry ng Evacuee';

  @override
  String get ecBoardEntryDetailTitle => 'Entry ng Evacuee';

  @override
  String get ecBoardFieldSex => 'Kasarian';

  @override
  String get ecBoardFieldAgeBracket => 'Age Bracket';

  @override
  String get ecBoardFieldHousehold => 'Sambahayan';

  @override
  String get ecBoardHouseholdExisting => 'Umiiral na sambahayan';

  @override
  String get ecBoardHouseholdNew => 'Bagong sambahayan';

  @override
  String get ecBoardSelectHouseholdButton => 'Pumili ng sambahayan';

  @override
  String get ecBoardHouseholdSearchHint =>
      'Maghanap gamit ang pangalan ng puno ng pamilya';

  @override
  String get ecBoardRefreshHouseholdsTooltip =>
      'I-refresh ang listahan ng sambahayan';

  @override
  String get ecBoardHouseholdsUpToDate => 'Napapanahon';

  @override
  String get ecBoardPendingHouseholdBadge => 'Nakabinbin — hindi pa naka-sync';

  @override
  String get ecBoardPendingNewHouseholdBadge =>
      'Bagong sambahayan mula sa device na ito — hindi pa naka-sync';

  @override
  String get ecBoardPendingHouseholdNotice =>
      'Hindi pa naka-sync ang sambahayang ito. Awtomatikong maki-sync ang entry na ito kapag na-sync na ito.';

  @override
  String get ecBoardNewHouseholdHeadName => 'Pangalan ng Puno ng Sambahayan';

  @override
  String get ecBoardSubmitButton => 'I-save ang Evacuee';

  @override
  String get ecBoardValidationBanner =>
      'Pakikumpleto ang kasarian, age bracket, at sambahayan bago i-save.';

  @override
  String get ecBoardSavedOfflineMessage =>
      'Na-save offline. Mag-si-sync ito kapag online ka na.';

  @override
  String get ecBoardSavedPendingHouseholdMessage =>
      'Na-save — hinihintay munang maki-sync ang piniling sambahayan.';

  @override
  String get ecBoardSuccessMessage => 'Matagumpay na naidagdag ang evacuee.';

  @override
  String get ecBoardNoEventsAvailable =>
      'Wala pang available na evacuation event.';

  @override
  String get ecBoardAgeSexSectionTitle => 'Edad at Kasarian (Age & Sex)';

  @override
  String get ecBoardSectoralSectionTitle => 'Sectoral Group';

  @override
  String get ecBoardPendingSectoralEmptyState =>
      'Walang nakabinbing update sa sectoral sa device na ito.';

  @override
  String get ecBoardLastKnownSectionTitle => 'Huling Kilalang Breakdown';

  @override
  String get ecBoardLastKnownSectionSubtitle =>
      'Live na bilang ng mga evacuee na nakumpirma na sa server.';

  @override
  String get ecBoardLastKnownUnavailable =>
      'Hindi na-load ang huling kilalang breakdown.';

  @override
  String get ecBoardLastKnownEmpty =>
      'Wala pang naitalang evacuee para sa center at event na ito.';

  @override
  String get ecBoardLastKnownFromCacheNotice =>
      'Offline — ipinapakita ang huling nakumpirmang bilang na naka-save sa device na ito.';

  @override
  String get ecBoardUnclassifiedLabel => 'Hindi Naklasipika';

  @override
  String get ecBoardPendingSectionTitle =>
      'Mga Nakabinbing Entry ng Device na Ito';

  @override
  String get ecBoardPendingSectionSubtitle =>
      'Hindi pa naka-sync — hiwalay sa nakumpirmang bilang sa itaas.';

  @override
  String get ecBoardSyncNowInlineButton => 'I-sync Ngayon';

  @override
  String get ecBoardPendingListEmpty =>
      'Walang nakabinbing entry sa device na ito.';

  @override
  String get ecBoardTotalLabel => 'Kabuuan';

  @override
  String ecBoardMaleFemaleCount(int male, int female) {
    return '${male}L / ${female}B';
  }

  @override
  String get ecBoardBracketInfant => 'Sanggol (0-6 buwan)';

  @override
  String get ecBoardBracketToddler => 'Toddler (7-24 buwan)';

  @override
  String get ecBoardBracketPreschooler => 'Preschooler';

  @override
  String get ecBoardBracketSchoolAge => 'Edad-Paaralan';

  @override
  String get ecBoardBracketTeenage => 'Tin-edyer';

  @override
  String get ecBoardBracketAdult => 'Nasa Hustong Gulang';

  @override
  String get ecBoardBracketSeniorCitizen => 'Senior Citizen';

  @override
  String get ecBoardSectoralGroupsSectionTitle => 'Mga Sektoral na Grupo';

  @override
  String get ecBoardSectoralGroupsSectionSubtitle =>
      'Mga kabuuang iniulat ng staff, hiwalay na ipinasok mula sa Add Evacuee.';

  @override
  String get ecBoardSectoralPwd => 'Taong May Kapansanan (PWD)';

  @override
  String get ecBoardSectoralChildHeadedFamily =>
      'Pamilyang Pinamumunuan ng Bata';

  @override
  String get ecBoardSectoralSingleHeadedFamily => 'Pamilyang Iisa ang Puno';

  @override
  String get ecBoardSectoralSoloParent => 'Solo Parent';

  @override
  String get ecBoardSectoralPregnantWomen => 'Buntis na Kababaihan';

  @override
  String get ecBoardSectoralLactatingMothers => 'Nagpapasusong Ina';

  @override
  String get ecBoardSectoralFourPsBeneficiary => '4Ps Beneficiary';

  @override
  String get ecBoardSectoralIndigenousPeoples => 'Katutubong Mamamayan';

  @override
  String get ecBoardSyncNowExplanation =>
      'Ang I-sync Ngayon ay nagpapadala ng iyong mga offline entry (bagong evacuee, sectoral update) sa server.';

  @override
  String get ecBoardSectoralEditButton => 'I-edit ang Sectoral at 4Ps';

  @override
  String get ecBoardFamiliesLabel => 'Pamilya';

  @override
  String get ecBoardPersonsLabel => 'Tao';

  @override
  String get ecBoardNowLabel => 'ngayon';

  @override
  String ecBoardCumulativeValue(int count) {
    return '$count kumulatibo';
  }

  @override
  String get ecBoardFourPsBeneficiaryFamilies =>
      '4Ps Beneficiary na mga Pamilya';

  @override
  String ecBoardSectoralUpdatedBy(String name) {
    return 'Huling in-update ni $name';
  }

  @override
  String get ecBoardPendingSectoralCardTitle => 'Nakabinbin na sectoral update';

  @override
  String get ecBoardPendingSectoralCardSubtitle =>
      'Hindi pa naka-sync — i-tap para suriin o i-edit.';

  @override
  String get ecBoardSectoralFormTitle => 'Ulat ng Sectoral at 4Ps';

  @override
  String get ecBoardSectoralFormSubtitle =>
      'Manu-manong naiuulat na kabuuan para sa center at event na ito — hiwalay sa Add Evacuee.';

  @override
  String get ecBoardSectoralFormFieldsHint =>
      'Ilagay ang bilang ng tao sa bawat kategorya.';

  @override
  String get ecBoardSectoralSaveButton => 'I-save ang Sectoral at 4Ps';

  @override
  String get ecBoardSectoralSavedOfflineMessage =>
      'Na-save offline. Mag-si-sync ito kapag online ka na.';

  @override
  String get ecBoardSectoralSuccessMessage =>
      'Matagumpay na na-update ang ulat ng Sectoral at 4Ps.';

  @override
  String get ecBoardQuickDepartureTitle => 'Quick Departure';

  @override
  String get ecBoardQuickDepartureSubtitle =>
      'Markahan ang mga taong umalis sa center na ito, ayon sa age bracket, kasarian, at bilang.';

  @override
  String get ecBoardQuickDepartureQuantity => 'Bilang';

  @override
  String get ecBoardQuickDepartureStatus => 'Katayuan';

  @override
  String get ecBoardQuickDepartureReturnedHome => 'Umuwi na';

  @override
  String get ecBoardQuickDepartureTransferred => 'Nailipat';

  @override
  String get ecBoardQuickDepartureSubmitButton => 'Markahan bilang Umalis';

  @override
  String get ecBoardQuickDepartureValidationBanner =>
      'Piliin ang kasarian, age bracket, bilang, at katayuan.';

  @override
  String get ecBoardQuickDepartureSuccessMessage => 'Naitala bilang umalis.';

  @override
  String get ecBoardQuickDepartureOfflineMessage =>
      'Kailangan ng internet connection para sa Quick Departure.';

  @override
  String get ecBoardQuickDepartureOfflineExplanation =>
      'Kailangan ng internet connection ang Quick Departure dahil kailangan nitong tingnan kung sino ang kasalukuyang nakumpirma sa center na ito.';
}
