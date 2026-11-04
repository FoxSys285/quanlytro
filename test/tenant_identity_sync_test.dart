import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/data/firebase_account_gateway.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/shared/profile/account_store.dart';
import 'package:quanlytro/pages/shared/profile/contact_details.dart';
import 'package:quanlytro/pages/shared/rental/rental_record_id.dart';
import 'package:quanlytro/pages/shared/rental/tenant_session.dart';
import 'package:quanlytro/pages/tenant/announcements/tenant_announcements_page.dart';
import 'package:quanlytro/pages/tenant/discovery/tenant_discovery_page.dart';
import 'package:quanlytro/pages/tenant/incidents/tenant_baosuco_page.dart';
import 'package:quanlytro/pages/tenant/invoices/tenant_invoice_detail_page.dart';
import 'package:quanlytro/pages/tenant/invoices/tenant_invoices_page.dart';
import 'package:quanlytro/pages/tenant/invoices/components/tenant_payment_instructions_sheet.dart';
import 'package:quanlytro/pages/tenant/leases/tenant_home_page.dart';
import 'package:quanlytro/pages/tenant/leases/tenant_lease_contract_page.dart';
import 'package:quanlytro/pages/tenant/members/tenant_members_page.dart';
import 'package:quanlytro/pages/tenant/viewings/tenant_viewings_page.dart';

void main() {
  tearDown(() => TenantSession.authenticatedTenantId = null);

  test('Nested tenant pages resolve the authenticated identity by default', () {
    TenantSession.authenticatedTenantId = 'tenant-second';
    expect(const TenantHomePage().tenantId, 'tenant-second');
    expect(const TenantLeaseContractPage().tenantId, 'tenant-second');
    expect(const TenantMembersPage().tenantId, 'tenant-second');
    expect(const TenantInvoicesPage().tenantId, 'tenant-second');
    expect(
      const TenantInvoiceDetailPage(invoiceId: 'i').tenantId,
      'tenant-second',
    );
    expect(
      const TenantPaymentInstructionsSheet(invoiceId: 'i').tenantId,
      'tenant-second',
    );
    expect(const TenantAnnouncementsPage().tenantId, 'tenant-second');
    expect(const TenantBaoSuCoPage().tenantId, 'tenant-second');
    expect(const TenantViewingsPage().tenantId, 'tenant-second');
    expect(const TenantDiscoveryPage().tenantId, 'tenant-second');
    expect(const TenantInvoicesPage(tenantId: 'explicit').tenantId, 'explicit');
  });

  test(
    'Cloud profile saves personal state without rewriting legal records',
    () {
      final rental = LandlordDemoStore.demo();
      final accounts = AccountStore(rental: rental);
      addTearDown(rental.dispose);
      addTearDown(accounts.dispose);
      TenantSession.authenticatedTenantId = TenantSession.tenantId;
      final lease = rental.currentLeaseForTenant(TenantSession.tenantId)!;
      final originalName = lease.tenantName;
      accounts.saveProfile(
        AppRole.tenant,
        const ContactDetails(
          name: 'Liên hệ mới',
          phone: '0901234567',
          email: 'new@example.com',
        ),
      );
      expect(accounts.profile(AppRole.tenant).name, 'Liên hệ mới');
      expect(accounts.toMap()['contacts']['tenant']['name'], 'Liên hệ mới');
      expect(lease.tenantName, originalName);
      expect(
        rental.members
            .where((m) => m.tenantId == TenantSession.tenantId)
            .every((m) => m.name != 'Liên hệ mới'),
        isTrue,
      );
    },
  );

  test('Independent clients do not reuse sequential rental record IDs', () {
    final ids = List.generate(1000, (_) => rentalRecordId('payment'));
    expect(ids.toSet(), hasLength(1000));
    expect(
      ids.every((id) => RegExp(r'^payment-[0-9a-f]{32}$').hasMatch(id)),
      isTrue,
    );
  });

  test('Provisioned tenant IDs must remain safe document key components', () {
    for (final id in ['', '   ', ' tenant ', 'a/b', 'a:b']) {
      expect(
        () => FirebaseAccountSession.fromProfile('u', {
          'role': 'tenant',
          'disabled': false,
          'tenantId': id,
        }),
        throwsArgumentError,
      );
    }
  });
}
