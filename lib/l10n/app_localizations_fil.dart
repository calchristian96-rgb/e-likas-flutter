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
  String get hazardOverlaysSectionTitle => 'Panganib sa Hazard (MGB)';

  @override
  String get hazardOverlayFloodName => 'Panganib sa baha';

  @override
  String get hazardOverlayLandslideName =>
      'Panganib sa landslide dulot ng ulan';

  @override
  String get hazardOverlaysOnlineNotice =>
      'Kailangan ng internet connection ang mga layer na ito — hindi sila naka-save para sa offline na paggamit.';

  @override
  String get hazardOverlayFloodNote =>
      'Panganib sa baha: Mines and Geosciences Bureau via GeoRiskPH (ayon sa service: noong Hulyo 2018). Antas ng panganib ito, hindi hula sa baha.';

  @override
  String get hazardOverlayLandslideNote =>
      'Landslide dulot ng ulan lamang: Mines and Geosciences Bureau via GeoRiskPH (ayon sa service: may petsang 2012). Antas ng panganib ito, hindi hula sa landslide. Hindi kasama sa mapa ang lahar.';

  @override
  String hazardOverlayLoadFailed(String layer) {
    return 'Hindi ma-load ang $layer mula sa GeoRiskPH sa ngayon. I-off at i-on ito para subukan muli.';
  }

  @override
  String get hazardOverlayAttribution => 'MGB via GeoRiskPH';

  @override
  String get updateAvailableTitle => 'May bagong update';

  @override
  String get updateRequiredTitle => 'Kailangan ng update';

  @override
  String updateVersionReady(String version) {
    return 'Handa na ang bersyon $version';
  }

  @override
  String get updateRequiredBody =>
      'Luma na ang bersyong ito ng E-LIKAS. Paki-update para manatiling tama ang inyong mga alerto at impormasyon sa evacuation.';

  @override
  String updateSizeWifi(String size) {
    return '$size MB · Mas mainam ang Wi-Fi';
  }

  @override
  String get updateWifiRecommended => 'Mas mainam ang Wi-Fi';

  @override
  String get updateWhatsNew => 'Ano ang bago';

  @override
  String get updateLater => 'Mamaya';

  @override
  String get updateNow => 'I-update na';

  @override
  String get updateDownloading => 'Dina-download ang update…';

  @override
  String get updateVerifying => 'Sinusuri ang na-download…';

  @override
  String get updateReadyToInstall =>
      'Na-verify ang download. Binubuksan ang installer…';

  @override
  String get updateInstallHint =>
      'Kung hihingin ng Android na payagan ang pag-install mula sa E-LIKAS, i-on ito, bumalik, at pindutin ang Install.';

  @override
  String get updateInstall => 'I-install';

  @override
  String get updateCancel => 'Kanselahin';

  @override
  String get updateFailedTitle => 'Hindi nagtagumpay ang update';

  @override
  String get updateFailedBody =>
      'Hindi ma-download ang update o hindi ito pumasa sa safety check. Tingnan ang inyong koneksyon at subukan muli.';

  @override
  String get updateTryAgain => 'Subukan muli';

  @override
  String get updateOpenInBrowser => 'Buksan sa browser';

  @override
  String get settingsCheckForUpdates => 'Tingnan kung may update';

  @override
  String settingsVersionBuild(String version, String build) {
    return 'Bersyon $version (build $build)';
  }

  @override
  String get updateChecking => 'Sinusuri…';

  @override
  String get updateUpToDate => 'Napapanahon na ang E-LIKAS.';

  @override
  String get updateCheckFailed => 'Hindi masuri ang mga update sa ngayon.';

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
  String get staffWorkspaceAllEvacuees => 'Mga Evacuee';

  @override
  String get staffWorkspaceAllEvacueesSubtitle =>
      'Mga naka-sync na pamilya sa inyong lugar';

  @override
  String get registeredFamiliesTitle => 'Mga Rehistradong Pamilya';

  @override
  String get registeredFamiliesWorkspaceSubtitle =>
      'Mga talaang naka-save sa device na ito — naka-sync man o hindi';

  @override
  String get registeredFamiliesSubtitle =>
      'Lahat ng talaan ng pamilya na naka-save sa device na ito, mula sa kahit anong barangay. Dito lang lumalabas ang mga talaan mula sa ibang barangay — ang Mga Evacuee ay para sa naka-sync na talaan ng sarili mong barangay.';

  @override
  String get registeredFamiliesNotSyncedSection => 'Hindi pa naka-sync';

  @override
  String get registeredFamiliesSyncedSection => 'Naka-sync';

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
  String get ecBoardFieldAgeBracket => 'Age group';

  @override
  String get ecBoardFieldHousehold => 'Pamilya';

  @override
  String get ecBoardHouseholdExisting => 'Narito na';

  @override
  String get ecBoardHouseholdNew => 'Bagong pamilya';

  @override
  String get ecBoardSelectHouseholdButton => 'Pumili ng pamilya';

  @override
  String get ecBoardHouseholdSearchHint =>
      'Maghanap gamit ang pangalan ng puno ng pamilya';

  @override
  String get ecBoardRefreshHouseholdsTooltip =>
      'I-refresh ang listahan ng pamilya';

  @override
  String get ecBoardHouseholdsUpToDate => 'Napapanahon';

  @override
  String get ecBoardPendingHouseholdBadge => 'Nakabinbin — hindi pa naka-sync';

  @override
  String get ecBoardPendingNewHouseholdBadge =>
      'Bagong pamilya mula sa device na ito — hindi pa naka-sync';

  @override
  String get ecBoardPendingHouseholdNotice =>
      'Hindi pa naka-sync ang pamilyang ito. Awtomatikong maki-sync ang entry na ito kapag na-sync na ito.';

  @override
  String get ecBoardNewHouseholdHeadName => 'Pangalan ng pamilya';

  @override
  String get ecBoardSubmitButton => 'I-save ang Evacuee';

  @override
  String get ecBoardValidationBanner =>
      'Pakikumpleto ang kasarian, age group, at pamilya bago i-save.';

  @override
  String get ecBoardSavedOfflineMessage =>
      'Na-save offline. Mag-si-sync ito kapag online ka na.';

  @override
  String get ecBoardSavedPendingHouseholdMessage =>
      'Na-save — hinihintay munang maki-sync ang piniling pamilya.';

  @override
  String get ecBoardSuccessMessage => 'Matagumpay na naidagdag ang evacuee.';

  @override
  String get ecBoardNoEventsAvailable =>
      'Wala pang bukas na event. Nagbubukas ang CSWDO ng event kapag may ibinabalang banta.';

  @override
  String get ecBoardAgeSexSectionTitle => 'Edad at Kasarian (Age & Sex)';

  @override
  String get ecBoardSectoralSectionTitle => 'Sectoral Group';

  @override
  String get ecBoardLastKnownFromCacheNotice =>
      'Offline — ipinapakita ang huling nakumpirmang bilang na naka-save sa device na ito.';

  @override
  String get ecBoardUnclassifiedLabel => 'Hindi pa naka-uri';

  @override
  String get ecBoardPendingSectionTitle => 'Idinagdag sa device na ito';

  @override
  String get ecBoardPendingSectionSubtitle =>
      'Hindi pa naka-sync, kaya dito lang ipinapakita — hindi kailanman idinadagdag sa mga numero ng board. Ipapadala ang mga ito ng I-sync Ngayon, kasama ang kanilang sectoral na detalye at mga sagot tungkol sa pamilya.';

  @override
  String get ecBoardSyncNowInlineButton => 'I-sync Ngayon';

  @override
  String get ecBoardPendingListEmpty =>
      'Walang nakabinbing entry sa device na ito.';

  @override
  String get ecBoardTotalLabel => 'Kabuuan';

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
  String get ecBoardSectoralFlagsTitle => 'Sectoral na detalye (opsyonal)';

  @override
  String get ecBoardSectoralFlagsHelp =>
      'Lagyan ng tsek lang ang alam mo. Ang walang tsek ay hindi naitala — hindi ito nangangahulugang \"hindi\".';

  @override
  String ecBoardSectoralFlagsTicked(int count) {
    return '$count ang may tsek';
  }

  @override
  String get ecBoardFourPsBeneficiaryFamilies =>
      '4Ps Beneficiary na mga Pamilya';

  @override
  String get ecBoardAddEvacueeIntro =>
      'Maaaring idagdag ang pangalan at kaarawan sa ibang pagkakataon sa Evacuees page ng web dashboard.';

  @override
  String get ecBoardSectionWhoIsThisPerson => 'Sino ang taong ito?';

  @override
  String get ecBoardHeadNote =>
      'Gagamitin ang edad at kasarian ng taong ito para sa puno ng pamilya.';

  @override
  String get ecBoardThisPersonIsHead => 'Ang taong ito ang puno ng pamilya';

  @override
  String get ecBoardNoHeadLinkedYet =>
      'Wala pang naka-link na puno ang pamilyang ito.';

  @override
  String get ecBoardSingleHeadedQuestion =>
      'Iisa lang ba ang puno ng pamilya? (single-headed)';

  @override
  String get ecBoardAnswerNotYetKnown => 'Hindi pa alam';

  @override
  String get ecBoardAnswerYes => 'Oo';

  @override
  String get ecBoardAnswerNo => 'Hindi';

  @override
  String get ecBoardAnswerYesUnder18 => 'Oo (wala pang 18)';

  @override
  String get ecBoardHeadSectionTitle => 'Tungkol sa tunay na puno ng pamilya';

  @override
  String get ecBoardHeadSectionSubtitle =>
      'Ibang tao sa idinaragdag mo. Gagamitin hanggang maidagdag at ma-link sila.';

  @override
  String get ecBoardHeadSexLabel => 'Kasarian ng puno';

  @override
  String get ecBoardHeadIsMinorLabel => 'Menor de edad ba ang puno?';

  @override
  String get ecBoardWillBeRecordedTitle => 'Itatala';

  @override
  String ecBoardSummaryAdding(String sex, String ageGroup) {
    return 'Magdaragdag ng 1 $sex, $ageGroup.';
  }

  @override
  String get ecBoardSummaryChooseAgeSex =>
      'Piliin ang age group at kasarian ng taong ito.';

  @override
  String ecBoardSummaryJoinsHousehold(String household) {
    return 'Sasali sa pamilyang narito na: $household.';
  }

  @override
  String get ecBoardSummaryChooseHousehold =>
      'Piliin ang pamilya ng taong ito.';

  @override
  String ecBoardSummaryBecomesHead(String minor) {
    return 'Magiging puno ng pamilyang iyon ($minor).';
  }

  @override
  String ecBoardSummaryNewHousehold(String name, String barangay) {
    return 'Bagong pamilya: $name, $barangay.';
  }

  @override
  String get ecBoardSummaryNoHeadName => '(wala pang pangalan ng pamilya)';

  @override
  String get ecBoardSummaryNoBarangay =>
      '(hindi pa napipili ang barangay na tinitirhan)';

  @override
  String get ecBoardHomeBarangayLabel => 'Barangay na tinitirhan';

  @override
  String get ecBoardHomeBarangayHint =>
      'Piliin ang barangay na tinitirhan ng pamilya...';

  @override
  String get ecBoardHomeBarangayHelp =>
      'Kung saan nakatira ang pamilya -- hindi kailangang kung saan ang center na ito.';

  @override
  String ecBoardHomeBarangaySameAsCenter(String barangay) {
    return 'Kapareho ng center na ito ($barangay)';
  }

  @override
  String get ecBoardHomeBarangayRequired =>
      'Piliin ang barangay na tinitirhan ng pamilya.';

  @override
  String ecBoardFamilyHereGeneric(int id, String barangay, int count) {
    return 'Pamilya #$id · $barangay · $count narito';
  }

  @override
  String ecBoardFamilyNumber(int id) {
    return 'Pamilya #$id';
  }

  @override
  String get ecBoardNoFamiliesHere => 'Walang pamilya rito sa ngayon.';

  @override
  String get ecBoardFamiliesHereOffline =>
      'Offline: ipinapakita ang mga pamilyang naka-save sa teleponong ito. Ang pamilyang umalis na sa center na ito ay tatanggihan pagka-sync.';

  @override
  String ecBoardOtherBarangayNote(String barangay) {
    return 'Nasa $barangay ang center na ito. Idagdag lamang ang mga taong nananatili sa center na ito.';
  }

  @override
  String ecBoardEventClosedName(String name) {
    return '$name (sarado)';
  }

  @override
  String get ecBoardClosedEventNote =>
      'Sarado na ang event na ito. Hindi na maaaring magdagdag ng evacuee rito.';

  @override
  String get ecBoardClosedEventWaitingNote =>
      'Hindi na maisi-sync ang mga entry na naghihintay pa sa teleponong ito para rito. Suriin ang mga ito, saka burahin sa teleponong ito.';

  @override
  String ecBoardSummaryHeadIsThisPerson(String minor) {
    return 'Puno: ang taong ito ($minor).';
  }

  @override
  String ecBoardSummaryHeadIsSomeoneElse(String sex, String minor) {
    return 'Puno: ibang tao, $sex, $minor.';
  }

  @override
  String get ecBoardSummarySexNotYetKnown => 'hindi pa alam ang kasarian';

  @override
  String get ecBoardSummaryMinorUnknown =>
      'menor de edad o hindi: hindi pa alam';

  @override
  String get ecBoardSummaryMinor => 'menor de edad';

  @override
  String get ecBoardSummaryNotMinor => 'hindi menor de edad';

  @override
  String ecBoardSummarySingleHeaded(String answer) {
    return 'Single-headed: $answer.';
  }

  @override
  String get ecBoardSummaryAnswerUnknown => 'hindi pa alam';

  @override
  String get ecBoardSummaryAnswerYes => 'oo';

  @override
  String get ecBoardSummaryAnswerNo => 'hindi';

  @override
  String get ecBoardSummaryMale => 'lalaki';

  @override
  String get ecBoardSummaryFemale => 'babae';

  @override
  String ecBoardSummarySectoral(String flags) {
    return 'Sectoral: $flags.';
  }

  @override
  String get ecBoardSummaryNoSectoral => 'Walang sectoral na detalye.';

  @override
  String get ecBoardSectoralLiveExplanation =>
      'Binibilang mula sa sectoral na detalye ng bawat evacuee. Ang child- at single-headed na pamilya ay binibilang nang isang beses bawat pamilya, ayon sa kasarian ng puno, mula sa mga sagot noong idinagdag ang pamilya.';

  @override
  String familyMemberDetailsPending(int index) {
    return 'Miyembro $index — kulang pa ang detalye';
  }

  @override
  String familyMemberCheckedInAt(String center) {
    return 'Naka-check in sa $center';
  }

  @override
  String get familyMemberCheckedInUnspecified =>
      'Naka-check in sa hindi tukoy na lugar';

  @override
  String get familyMemberCheckedOut => 'Naka-check out na';

  @override
  String get familyMembersNeedConnection =>
      'Kumonekta sa internet para makita kung sino pa ang naka-check in at para mag-check out ng isang tao.';

  @override
  String familyHeadNotLinked(String answers) {
    return 'Wala pang naka-link na puno. Ginagamit ng bilang ang mga sagot para sa puno ($answers) hanggang may ma-link na miyembro. Pagdating ng puno, idagdag sila sa Add Evacuee → Narito na at i-tsek ang \"Ang taong ito ang puno ng pamilya\".';
  }

  @override
  String get familyHeadNotLinkedNothingKnown =>
      'Wala pang naka-link na puno. Wala pang alam tungkol sa puno hanggang may ma-link na miyembro. Pagdating ng puno, idagdag sila sa Add Evacuee → Narito na at i-tsek ang \"Ang taong ito ang puno ng pamilya\".';

  @override
  String get familyLegacyBulkEntryNotice =>
      'Lumang bulk entry — kailangang suriin nang mano-mano. Mga hindi kilalang tao mula sa lumang headcount, hindi tunay na pamilya.';

  @override
  String get checkOutButton => 'Check out';

  @override
  String checkOutDialogTitle(String name) {
    return 'I-check out si $name';
  }

  @override
  String checkOutDialogSubtitle(String center) {
    return 'Isasara ang kanilang pananatili sa $center, kaya hindi na sila bibilangin bilang narito ngayon.';
  }

  @override
  String get checkOutTheirCurrentLocation => 'kanilang kasalukuyang lugar';

  @override
  String get checkOutReasonLabel => 'Dahilan';

  @override
  String get checkOutReturnedHome => 'Umuwi na';

  @override
  String get checkOutTransferred => 'Lumipat sa ibang lugar';

  @override
  String get checkOutReturnedHomeLower => 'umuwi na';

  @override
  String get checkOutTransferredLower => 'lumipat sa ibang lugar';

  @override
  String checkOutConfirm(String name, String reason) {
    return 'I-check out si $name bilang $reason? Hindi na sila bibilangin bilang narito ngayon.';
  }

  @override
  String checkOutMemberPendingName(int index) {
    return 'Miyembro $index (kulang pa ang detalye)';
  }

  @override
  String checkOutSucceeded(String name) {
    return 'Na-check out na si $name.';
  }

  @override
  String get checkOutOther => 'Iba pa';

  @override
  String get checkOutOtherLower => 'umalis dahil sa ibang dahilan';

  @override
  String get markFamilyDepartedButton => 'Markahang umalis ang pamilya';

  @override
  String get markFamilyDepartedSubtitle =>
      'Iche-check out ang lahat ng naka-tsek, iisang dahilan para sa lahat. Hindi na nakalista ang mga naka-check out na.';

  @override
  String get markFamilyDepartedWho => 'Sino ang aalis';

  @override
  String get markFamilyDepartedReasonHelp =>
      'Para sa lahat ng naka-tsek sa itaas.';

  @override
  String markFamilyDepartedSubmit(int count) {
    return 'Markahang umalis ang $count';
  }

  @override
  String markFamilyDepartedConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Markahang umalis ang $count miyembro?',
      one: 'Markahang umalis ang 1 miyembro?',
    );
    return '$_temp0';
  }

  @override
  String markFamilyDepartedConfirmMessage(String reason) {
    return 'Itatala sila bilang $reason at hindi na bibilangin bilang narito ngayon.';
  }

  @override
  String get markFamilyDepartedConfirmButton => 'Markahang umalis';

  @override
  String get markFamilyDepartedWorking => 'Minamarkahan…';

  @override
  String markFamilyDepartedDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Namarkahang umalis ang $count miyembro.',
      one: 'Namarkahang umalis ang 1 miyembro.',
    );
    return '$_temp0';
  }

  @override
  String markFamilyDepartedPartialTitle(int done, int total) {
    return '$done sa $total ang namarkahang umalis';
  }

  @override
  String get markFamilyDepartedPartialBody => 'Hindi na-check out ang mga ito:';

  @override
  String get ecBoardHeaderCenter => 'Evacuation center';

  @override
  String get ecBoardAsOf => 'Hanggang';

  @override
  String get ecBoardAsOfNotYetFetched => 'Hindi pa nakukuha';

  @override
  String get ecBoardNotYetFetchedHelp =>
      'Hindi pa naida-download ang board na ito sa device na ito, kaya gitling ang bawat numero. Kumonekta sa internet at subukan ulit.';

  @override
  String get ecBoardHeaderFamilies => 'Pamilya (Cum/Now)';

  @override
  String get ecBoardHeaderPersons => 'Tao (Cum/Now)';

  @override
  String get staffUseTheWebTitle => 'Gamitin ang website';

  @override
  String get staffUseTheWebBody =>
      'Ang mga administrator account ay namamahala ng users, logs at backups sa E-LIKAS website. Ang mobile app ay para sa field work ng barangay at monitoring ng CSWD.';

  @override
  String get staffOpenWebsite => 'Buksan ang E-LIKAS website';

  @override
  String get staffSignOut => 'Mag-sign out';

  @override
  String get centerApprovalUnverified => 'Hindi pa beripikado';

  @override
  String get centerApprovalRejected => 'Tinanggihan';

  @override
  String get centerApprovalEditWaiting => 'Pagbabago na hinihintay ang CSWD';

  @override
  String get centerRejectedNotUsable =>
      'Tinanggihan ng CSWD. Hindi magagamit sa EC Board.';

  @override
  String get staffOwnCentersEmpty =>
      'Wala pang evacuation center sa inyong barangay';

  @override
  String get demoBadge => 'DEMO';

  @override
  String get drillBadge => 'DRILL';

  @override
  String get residentBarangayTitle => 'Inyong barangay';

  @override
  String get residentBarangayNotSet => 'Hindi pa napipili';

  @override
  String get residentBarangayPickerTitle => 'Piliin ang inyong barangay';

  @override
  String get residentBarangaySearchHint => 'Maghanap ng barangay';

  @override
  String get residentBarangayListUnavailable =>
      'Kailangan ng internet sa unang pagkuha ng listahan ng barangay.';

  @override
  String get residentBarangayWhy =>
      'Makita muna ang status ng inyong barangay at ang mga evacuation center nito.';

  @override
  String residentBarangayStatusOf(Object barangay) {
    return 'Brgy. $barangay';
  }

  @override
  String get residentNoOpenEvent => 'Walang bukas na sakuna.';

  @override
  String residentStatusSavedCopy(Object age) {
    return 'Naka-save na kopya, huling update $age';
  }

  @override
  String get showBarangayStatus => 'Status ng barangay';

  @override
  String get barangayBoundariesAttribution =>
      'Hangganan ng barangay: PSA-NAMRIA via HDX (CC BY-IGO)';

  @override
  String barangayStatusTapped(Object barangay, Object status) {
    return '$barangay: $status';
  }

  @override
  String get drillNotice => 'PAGSASANAY - Hindi ito totoong emergency.';

  @override
  String centersInYourBarangay(Object barangay) {
    return 'Mga center sa Brgy. $barangay';
  }

  @override
  String get centerNoMapLocationYet =>
      'Wala pang lokasyon sa mapa. Magtanong sa inyong barangay kung paano pumunta.';

  @override
  String get staffTabCenters => 'Centers';

  @override
  String get staffTabMore => 'Iba pa';

  @override
  String get staffTabResidentApp => 'Resident app';

  @override
  String get staffSignInButton => 'Staff sign in';

  @override
  String get staffModeButton => 'Staff Mode';

  @override
  String get syncTitle => 'Sync';

  @override
  String get syncNow => 'I-sync ngayon';

  @override
  String get syncAllDone => 'Naka-sync na ang lahat';

  @override
  String syncWaitingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count naghihintay ma-sync',
      one: '1 naghihintay ma-sync',
    );
    return '$_temp0';
  }

  @override
  String syncAttentionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kailangang tingnan',
      one: '1 kailangang tingnan',
    );
    return '$_temp0';
  }

  @override
  String syncSentMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count naipadala.',
      one: '1 naipadala.',
      zero: 'Walang bagong ipapadala.',
    );
    return '$_temp0';
  }

  @override
  String get syncNeedsAttention => 'Kailangang tingnan';

  @override
  String get syncWaiting => 'Naghihintay ma-sync';

  @override
  String get syncFamilyRegistrations => 'Mga rehistro ng pamilya';

  @override
  String get syncTryAgain => 'Subukang muli';

  @override
  String get syncDiscardTitle => 'Itapon ang aksyong ito?';

  @override
  String syncDiscardBody(Object summary) {
    return 'Hindi na ipapadala ang \"$summary\". Hindi na ito maibabalik.';
  }

  @override
  String get syncDiscardConfirm => 'Itapon';

  @override
  String get syncDiscarded => 'Naitapon ang aksyon';

  @override
  String get syncCouldNotRead => 'Hindi mabasa ang pila sa device na ito.';

  @override
  String get moreActions => 'Iba pang aksyon';

  @override
  String get staffSyncRow => 'Sync';

  @override
  String get purokOptionalLabel => 'Purok (opsyonal)';

  @override
  String get purokNone => 'Walang purok';

  @override
  String get ecBoardFamiliesHereTitle => 'Mga pamilyang narito ngayon';

  @override
  String get ecBoardFamiliesHereEmpty =>
      'Walang pamilyang naka-check in dito para sa event na ito.';

  @override
  String ecBoardFamilyMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miyembro',
      one: '1 miyembro',
    );
    return '$_temp0';
  }

  @override
  String showAllCount(int count) {
    return 'Ipakita lahat ($count)';
  }

  @override
  String get returningFamiliesTitle => 'Bumabalik na pamilya';

  @override
  String get returningFamiliesOfflineButton =>
      'Bumabalik na pamilya (kailangan ng internet)';

  @override
  String get returningFamiliesNeedsConnection =>
      'Kailangan ng internet para sa bumabalik na pamilya.';

  @override
  String get returningFamiliesNoPastEvents =>
      'Walang pamilya ng inyong barangay mula sa nakaraang event na maaaring ilagay dito.';

  @override
  String get returningFamiliesPastEvent => 'Nakaraang event';

  @override
  String get returningFamiliesSearchHint => 'Pangalan ng pamilya o miyembro';

  @override
  String get returningFamiliesNone => 'Walang nahanap na pamilya.';

  @override
  String get returningFamilyAlreadyIn => 'Nasa event na ito na';

  @override
  String get returningFamilyWhoArrived => 'Sino ang dumating?';

  @override
  String returningFamilyUnnamed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hindi nakalista ang $count miyembrong walang pangalan.',
      one: 'Hindi nakalista ang 1 miyembrong walang pangalan.',
    );
    return '$_temp0';
  }

  @override
  String get returningMemberCheckedIn => 'Naka-check in na sa event na ito';

  @override
  String returningMemberAge(int age) {
    String _temp0 = intl.Intl.pluralLogic(
      age,
      locale: localeName,
      other: '$age taon',
      one: '1 taon',
    );
    return '$_temp0';
  }

  @override
  String get returningMemberAgeGroup =>
      'Pangkat ng edad (walang petsa ng kapanganakan)';

  @override
  String get returningMemberStillPregnant => 'Buntis ngayon';

  @override
  String get returningMemberStillLactating => 'Nagpapasuso ngayon';

  @override
  String returningFamilyEnroll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ilagay ang $count tao',
      one: 'Ilagay ang 1 tao',
    );
    return '$_temp0';
  }

  @override
  String returningFamilyDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tao ang nailagay',
      one: '1 tao ang nailagay',
    );
    return '$_temp0';
  }

  @override
  String get returningFamilyDuplicateTitle => 'Parehong pamilya?';

  @override
  String get returningFamilyDuplicateBody =>
      'May pamilyang maaaring pareho na nasa event na ito.';

  @override
  String returningFamilyLinkTo(String name, String center, String members) {
    return 'Parehong pamilya, ikonekta: $name · $center · $members';
  }

  @override
  String get returningFamilyDifferent => 'Ibang pamilya, idagdag bilang bago';

  @override
  String get centerLocationTitle => 'Lokasyon sa mapa';

  @override
  String get centerLocationOnMap => 'Nasa mapa';

  @override
  String get centerLocationWaitingForCswd =>
      'Hinihintay ng CSWD ang lokasyong ipinadala ninyo.';

  @override
  String get centerLocationWaitingToSync =>
      'May lokasyong naka-save sa teleponong ito at ipapadala pagka-online.';

  @override
  String get centerLocationSetFromPhone =>
      'Itakda ang lokasyon mula sa teleponong ito';

  @override
  String get centerLocationConfirmTitle => 'Gamitin ang lokasyong ito?';

  @override
  String centerLocationAccuracy(int meters) {
    return 'Tumpak hanggang mga $meters m';
  }

  @override
  String get centerLocationLowAccuracy =>
      'Mababa ang katumpakan. Lumabas o maghintay sandali, saka subukang muli.';

  @override
  String get centerLocationGoesToCswd =>
      'Tumayo sa pasukan ng center. Aaprubahan ng CSWD ang lokasyon bago ito lumabas sa mapa.';

  @override
  String get centerLocationSend => 'Ipadala sa CSWD';

  @override
  String centerLocationSummary(Object center) {
    return 'Lokasyon ng $center';
  }

  @override
  String get centerLocationQueued =>
      'Naipadala ang lokasyon para sa pag-apruba ng CSWD (o itatago hanggang maka-online).';

  @override
  String get facilityRequestsTitle => 'Mga hiling na pasilidad';

  @override
  String get facilityRequestsNone => 'Wala pang hiling.';

  @override
  String get facilityRequestsNeedConnection =>
      'Kailangan ng internet para makita ang mga naunang hiling.';

  @override
  String get facilityRequestsAsk => 'Hilingin ang kulang';

  @override
  String get facilityRequestWhat => 'Ano ang kulang';

  @override
  String get facilityRequestOther => 'Iba pa (i-type)';

  @override
  String get facilityRequestItem => 'Ano ang kailangan';

  @override
  String get facilityRequestQuantity => 'Ilan';

  @override
  String get facilityRequestReason => 'Bakit (opsyonal)';

  @override
  String get facilityRequestSend => 'Ipadala sa CSWD';

  @override
  String get facilityRequestSent =>
      'Naipadala ang hiling sa CSWD (o itatago hanggang maka-online).';

  @override
  String facilityRequestSummary(String what, int count, String center) {
    return '$what × $count para sa $center';
  }

  @override
  String get requestStatusWaiting => 'Naghihintay';

  @override
  String get requestStatusApproved => 'Naaprubahan';

  @override
  String get requestStatusRejected => 'Tinanggihan';

  @override
  String get requestStatusFulfilled => 'Naibigay';

  @override
  String get decrease => 'Bawasan';

  @override
  String get increase => 'Dagdagan';

  @override
  String get reliefTitle => 'Mga relief box';

  @override
  String get staffTabRelief => 'Relief';

  @override
  String get reliefNeedsConnectionFirst =>
      'Kailangan ng internet sa unang pagbukas ng relief box.';

  @override
  String get staffNoOpenEvent =>
      'Wala pang bukas na event. Nagbubukas ang CSWDO ng event kapag may ibinabalang banta.';

  @override
  String savedCopyAge(Object age) {
    return 'Naka-save na kopya, $age';
  }

  @override
  String get reliefCountNotValidated =>
      'Hindi pa beripikado ang final count ng inyong barangay. Hanggang hindi ito beripikado ng CSWD, 0 ang pangangailangan at walang box na maipapadala.';

  @override
  String get reliefNoRoundYet => 'Wala pang relief round.';

  @override
  String reliefRound(int number) {
    return 'Round $number';
  }

  @override
  String get reliefNeed => 'Kailangan';

  @override
  String get reliefReceived => 'Natanggap';

  @override
  String get reliefGiven => 'Naibigay';

  @override
  String get reliefShort => 'Kulang';

  @override
  String get reliefBoxesToConfirm => 'Mga box na kukumpirmahin';

  @override
  String get reliefGiveBoxes => 'Magbigay ng box';

  @override
  String reliefGivenOfReceived(int given, int received) {
    return '$given naibigay sa $received natanggap';
  }

  @override
  String reliefBoxesSent(String boxes, int round) {
    return '$boxes ang ipinadala, round $round';
  }

  @override
  String get reliefConfirmArrived => 'Kumpirmahin ang dumating';

  @override
  String get reliefHowManyArrived => 'Ilang box ang dumating?';

  @override
  String reliefBoxesArrived(int sent) {
    return 'Mga box na natanggap (sa $sent na ipinadala)';
  }

  @override
  String get reliefFewerNote => 'Bakit kulang? (kailangan)';

  @override
  String get reliefConfirm => 'Kumpirmahin';

  @override
  String reliefConfirmSummary(String boxes, int round) {
    return '$boxes ang natanggap, round $round';
  }

  @override
  String get reliefLeftToGive => 'Natitirang ibibigay';

  @override
  String get reliefByPriority => 'Ayon sa prayoridad';

  @override
  String get reliefByName => 'Ayon sa pangalan';

  @override
  String get reliefSuggestedOrderNote =>
      'Pagkakasunod ayon sa prayoridad: unahin ang mga pamilya sa itaas.';

  @override
  String reliefPurokHeading(String purok, int given, int total) {
    return '$purok · $given sa $total naibigay';
  }

  @override
  String get reliefGiveBox => 'Ibigay ang box';

  @override
  String get reliefGivenWaiting => 'Naibigay, naghihintay ma-sync';

  @override
  String get reliefVoidWaiting => 'Pag-void na naghihintay ma-sync';

  @override
  String get reliefVoidHandout => 'I-void ang pagbigay';

  @override
  String reliefVoidTitle(Object family) {
    return 'I-void ang box para sa $family?';
  }

  @override
  String get reliefVoidBody =>
      'Lalabas ang pamilya na hindi pa nabibigyan. Hindi na ito maibabalik.';

  @override
  String get reliefVoidReason => 'Dahilan (kailangan)';

  @override
  String reliefGiveSummary(String family, int round) {
    return 'Box para sa $family, round $round';
  }

  @override
  String reliefVoidSummary(Object family) {
    return 'I-void ang box para sa $family';
  }

  @override
  String get staffTabBarangay => 'Barangay';

  @override
  String get barangayStatusNeedsConnection =>
      'Kailangan ng internet sa unang pagkuha ng status ng barangay.';

  @override
  String barangayStatusSetBy(Object name, Object when) {
    return 'Itinakda ni $name, $when';
  }

  @override
  String get barangayStatusReadOnly =>
      'Sarado na ang event. Mababago lang ang status habang bukas ang event.';

  @override
  String barangayStatusCswdOrder(Object status) {
    return 'Nasa \"$status\", iniutos ng CSWD. CSWD lang ang makakapagbago nito.';
  }

  @override
  String get barangayStatusChange => 'Baguhin ang status';

  @override
  String get barangayStatusNote =>
      'Tala (opsyonal; kailangan para i-update ang parehong status)';

  @override
  String get barangayStatusSave => 'I-save ang status';

  @override
  String barangayStatusSaved(Object status) {
    return 'Minarkahan na \"$status\" (ipapadala pagka-online).';
  }

  @override
  String get finalCountTitle => 'Final count';

  @override
  String finalCountFigures(String families, String persons) {
    return '$families · $persons';
  }

  @override
  String finalCountInsideOutside(int inside, int outside) {
    return '$inside nasa loob ng center · $outside nasa labas';
  }

  @override
  String finalCountNoStay(int count) {
    return '$count na walang naitalang pananatili';
  }

  @override
  String get finalCountNotSubmitted => 'Hindi pa naisusumite';

  @override
  String get finalCountWaiting => 'Naisumite, hinihintay ang CSWD';

  @override
  String get finalCountReturned => 'Ibinalik ng CSWD';

  @override
  String finalCountValidated(String families) {
    return 'Beripikado: $families (ang pangangailangan sa relief)';
  }

  @override
  String get finalCountChanged =>
      'Nagbago ang bilang mula sa huling pagsumite.';

  @override
  String get finalCountSubmit => 'Isumite ang final count';

  @override
  String get finalCountSubmitUpdated => 'Isumite ang bagong bilang';

  @override
  String get finalCountSubmitTitle => 'Isumite ang final count na ito?';

  @override
  String get finalCountComputedNote =>
      'Kinukuwenta ng sistema ang mga bilang mula sa mga pamilyang nakarehistro sa event na ito; hindi ito tina-type.';

  @override
  String get finalCountNote => 'Tala para sa CSWD (opsyonal)';

  @override
  String finalCountSummary(String families, String persons) {
    return 'Final count: $families, $persons';
  }

  @override
  String reliefShortfallTitle(int round) {
    return 'Humiling ng dagdag na box para sa round $round';
  }

  @override
  String get reliefShortfallSend => 'Ipadala ang hiling';

  @override
  String reliefShortfallAsk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Humiling ng hanggang $count pang box',
      one: 'Humiling ng 1 pang box',
    );
    return '$_temp0';
  }

  @override
  String reliefShortfallRow(int count, String status) {
    return 'Humiling ng $count pa: $status';
  }

  @override
  String reliefShortfallSummary(int count, int round) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Humiling ng $count pang box, round $round',
      one: 'Humiling ng 1 pang box, round $round',
    );
    return '$_temp0';
  }

  @override
  String get staffMyCentersSubtitle =>
      'Itakda ang lokasyon, hilingin ang kulang';

  @override
  String get pendingRegistrationsRetiring =>
      'Hindi na nagsisimula ng buong rehistro sa telepono; sa EC Board na inilalagay ang mga pamilya. I-sync o ayusin ang mga nasa ibaba. Mawawala ang screen na ito kapag tapos na ang mga ito.';

  @override
  String get monitoringTitle => 'Monitoring';

  @override
  String get staffTabMonitoring => 'Monitoring';

  @override
  String get monitoringOverview => 'Buod';

  @override
  String get monitoringCenters => 'Mga center';

  @override
  String get monitoringBarangays => 'Mga barangay';

  @override
  String get monitoringRequests => 'Mga hiling';

  @override
  String get monitoringPersons => 'Tao';

  @override
  String get monitoringFamilies => 'Pamilya';

  @override
  String get monitoringInside => 'Nasa loob ng center';

  @override
  String get monitoringCentersInUse => 'Ginagamit na center';

  @override
  String monitoringArrivedLastHour(int count) {
    return '$count ang dumating sa nakaraang oras';
  }

  @override
  String get monitoringNeedsAttention => 'Kailangang tingnan';

  @override
  String get monitoringNothingUrgent => 'Walang kailangang tingnan ngayon.';

  @override
  String monitoringCentersSummary(int inUse, String centers, int noCapacity) {
    return '$inUse sa $centers ang ginagamit · $noCapacity walang kapasidad';
  }

  @override
  String monitoringShort(Object items) {
    return 'Kulang: $items';
  }

  @override
  String get monitoringNoChecklist => 'Walang checklist ng pasilidad';

  @override
  String monitoringInsideNoCapacity(int count) {
    return '$count sa loob · walang kapasidad';
  }

  @override
  String get monitoringNotNormal => 'Hindi normal';

  @override
  String get monitoringAllNormal => 'Normal ang lahat ng barangay.';

  @override
  String get monitoringLatestChanges => 'Pinakabagong pagbabago';

  @override
  String get monitoringNoRequests => 'Walang hiling na naghihintay.';

  @override
  String monitoringWaited(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get monitoringNeedsConnection =>
      'Kailangan ng internet sa unang pagbukas ng monitoring.';

  @override
  String monitoringUpdated(Object age) {
    return 'Na-update $age';
  }

  @override
  String get reliefNextInLine => 'Susunod';

  @override
  String get reliefWaitingForBoxes => 'Naghihintay ng dagdag na box';

  @override
  String reliefOutOfOrderTitle(Object family) {
    return 'Bigyan ng box ang $family ngayon?';
  }

  @override
  String reliefOutOfOrderBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'May $count pamilyang mas mataas ang prayoridad na naghihintay pa.',
      one: 'May 1 pamilyang mas mataas ang prayoridad na naghihintay pa.',
    );
    return '$_temp0';
  }

  @override
  String countFamilies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pamilya',
      one: '1 pamilya',
    );
    return '$_temp0';
  }

  @override
  String countPersons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tao',
      one: '1 tao',
    );
    return '$_temp0';
  }

  @override
  String countBoxes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count box',
      one: '1 box',
    );
    return '$_temp0';
  }

  @override
  String countCenters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count center',
      one: '1 center',
    );
    return '$_temp0';
  }

  @override
  String countEvacuees(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count evacuee',
      one: '1 evacuee',
    );
    return '$_temp0';
  }

  @override
  String get registerTitle => 'Irehistro ang pamilya';

  @override
  String get registerStepHead => 'Puno ng pamilya';

  @override
  String get registerStepMembers => 'Mga miyembro';

  @override
  String get registerStepPlace => 'Purok at center';

  @override
  String get registerStepReview => 'Suriin';

  @override
  String registerStepOf(int step, int total) {
    return 'Hakbang $step sa $total';
  }

  @override
  String get registerBack => 'Bumalik';

  @override
  String get registerNext => 'Susunod';

  @override
  String get registerSave => 'I-save';

  @override
  String registerSaved(Object name) {
    return 'Na-save ang pamilya ni $name. Ipapadala ngayon, o pagbalik ng internet.';
  }

  @override
  String get registerDiscardDraft => 'Itapon ang draft na ito';

  @override
  String get registerFirstName => 'Pangalan';

  @override
  String get registerMiddleName => 'Gitnang pangalan (opsyonal)';

  @override
  String get registerLastName => 'Apelyido';

  @override
  String get registerSex => 'Kasarian';

  @override
  String get registerBirthdate => 'Piliin ang petsa ng kapanganakan';

  @override
  String registerBirthdateValue(Object date) {
    return 'Ipinanganak $date';
  }

  @override
  String get registerMobile => 'Mobile number';

  @override
  String get registerMobileInvalid => '11 digit na nagsisimula sa 09 (o +639)';

  @override
  String get registerPwd => 'May kapansanan (PWD)';

  @override
  String get registerPwdType => 'Uri ng kapansanan';

  @override
  String get registerSoloParent => 'Solo parent';

  @override
  String get registerIndigenous => 'Katutubo';

  @override
  String get register4ps => 'Benepisyaryo ng 4Ps';

  @override
  String get registerMembersHint =>
      'Idagdag ang ibang miyembro ng pamilya. Gagamitin ang mobile number ng puno maliban kung may sarili sila.';

  @override
  String get registerAddMember => 'Magdagdag ng miyembro';

  @override
  String get registerEditMember => 'I-edit ang miyembro';

  @override
  String get registerRemoveMember => 'Tanggalin ang miyembro';

  @override
  String get registerSaveMember => 'I-save ang miyembro';

  @override
  String get registerBarangay => 'Barangay';

  @override
  String get registerCenter => 'Evacuation center';

  @override
  String get registerHomeAddress => 'Tirahan (opsyonal)';

  @override
  String get registerSaveNote =>
      'Una itong nase-save sa teleponong ito at saka ipinapadala; walang mawawala kahit offline.';

  @override
  String get sexFemaleShort => 'Babae';

  @override
  String get sexMaleShort => 'Lalaki';
}
