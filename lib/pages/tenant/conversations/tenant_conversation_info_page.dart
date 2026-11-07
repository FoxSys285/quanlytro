import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/admin_store.dart';
import '../../../data/local_auth.dart';
import '../../../data/property_catalog.dart';
import '../tenant_detail_ui.dart';
import '../tenant_ui.dart';
import '../../landlord/landlord_demo_store.dart';
import '../../landlord/properties/models/landlord_property.dart';
import '../../landlord/properties/components/landlord_property_image.dart';
import '../discovery/models/tenant_property_listing.dart';
import 'models/tenant_cuoctrochuyen.dart';
import 'tenant_conversation_property_detail_page.dart';

class TenantConversationInfoPage extends StatefulWidget {
  const TenantConversationInfoPage({super.key, required this.conversation});

  final TenantConversation conversation;

  @override
  State<TenantConversationInfoPage> createState() =>
      _TenantConversationInfoPageState();
}

class _TenantConversationInfoPageState
    extends State<TenantConversationInfoPage> {
  List<TenantPropertyListing>? _remoteProperties;
  bool _loadingRemote = false;

  @override
  void initState() {
    super.initState();
    final source = widget.conversation.source;
    if (source != null && LocalAuth.instance.isCloudMode) {
      _loadingRemote = true;
      unawaited(_loadOwnerProperties(source.propertyId));
    }
  }

  Future<void> _loadOwnerProperties(String propertyId) async {
    try {
      final properties = await FirestoreTenantPropertyCatalogSource()
          .fetchPropertiesForOwnerOf(propertyId);
      if (!mounted) return;
      setState(() => _remoteProperties = properties);
    } catch (_) {
      if (!mounted) return;
      setState(() => _remoteProperties = null);
    } finally {
      if (mounted) setState(() => _loadingRemote = false);
    }
  }

  List<TenantPropertyListing> _propertiesForOwner() {
    final source = widget.conversation.source;
    final currentStore = source == null
        ? null
        : RentalPortfolio.instance.byId(source.propertyId);
    final currentProperty = currentStore?.property;
    final ownerName = currentProperty?.ownerName.trim().isNotEmpty == true
        ? currentProperty!.ownerName.trim()
        : widget.conversation.landlordName.trim();
    final normalizedOwner = ownerName.toLowerCase();
    final byId = <String, TenantPropertyListing>{};

    if (_remoteProperties != null) {
      for (final property in _remoteProperties!) {
        byId[property.property.id] = property;
      }
      if (currentStore != null && !byId.containsKey(currentStore.property.id)) {
        byId[currentStore.property.id] = TenantPropertyListing.fromStore(
          currentStore,
          verified: AdminStore.instance.isVerified(currentStore.property.id),
        );
      }
    } else {
      for (final store in RentalPortfolio.instance.stores) {
        final isCurrentProperty = store.property.id == source?.propertyId;
        final hasSameOwner =
            normalizedOwner.isNotEmpty &&
            normalizedOwner != 'chủ trọ' &&
            store.property.ownerName.trim().toLowerCase() == normalizedOwner;
        if (!isCurrentProperty &&
            (!hasSameOwner ||
                AdminStore.instance.isHidden(store.property.id))) {
          continue;
        }
        byId[store.property.id] = TenantPropertyListing.fromStore(
          store,
          verified: AdminStore.instance.isVerified(store.property.id),
        );
      }
    }

    if (source != null && !byId.containsKey(source.propertyId)) {
      final name = source.propertyName.trim();
      if (name.isNotEmpty) {
        byId[source.propertyId] = TenantPropertyListing(
          property: LandlordProperty(
            id: source.propertyId,
            name: name,
            address: '',
            ownerName: ownerName,
            phone: '',
            description: '',
          ),
          roomCount: 0,
          minRent: null,
          verified: false,
        );
      }
    }

    final properties = byId.values.toList();
    properties.sort((a, b) {
      if (a.property.id == source?.propertyId) return -1;
      if (b.property.id == source?.propertyId) return 1;
      return a.property.name.compareTo(b.property.name);
    });
    return properties;
  }

  @override
  Widget build(BuildContext context) {
    final properties = _propertiesForOwner();
    final name = widget.conversation.landlordName.trim();
    return TenantDetailTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Thông tin chủ trọ')),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LandlordProfileCard(name: name),
                    const SizedBox(height: 26),
                    TenantSectionHeading(
                      'Nhà trọ',
                      trailing: Text(
                        _loadingRemote
                            ? 'Đang tải'
                            : '${properties.length} nhà',
                        style: const TextStyle(
                          color: tenantMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (properties.isEmpty && _loadingRemote)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 26),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (properties.isEmpty)
                      const TenantEmptyState(
                        icon: Icons.home_work_outlined,
                        title: 'Chưa có thông tin nhà trọ',
                        subtitle: 'Thông tin nhà trọ sẽ xuất hiện tại đây.',
                      )
                    else
                      for (final property in properties) ...[
                        _PropertyCard(
                          listing: property,
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  TenantConversationPropertyDetailPage(
                                    listing: property,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LandlordProfileCard extends StatelessWidget {
  const _LandlordProfileCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE4F6EA), Color(0xFFF6FBF7)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFD5EBDD)),
    ),
    child: Row(
      children: [
        TenantProfileAvatar(name: name, radius: 34),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CHỦ TRỌ',
                style: TextStyle(
                  color: tenantGreenDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                name.isEmpty ? 'Chủ trọ' : name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: tenantInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.listing, required this.onTap});

  final TenantPropertyListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final property = listing.property;
    return TenantSurface(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: LandlordPropertyImage(
                  url: property.imageUrl,
                  bytes: property.imageBytes,
                  height: 88,
                  borderRadius: 14,
                  semanticLabel: 'Ảnh ${property.name}',
                  showIllustrationLabel: false,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: tenantInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      property.address.isEmpty
                          ? 'Chưa cập nhật địa chỉ'
                          : property.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: tenantMuted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${listing.roomCount} phòng',
                      style: const TextStyle(
                        color: tenantGreenDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: tenantMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
