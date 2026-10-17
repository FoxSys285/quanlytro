import 'package:flutter/foundation.dart';

import '../../../layouts/role_layout.dart';
import '../../landlord/landlord_demo_store.dart';
import '../../landlord/properties/models/landlord_property.dart';
import '../rental/tenant_session.dart';
import 'contact_details.dart';

/// Per-account demo preferences and contact information for the current session.
class AccountStore extends ChangeNotifier {
  AccountStore({required this.rental}) {
    rental.addListener(notifyListeners);
  }
  static final instance = AccountStore(rental: LandlordDemoStore.instance);
  final LandlordDemoStore rental;
  final _contacts = <AppRole, ContactDetails>{};
  final _notifications = <AppRole, bool>{};
  bool notificationsEnabled(AppRole role) => _notifications[role] ?? true;
  void setNotificationsEnabled(AppRole role, bool enabled) {
    _notifications[role] = enabled;
    notifyListeners();
  }

  ContactDetails profile(AppRole role) {
    final saved = _contacts[role];
    if (role == AppRole.landlord) {
      final property = rental.property;
      return ContactDetails(
        name: property.ownerName,
        phone: property.phone,
        email: saved?.email ?? 'nguyenvanan@example.com',
        address: saved?.address ?? property.address,
      );
    }
    final members = rental.members
        .where((member) => member.tenantId == TenantSession.tenantId)
        .toList();
    return ContactDetails(
      name: members.isEmpty
          ? saved?.name ?? TenantSession.name
          : members.first.name,
      phone: members.isEmpty
          ? saved?.phone ?? TenantSession.phone
          : members.first.phone,
      email: saved?.email ?? 'minhanh@example.com',
      address: saved?.address ?? 'Bình Thạnh, TP. Hồ Chí Minh',
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
          city: property.city,
          ward: property.ward,
        ),
      );
    } else {
      rental.updateTenantContact(
        TenantSession.tenantId,
        name: contact.name,
        phone: contact.phone,
      );
    }
  }

  @override
  void dispose() {
    rental.removeListener(notifyListeners);
    super.dispose();
  }
}
