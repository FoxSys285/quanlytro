import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/firebase_account_gateway.dart';
import 'package:quanlytro/data/firebase_media_store.dart';
import 'package:quanlytro/data/rental_cloud_codec.dart';
import 'package:quanlytro/data/scoped_firestore_repository.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/pages/landlord/finance/landlord_finance_models.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/shared/rental/lease_member.dart';

import 'support/memory_firestore_queries.dart';

class _Media extends Fake implements FirebaseMediaStore {
  @override
  Future<Map<String, Map<String, dynamic>>> prepareForCloud(
    Map<String, Map<String, dynamic>> snapshot, {
    bool uploadPropertyMedia = true,
    bool uploadPaymentProofs = true,
    String? uploaderUid,
  }) async => snapshot;
}

void main() {
  test(
    'Lease termination and member leave requests persist as requests only',
    () async {
      final seed = LandlordDemoStore.demo();
      addTearDown(seed.dispose);
      final seedLease = seed.leases.firstWhere((lease) => lease.isCurrent);
      final seedMember = seed.members.firstWhere(
        (member) =>
            member.status == LeaseMemberStatus.active &&
            !member.isRepresentative,
      );
      final originalRent = seedLease.monthlyRent;
      final encoded = encodeCloudDocuments(
        {
          'portfolio': {
            'properties': [seed.toMap()],
          },
        },
        owners: {'may': 'owner-a'},
      );
      final docs = <String, Map<String, Json>>{};
      for (final entry in encoded.entries) {
        final parts = entry.key.split('/');
        docs.putIfAbsent(parts[0], () => {})[parts[1]] =
            jsonDecode(jsonEncode(entry.value)) as Map<String, dynamic>;
      }

      final db = MemoryFirestore(docs);
      final representativeId = seedLease.tenantId;
      final leaseRepository = _repository(db, representativeId);
      final leaseSnapshot = await leaseRepository.readAll();
      final leasePortfolio = RentalPortfolio.fromMap(
        leaseSnapshot['portfolio']!,
      );
      addTearDown(leasePortfolio.dispose);
      leaseRepository.setLocalSnapshotBaseline(leaseSnapshot);
      final leaseStore = leasePortfolio.active;
      final lease = leaseStore.leaseById(seedLease.id)!;
      leaseStore.requestLeaseTermination(
        tenantId: representativeId,
        leaseId: lease.id,
        reason: 'Work relocation',
      );
      lease.monthlyRent = originalRent + 1;
      leaseSnapshot['portfolio'] = leasePortfolio.toMap();
      await leaseRepository.saveAll(leaseSnapshot);

      final reloadedLeaseRepository = _repository(db, representativeId);
      final reloadedLeaseSnapshot = await reloadedLeaseRepository.readAll();
      final reloadedLeasePortfolio = RentalPortfolio.fromMap(
        reloadedLeaseSnapshot['portfolio']!,
      );
      addTearDown(reloadedLeasePortfolio.dispose);
      final reloadedLease = reloadedLeasePortfolio.active.leaseById(
        seedLease.id,
      )!;
      expect(reloadedLease.status, LandlordLeaseStatus.active);
      expect(reloadedLease.terminationRequestStatus, 'pending');
      expect(reloadedLease.terminationRequestReason, 'Work relocation');
      expect(reloadedLease.monthlyRent, originalRent);

      final memberRepository = _repository(db, seedMember.tenantId);
      final memberSnapshot = await memberRepository.readAll();
      final memberPortfolio = RentalPortfolio.fromMap(
        memberSnapshot['portfolio']!,
      );
      addTearDown(memberPortfolio.dispose);
      memberRepository.setLocalSnapshotBaseline(memberSnapshot);
      final memberStore = memberPortfolio.active;
      expect(
        memberStore.members.any(
          (candidate) => candidate.tenantId == seedMember.tenantId,
        ),
        isTrue,
      );
      memberStore.requestMemberLeave(
        tenantId: seedMember.tenantId,
        reason: 'Moving to another city',
      );
      memberSnapshot['portfolio'] = memberPortfolio.toMap();
      await memberRepository.saveAll(memberSnapshot);

      final reloadedMemberSnapshot = await _repository(
        db,
        seedMember.tenantId,
      ).readAll();
      final reloadedMemberPortfolio = RentalPortfolio.fromMap(
        reloadedMemberSnapshot['portfolio']!,
      );
      addTearDown(reloadedMemberPortfolio.dispose);
      final reloadedMember = reloadedMemberPortfolio.active.members.firstWhere(
        (candidate) => candidate.tenantId == seedMember.tenantId,
      );
      expect(reloadedMember.status, LeaseMemberStatus.active);
      expect(reloadedMember.leaveReason, 'Moving to another city');
      expect(reloadedMember.leaveRequestedAt, isNotNull);
    },
  );
}

ScopedFirestoreRentalRepository _repository(
  MemoryFirestore db,
  String tenantId,
) => ScopedFirestoreRentalRepository(
  session: FirebaseAccountSession(
    uid: 'account-$tenantId',
    role: AppRole.tenant,
    tenantId: tenantId,
  ),
  firestore: db,
  mediaStore: _Media(),
);
