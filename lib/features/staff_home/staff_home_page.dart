import 'package:flutter/material.dart';

import '../staff_auth/presentation/widgets/staff_auth_guard.dart';
import '../monitoring/monitoring_page.dart';
import 'official_home_page.dart';

/// Staff Mode's Home tab: city-wide monitoring for a CSWDO account, the
/// barangay official's home otherwise (from /auth/me permissions).
class StaffHomePage extends StatelessWidget {
  const StaffHomePage({super.key});

  @override
  Widget build(BuildContext context) => StaffAuthGuard(
    builder: (context, session) => session.isCityMonitor
        ? const MonitoringPage()
        : OfficialHomePage(session: session),
  );
}
