import 'package:flutter/foundation.dart';

import '../../../data/local_auth.dart';
import '../../../layouts/role_layout.dart';
import '../../landlord/landlord_demo_store.dart';
import '../../landlord/properties/models/landlord_property.dart';
import '../rental/tenant_session.dart';
import 'contact_details.dart';

/// Saved per-account preferences and contact information.
class AccountStore extends ChangeNotifier {
  AccountStore({required LandlordDemoStore rental})
    : _fallbackRental = rental,
      _portfolio = RentalPortfolio.instance,
      _portfolioBacked = RentalPortfolio.instance.stores.contains(rental) ||
          identical(RentalPortfolio.instance.active, rental) {
    if (_portfolioBacked) {
      _portfolio.addListener(notifyListeners);
    } else {
      _fallbackRental.addListener(notifyListeners);
    }
  }
  static AccountStore instance = AccountStore(
    rental: LandlordDemoStore.instance,
  );
  final RentalPortfolio _portfolio;
  final bool _portfolioBacked;
  LandlordDemoStore _fallbackRental;
  LandlordDemoStore get rental =>
      _portfolioBacked && identical(_portfolio, RentalPortfolio.instance)
      ? _portfolio.active
      : _fallbackRental;
  final _contacts = <AppRole, ContactDetails>{};
  final _notifications = <AppRole, bool>{};
  Map<String, dynamic> toMap() => {
    'contacts': _contacts.map((k, v) => MapEntry(k.name, v.toMap())),
    'notifications': _notifications.map((k, v) => MapEntry(k.name, v)),
  };
  void restore(Map<String, dynamic> map) {
    _contacts.clear();
    _notifications.clear();
    (map['contacts'] as Map).forEach(
      (k, v) => _contacts[AppRole.values.byName(k as String)] =
          ContactDetails.fromMap(Map<String, dynamic>.from(v as Map)),
    );
    (map['notifications'] as Map).forEach(
      (k, v) => _notifications[AppRole.values.byName(k as String)] = v as bool,
    );
    notifyListeners();
  }

  void rebindRental(LandlordDemoStore nextRental) {
    if (_portfolioBacked) {
      _fallbackRental = nextRental;
      notifyListeners();
      return;
    }
    if (identical(rental, nextRental)) return;
    _fallbackRental.removeListener(notifyListeners);
    _fallbackRental = nextRental;
    _fallbackRental.addListener(notifyListeners);
    notifyListeners();
  }

  bool notificationsEnabled(AppRole role) => _notifications[role] ?? true;
  void setNotificationsEnabled(AppRole role, bool enabled) {
    _notifications[role] = enabled;
    notifyListeners();
  }

  ContactDetails profile(AppRole role) {
    final saved = _contacts[role];
    if (role == AppRole.admin) {
      return saved ??
          const ContactDetails(name: 'Quản trị viên', phone: '', email: '');
    }
    if (role == AppRole.landlord) {
      final property = rental.property;
      return ContactDetails(
        name: property.ownerName,
        phone: property.phone,
        email: saved?.email ?? 'nguyenvanan@example.com',
        address: saved?.address ?? property.address,
      );
    }
    final cloudTenant = TenantSession.authenticatedTenantId != null;
    if (cloudTenant && saved != null) return saved;
    final authSession = LocalAuth.instance.session;
    final members = rental.members
        .where((member) => member.tenantId == TenantSession.currentTenantId)
        .toList();
    return ContactDetails(
      name: members.isEmpty
          ? saved?.name ??
                (cloudTenant
                    ? authSession?.displayName ?? 'Người thuê'
                    : TenantSession.name)
          : members.first.name,
      phone: members.isEmpty
          ? saved?.phone ?? (cloudTenant ? '' : TenantSession.phone)
          : members.first.phone,
      email: saved?.email ??
          (cloudTenant ? authSession?.email ?? '' : 'minhanh@example.com'),
      address:
          saved?.address ?? (cloudTenant ? '' : 'Bình Thạnh, TP. Hồ Chí Minh'),
    );
  }

  void saveProfile(AppRole role, ContactDetails contact) {
    validateContact(contact);
    _contacts[role] = contact;
    if (role == AppRole.landlord) {
      final property = rental.property;
      rental.updateProperty(
        LandlordProperty(
          id: property.id,
          name: property.name,
          address: property.address,
          ownerName: contact.name,
          phone: contact.phone,
          description: property.description,
          imageUrl: property.imageUrl,
          imageBytes: property.imageBytes,
          imageName: property.imageName,
          amenities: property.amenities,
          city: property.city,
          ward: property.ward,
        ),
      );
    } else if (role == AppRole.tenant &&
        TenantSession.authenticatedTenantId == null) {
      // Hồ sơ cá nhân cloud nằm trong user_state; hợp đồng do chủ trọ quản lý.
      rental.updateTenantContact(
        TenantSession.currentTenantId,
        name: contact.name,
        phone: contact.phone,
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    if (_portfolioBacked) {
      _portfolio.removeListener(notifyListeners);
    } else {
      _fallbackRental.removeListener(notifyListeners);
    }
    super.dispose();
  }
}
