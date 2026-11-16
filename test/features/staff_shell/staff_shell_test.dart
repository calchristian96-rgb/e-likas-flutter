import 'package:elikas_mobile/features/staff_shell/staff_shell.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_auth.dart';

void main() {
  test('old Settings staff links land in Staff Mode', () {
    expect(redirectOldStaffPath('/settings/staff'), '/staff');
    expect(redirectOldStaffPath('/settings/staff/login'), '/staff');
    expect(redirectOldStaffPath('/settings/staff/ec-board'), '/staff/centers');
    expect(
      redirectOldStaffPath('/settings/staff/ec-board/42'),
      '/staff/centers/42',
    );
    expect(
      redirectOldStaffPath('/settings/staff/all-evacuees'),
      '/staff/more/all-evacuees',
    );
    expect(redirectOldStaffPath('/settings'), isNull);
    expect(redirectOldStaffPath('/home'), isNull);
  });

  test('field work tabs are for barangay officials only', () {
    Iterable<int> branchesFor(session) =>
        staffTabs.where((t) => t.visibleTo(session)).map((t) => t.branch);
    expect(branchesFor(official), contains(0));
    expect(branchesFor(cswd), isNot(contains(0)));
  });
}
