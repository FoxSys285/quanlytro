import 'package:flutter/material.dart';

import '../finance/landlord_finance_models.dart';
import '../landlord_demo_store.dart';
import '../landlord_ui.dart';

class LandlordLeasesPage extends StatefulWidget {
  const LandlordLeasesPage({super.key});

  @override
  State<LandlordLeasesPage> createState() => _LandlordLeasesPageState();
}

class _LandlordLeasesPageState extends State<LandlordLeasesPage> {
  final _store = LandlordDemoStore.instance;
  String _filter = 'Tất cả';
  String _search = '';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final leases = _store.leases.where((lease) {
        final matchesSearch =
            lease.tenantName.toLowerCase().contains(_search.toLowerCase()) ||
            lease.room.toLowerCase().contains(_search.toLowerCase()) ||
            lease.id.toLowerCase().contains(_search.toLowerCase());
        final matchesFilter = switch (_filter) {
          'Đang thuê' => lease.isCurrent,
          'Sắp hết hạn' => lease.isExpiringSoon,
          'Sắp bắt đầu' => lease.isUpcoming,
          'Hết hạn' => lease.isExpired,
          'Nháp' => lease.status == LandlordLeaseStatus.draft,
          'Đã kết thúc' => lease.status == LandlordLeaseStatus.terminated,
          _ => true,
        };
        return matchesSearch && matchesFilter;
      }).toList()..sort((a, b) => a.endDate.compareTo(b.endDate));
      final currentCount = _store.activeLeases.length;
      final expiringCount = _store.leases
          .where((lease) => lease.isExpiringSoon)
          .length;

      return LandlordPageFrame(
        children: [
          LandlordPageTitle(
            title: 'Hợp đồng thuê',
            subtitle:
                '$currentCount hợp đồng hiệu lực · $expiringCount sắp hết hạn',
            trailing: FilledButton.icon(
              onPressed: () => _editLease(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tạo hợp đồng'),
            ),
          ),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Tìm theo người thuê, phòng hoặc mã hợp đồng',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) => setState(() => _search = value.trim()),
          ),
          const SizedBox(height: 11),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final label in const [
                  'Tất cả',
                  'Đang thuê',
                  'Sắp hết hạn',
                  'Sắp bắt đầu',
                  'Hết hạn',
                  'Nháp',
                  'Đã kết thúc',
                ]) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _filter == label,
                      onSelected: (_) => setState(() => _filter = label),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (leases.isEmpty)
            const LandlordEmptyState(message: 'Không có hợp đồng phù hợp.'),
          for (final lease in leases) _leaseCard(lease),
          const SizedBox(height: 4),
          const Text(
            'Dữ liệu hiện được lưu tạm trong phiên chạy ứng dụng.',
            style: TextStyle(color: landlordMuted, fontSize: 11),
          ),
        ],
      );
    },
  );

  Widget _leaseCard(LandlordLease lease) {
    final (status, color) = _leaseStatus(lease);
    return LandlordCard(
      onTap: () => _showLeaseDetails(lease),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: landlordBlue.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.description_outlined,
                  color: landlordBlue,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phòng ${lease.room} · ${lease.tenantName}',
                      style: const TextStyle(
                        color: landlordInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lease.id,
                      style: const TextStyle(
                        color: landlordMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              LandlordStatusPill(status, color: color),
            ],
          ),
          const Divider(height: 23),
          _detailLine(
            'Thời hạn',
            '${landlordDate(lease.startDate)} – ${landlordDate(lease.endDate)}',
          ),
          const SizedBox(height: 7),
          _detailLine(
            'Tiền thuê',
            '${formatLandlordMoney(lease.monthlyRent)} / tháng',
          ),
          const SizedBox(height: 7),
          _detailLine('Tiền cọc', formatLandlordMoney(lease.deposit)),
          const SizedBox(height: 7),
          _detailLine('Số người ở', '${lease.occupantCount} người'),
          if (lease.phone.isNotEmpty) ...[
            const SizedBox(height: 7),
            _detailLine('Liên hệ', lease.phone),
          ],
          const SizedBox(height: 11),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _editLease(lease),
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Chỉnh sửa'),
              ),
              if (lease.isCurrent)
                TextButton.icon(
                  onPressed: () => _endLease(lease),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB64A4A),
                  ),
                  icon: const Icon(Icons.event_busy_outlined, size: 17),
                  label: const Text('Kết thúc'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  (String, Color) _leaseStatus(LandlordLease lease) {
    if (lease.status == LandlordLeaseStatus.terminated) {
      return ('Đã kết thúc', landlordMuted);
    }
    if (lease.status == LandlordLeaseStatus.draft)
      return ('Nháp', const Color(0xFFE08A1E));
    if (lease.isExpiringSoon) return ('Sắp hết hạn', const Color(0xFFE08A1E));
    if (lease.isUpcoming) return ('Sắp bắt đầu', landlordBlue);
    if (lease.isExpired) return ('Hết hạn', landlordMuted);
    return ('Đang hiệu lực', const Color(0xFF16836F));
  }

  Widget _detailLine(String label, String value) => Row(
    children: [
      SizedBox(
        width: 100,
        child: Text(
          label,
          style: const TextStyle(color: landlordMuted, fontSize: 12),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: landlordInk,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  Future<void> _showLeaseDetails(LandlordLease lease) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.86,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hợp đồng ${lease.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: landlordInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phòng ${lease.room}',
                  style: const TextStyle(color: landlordMuted),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailHeading('BÊN A · BÊN CHO THUÊ'),
                        _detailLine('Họ tên', lease.landlordName),
                        _detailLine(
                          'Thường trú',
                          lease.landlordPermanentAddress,
                        ),
                        _detailLine('CCCD', lease.landlordCitizenId),
                        _detailLine('Điện thoại / Zalo', lease.landlordContact),
                        const SizedBox(height: 12),
                        _detailHeading('BÊN B · BÊN THUÊ'),
                        _detailLine('Họ tên', lease.tenantName),
                        _detailLine('Năm sinh', lease.tenantBirthYear),
                        _detailLine('CCCD', lease.tenantCitizenId),
                        _detailLine(
                          'Ngày cấp',
                          lease.tenantCitizenIssueDate == null
                              ? 'Chưa cập nhật'
                              : landlordDate(lease.tenantCitizenIssueDate!),
                        ),
                        _detailLine('Điện thoại / Zalo', lease.phone),
                        _detailLine('Thường trú', lease.tenantPermanentAddress),
                        const SizedBox(height: 12),
                        _detailHeading('PHÒNG VÀ CHI PHÍ'),
                        _detailLine('Số phòng', lease.room),
                        _detailLine(
                          'Giá phòng',
                          '${formatLandlordMoney(lease.monthlyRent)}/tháng',
                        ),
                        _detailLine(
                          'Tiền đặt cọc',
                          formatLandlordMoney(lease.deposit),
                        ),
                        _detailLine(
                          'Tiền điện',
                          '${formatLandlordMoney(lease.electricityPrice)}/kWh',
                        ),
                        _detailLine(
                          'Tiền nước',
                          '${formatLandlordMoney(lease.waterPrice)}/${lease.waterType == 'Theo tháng' ? 'tháng' : 'm³'}',
                        ),
                        _detailLine(
                          'Tiền xe',
                          '${formatLandlordMoney(lease.vehicleFee)}/tháng',
                        ),
                        _detailLine(
                          'Tiền dịch vụ',
                          '${formatLandlordMoney(lease.serviceFee)}/tháng',
                        ),
                        const SizedBox(height: 12),
                        _detailHeading('THỜI HẠN VÀ THANH TOÁN'),
                        _detailLine(
                          'Thời hạn thuê',
                          '${lease.termMonths} tháng',
                        ),
                        _detailLine('Từ ngày', landlordDate(lease.startDate)),
                        _detailLine('Đến ngày', landlordDate(lease.endDate)),
                        _detailLine(
                          'Ngày đóng tiền',
                          'Ngày ${lease.dueDay} hằng tháng',
                        ),
                        _detailLine(
                          'Số người ở',
                          '${lease.occupantCount} người',
                        ),
                        if (lease.cashPaymentEnabled)
                          _detailLine(
                            'Tiền mặt tại',
                            lease.cashPaymentLocation,
                          ),
                        if (lease.bankTransferEnabled) ...[
                          _detailLine('Ngân hàng', lease.bankName),
                          _detailLine('Số tài khoản', lease.bankAccountNumber),
                        ],
                        const SizedBox(height: 12),
                        _detailHeading('GHI CHÚ'),
                        Text(
                          lease.note.isEmpty ? 'Không có ghi chú.' : lease.note,
                          style: const TextStyle(
                            color: landlordInk,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editLease(lease);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Chỉnh sửa hợp đồng'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailHeading(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label,
      style: const TextStyle(
        color: landlordBlue,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
  );

  Future<void> _editLease([LandlordLease? lease]) async {
    final result = await showDialog<_LeaseDraft>(
      context: context,
      builder: (_) => _LeaseEditor(
        lease: lease,
        occupiedRooms: _store.activeLeases.map((item) => item.room).toSet(),
      ),
    );
    if (result == null || !mounted) return;
    try {
      _store.saveLease(
        existing: lease,
        room: result.room,
        landlordName: result.landlordName,
        landlordPermanentAddress: result.landlordPermanentAddress,
        landlordCitizenId: result.landlordCitizenId,
        landlordContact: result.landlordContact,
        tenantName: result.tenantName,
        tenantBirthYear: result.tenantBirthYear,
        tenantCitizenId: result.tenantCitizenId,
        tenantCitizenIssueDate: result.tenantCitizenIssueDate,
        tenantPermanentAddress: result.tenantPermanentAddress,
        phone: result.phone,
        startDate: result.startDate,
        endDate: result.endDate,
        monthlyRent: result.monthlyRent,
        deposit: result.deposit,
        termMonths: result.termMonths,
        electricityPrice: result.electricityPrice,
        waterPrice: result.waterPrice,
        waterType: result.waterType,
        vehicleFee: result.vehicleFee,
        serviceFee: result.serviceFee,
        dueDay: result.dueDay,
        cashPaymentEnabled: result.cashPaymentEnabled,
        cashPaymentLocation: result.cashPaymentLocation,
        bankTransferEnabled: result.bankTransferEnabled,
        bankName: result.bankName,
        bankAccountNumber: result.bankAccountNumber,
        occupantCount: result.occupantCount,
        note: result.note,
        status: result.status,
      );
      showLandlordMessage(
        context,
        lease == null ? 'Đã tạo hợp đồng.' : 'Đã cập nhật hợp đồng.',
      );
    } on ArgumentError catch (error) {
      showLandlordMessage(context, error.message.toString());
    }
  }

  Future<void> _endLease(LandlordLease lease) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kết thúc hợp đồng?'),
        content: Text(
          'Hợp đồng phòng ${lease.room} của ${lease.tenantName} sẽ chuyển sang trạng thái đã kết thúc.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kết thúc hợp đồng'),
          ),
        ],
      ),
    );
    if (confirmed == true) _store.endLease(lease);
  }
}

class _LeaseDraft {
  const _LeaseDraft({
    required this.room,
    required this.landlordName,
    required this.landlordPermanentAddress,
    required this.landlordCitizenId,
    required this.landlordContact,
    required this.tenantName,
    required this.tenantBirthYear,
    required this.tenantCitizenId,
    required this.tenantCitizenIssueDate,
    required this.tenantPermanentAddress,
    required this.phone,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.deposit,
    required this.termMonths,
    required this.electricityPrice,
    required this.waterPrice,
    required this.waterType,
    required this.vehicleFee,
    required this.serviceFee,
    required this.dueDay,
    required this.cashPaymentEnabled,
    required this.cashPaymentLocation,
    required this.bankTransferEnabled,
    required this.bankName,
    required this.bankAccountNumber,
    required this.occupantCount,
    required this.note,
    required this.status,
  });

  final String room;
  final String landlordName;
  final String landlordPermanentAddress;
  final String landlordCitizenId;
  final String landlordContact;
  final String tenantName;
  final String tenantBirthYear;
  final String tenantCitizenId;
  final DateTime? tenantCitizenIssueDate;
  final String tenantPermanentAddress;
  final String phone;
  final DateTime startDate;
  final DateTime endDate;
  final int monthlyRent;
  final int deposit;
  final int termMonths;
  final int electricityPrice;
  final int waterPrice;
  final String waterType;
  final int vehicleFee;
  final int serviceFee;
  final int dueDay;
  final bool cashPaymentEnabled;
  final String cashPaymentLocation;
  final bool bankTransferEnabled;
  final String bankName;
  final String bankAccountNumber;
  final int occupantCount;
  final String note;
  final LandlordLeaseStatus status;
}

class _LeaseEditor extends StatefulWidget {
  const _LeaseEditor({required this.lease, required this.occupiedRooms});
  final LandlordLease? lease;
  final Set<String> occupiedRooms;

  @override
  State<_LeaseEditor> createState() => _LeaseEditorState();
}

class _LeaseEditorState extends State<_LeaseEditor> {
  static const _allRooms = [
    'A.101',
    'A.102',
    'A.103',
    'A.201',
    'A.202',
    'A.203',
    'A.302',
    'B.102',
    'B.105',
    'B.201',
  ];
  final _formKey = GlobalKey<FormState>();
  late final _landlordName = TextEditingController(
    text:
        widget.lease?.landlordName ??
        LandlordDemoStore.instance.property.ownerName,
  );
  late final _landlordAddress = TextEditingController(
    text: widget.lease?.landlordPermanentAddress ?? '',
  );
  late final _landlordId = TextEditingController(
    text: widget.lease?.landlordCitizenId ?? '',
  );
  late final _landlordContact = TextEditingController(
    text:
        widget.lease?.landlordContact ??
        LandlordDemoStore.instance.property.phone,
  );
  late final _name = TextEditingController(
    text: widget.lease?.tenantName ?? '',
  );
  late final _birthYear = TextEditingController(
    text: widget.lease?.tenantBirthYear ?? '',
  );
  late final _tenantId = TextEditingController(
    text: widget.lease?.tenantCitizenId ?? '',
  );
  late final _tenantAddress = TextEditingController(
    text: widget.lease?.tenantPermanentAddress ?? '',
  );
  late final _phone = TextEditingController(text: widget.lease?.phone ?? '');
  late final _rent = TextEditingController(
    text: widget.lease?.monthlyRent.toString() ?? '3000000',
  );
  late final _deposit = TextEditingController(
    text: widget.lease?.deposit.toString() ?? '3000000',
  );
  late final _termMonths = TextEditingController(
    text: widget.lease?.termMonths.toString() ?? '12',
  );
  late final _electricity = TextEditingController(
    text: widget.lease?.electricityPrice.toString() ?? '3500',
  );
  late final _water = TextEditingController(
    text: widget.lease?.waterPrice.toString() ?? '15000',
  );
  late final _vehicle = TextEditingController(
    text: widget.lease?.vehicleFee.toString() ?? '80000',
  );
  late final _service = TextEditingController(
    text: widget.lease?.serviceFee.toString() ?? '100000',
  );
  late final _dueDay = TextEditingController(
    text: widget.lease?.dueDay.toString() ?? '10',
  );
  late final _cashLocation = TextEditingController(
    text:
        widget.lease?.cashPaymentLocation ??
        LandlordDemoStore.instance.property.address,
  );
  late final _bankName = TextEditingController(
    text:
        widget.lease?.bankName ??
        LandlordDemoStore.instance.defaultPaymentAccount?.bankName ??
        '',
  );
  late final _bankAccount = TextEditingController(
    text:
        widget.lease?.bankAccountNumber ??
        LandlordDemoStore.instance.defaultPaymentAccount?.accountNumber ??
        '',
  );
  late final _occupants = TextEditingController(
    text: widget.lease?.occupantCount.toString() ?? '1',
  );
  late final _note = TextEditingController(text: widget.lease?.note ?? '');
  late String _room = widget.lease?.room ?? _firstAvailableRoom;
  late DateTime _start = widget.lease?.startDate ?? DateTime.now();
  late DateTime _end =
      widget.lease?.endDate ??
      DateTime(
        DateTime.now().year + 1,
        DateTime.now().month,
        DateTime.now().day,
      );
  late LandlordLeaseStatus _status =
      widget.lease?.status ?? LandlordLeaseStatus.active;
  late String _waterType = widget.lease?.waterType ?? 'Theo m³';
  late DateTime? _tenantIssueDate = widget.lease?.tenantCitizenIssueDate;
  late bool _cashEnabled = widget.lease?.cashPaymentEnabled ?? true;
  late bool _bankEnabled = widget.lease?.bankTransferEnabled ?? true;

  String get _firstAvailableRoom => _allRooms.firstWhere(
    (room) => !widget.occupiedRooms.contains(room),
    orElse: () => _allRooms.first,
  );

  @override
  void dispose() {
    _landlordName.dispose();
    _landlordAddress.dispose();
    _landlordId.dispose();
    _landlordContact.dispose();
    _name.dispose();
    _birthYear.dispose();
    _tenantId.dispose();
    _tenantAddress.dispose();
    _phone.dispose();
    _rent.dispose();
    _deposit.dispose();
    _termMonths.dispose();
    _electricity.dispose();
    _water.dispose();
    _vehicle.dispose();
    _service.dispose();
    _dueDay.dispose();
    _cashLocation.dispose();
    _bankName.dispose();
    _bankAccount.dispose();
    _occupants.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableRooms = _allRooms
        .where(
          (room) =>
              !widget.occupiedRooms.contains(room) ||
              room == widget.lease?.room,
        )
        .toList();
    if (!availableRooms.contains(_room) && availableRooms.isNotEmpty) {
      _room = availableRooms.first;
    }
    return AlertDialog(
      title: Text(
        widget.lease == null ? 'Tạo hợp đồng thuê phòng' : 'Chỉnh sửa hợp đồng',
      ),
      content: SizedBox(
        width: 540,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _room,
                  decoration: const InputDecoration(labelText: 'Phòng'),
                  items: [
                    for (final room in availableRooms)
                      DropdownMenuItem(value: room, child: Text('Phòng $room')),
                  ],
                  onChanged: (value) => setState(() => _room = value ?? _room),
                ),
                _sectionTitle('BÊN A · BÊN CHO THUÊ PHÒNG'),
                _textField(
                  _landlordName,
                  'Họ tên bên A',
                  validator: _requiredValidator('Nhập họ tên bên A.'),
                  capitalization: TextCapitalization.words,
                ),
                _textField(
                  _landlordAddress,
                  'Địa chỉ thường trú',
                  validator: _requiredValidator(
                    'Nhập địa chỉ thường trú bên A.',
                  ),
                ),
                _textField(
                  _landlordId,
                  'CCCD bên A',
                  keyboardType: TextInputType.number,
                  validator: _citizenIdValidator,
                ),
                _textField(
                  _landlordContact,
                  'Điện thoại / Zalo bên A',
                  keyboardType: TextInputType.phone,
                  validator: _phoneValidator,
                ),
                _sectionTitle('BÊN B · BÊN THUÊ PHÒNG'),
                _textField(
                  _name,
                  'Họ tên bên B',
                  validator: _requiredValidator('Nhập họ tên bên B.'),
                  capitalization: TextCapitalization.words,
                ),
                _textField(
                  _birthYear,
                  'Năm sinh',
                  keyboardType: TextInputType.number,
                  validator: _birthYearValidator,
                ),
                _textField(
                  _tenantId,
                  'CCCD bên B',
                  keyboardType: TextInputType.number,
                  validator: _citizenIdValidator,
                ),
                _dateField(
                  'Ngày cấp CCCD',
                  _tenantIssueDate,
                  (date) => setState(() => _tenantIssueDate = date),
                  lastDate: DateTime.now(),
                ),
                _textField(
                  _phone,
                  'Điện thoại / Zalo bên B',
                  keyboardType: TextInputType.phone,
                  validator: _phoneValidator,
                ),
                _textField(
                  _tenantAddress,
                  'Địa chỉ thường trú',
                  validator: _requiredValidator(
                    'Nhập địa chỉ thường trú bên B.',
                  ),
                ),
                _sectionTitle('PHÒNG VÀ CÁC KHOẢN TIỀN'),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        _rent,
                        'Giá phòng / tháng',
                        keyboardType: TextInputType.number,
                        validator: _positiveAmountValidator,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _textField(
                        _deposit,
                        'Tiền đặt cọc',
                        keyboardType: TextInputType.number,
                        validator: _nonNegativeAmountValidator,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        _electricity,
                        'Tiền điện / kWh',
                        keyboardType: TextInputType.number,
                        validator: _positiveAmountValidator,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _textField(
                        _water,
                        'Tiền nước',
                        keyboardType: TextInputType.number,
                        validator: _nonNegativeAmountValidator,
                      ),
                    ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  initialValue: _waterType,
                  decoration: const InputDecoration(
                    labelText: 'Cách tính tiền nước',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Theo m³', child: Text('Theo m³')),
                    DropdownMenuItem(
                      value: 'Theo tháng',
                      child: Text('Theo tháng'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _waterType = value ?? _waterType),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        _vehicle,
                        'Tiền xe / tháng',
                        keyboardType: TextInputType.number,
                        validator: _nonNegativeAmountValidator,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _textField(
                        _service,
                        'Tiền dịch vụ / tháng',
                        keyboardType: TextInputType.number,
                        validator: _nonNegativeAmountValidator,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        _dueDay,
                        'Ngày đóng tiền (1–31)',
                        keyboardType: TextInputType.number,
                        validator: _dueDayValidator,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _textField(
                        _occupants,
                        'Số người ở',
                        keyboardType: TextInputType.number,
                        validator: _occupantsValidator,
                      ),
                    ),
                  ],
                ),
                _sectionTitle('THỜI HẠN THUÊ'),
                _textField(
                  _termMonths,
                  'Thời hạn bên B thuê (tháng)',
                  keyboardType: TextInputType.number,
                  validator: _termMonthsValidator,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _dateField(
                        'Từ ngày',
                        _start,
                        (date) => setState(() => _start = date!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dateField(
                        'Đến ngày',
                        _end,
                        (date) => setState(() => _end = date!),
                      ),
                    ),
                  ],
                ),
                _sectionTitle('PHƯƠNG THỨC THANH TOÁN'),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _cashEnabled,
                  onChanged: (value) =>
                      setState(() => _cashEnabled = value ?? false),
                  title: const Text(
                    'Tiền mặt',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_cashEnabled)
                  _textField(
                    _cashLocation,
                    'Địa điểm nhận tiền mặt',
                    validator: _requiredValidator('Nhập nơi nhận tiền mặt.'),
                  ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _bankEnabled,
                  onChanged: (value) =>
                      setState(() => _bankEnabled = value ?? false),
                  title: const Text(
                    'Chuyển khoản ngân hàng',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_bankEnabled) ...[
                  _textField(
                    _bankName,
                    'Tên ngân hàng',
                    validator: _requiredValidator('Nhập tên ngân hàng.'),
                  ),
                  _textField(
                    _bankAccount,
                    'Số tài khoản',
                    keyboardType: TextInputType.number,
                    validator: _bankAccountValidator,
                  ),
                ],
                _sectionTitle('GHI CHÚ'),
                TextFormField(
                  controller: _note,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú thêm trong hợp đồng',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<LandlordLeaseStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái lưu',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: LandlordLeaseStatus.active,
                      child: Text('Đang hiệu lực'),
                    ),
                    DropdownMenuItem(
                      value: LandlordLeaseStatus.draft,
                      child: Text('Nháp'),
                    ),
                    DropdownMenuItem(
                      value: LandlordLeaseStatus.terminated,
                      child: Text('Đã kết thúc'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _status = value ?? _status),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(onPressed: _save, child: const Text('Lưu hợp đồng')),
      ],
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 15, bottom: 3),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: landlordBlue,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.45,
        ),
      ),
    ),
  );

  Widget _textField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextCapitalization capitalization = TextCapitalization.none,
  }) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      validator: validator,
      decoration: InputDecoration(labelText: label, isDense: true),
    ),
  );

  String? Function(String?) _requiredValidator(String message) =>
      (value) => value == null || value.trim().isEmpty ? message : null;

  String? _citizenIdValidator(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length == 9 || digits.length == 12
        ? null
        : 'CCCD cần có 9 hoặc 12 chữ số.';
  }

  String? _phoneValidator(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 9 && digits.length <= 12
        ? null
        : 'Nhập số điện thoại hợp lệ.';
  }

  String? _birthYearValidator(String? value) {
    final year = int.tryParse((value ?? '').trim());
    return year != null && year >= 1900 && year <= DateTime.now().year
        ? null
        : 'Nhập năm sinh hợp lệ.';
  }

  String? _positiveAmountValidator(String? value) {
    final amount = _parseInt(value);
    return amount != null && amount > 0 ? null : 'Số tiền phải lớn hơn 0.';
  }

  String? _nonNegativeAmountValidator(String? value) {
    final amount = _parseInt(value);
    return amount != null && amount >= 0 ? null : 'Nhập số tiền hợp lệ.';
  }

  String? _dueDayValidator(String? value) {
    final day = _parseInt(value);
    return day != null && day >= 1 && day <= 31
        ? null
        : 'Ngày đóng tiền từ 1 đến 31.';
  }

  String? _termMonthsValidator(String? value) {
    final months = _parseInt(value);
    return months != null && months >= 1 && months <= 120
        ? null
        : 'Thời hạn từ 1 đến 120 tháng.';
  }

  String? _occupantsValidator(String? value) {
    final count = _parseInt(value);
    return count != null && count >= 1 && count <= 30
        ? null
        : 'Số người ở từ 1 đến 30.';
  }

  String? _bankAccountValidator(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 6 && digits.length <= 20
        ? null
        : 'Số tài khoản cần có 6–20 chữ số.';
  }

  int? _parseInt(String? value) =>
      int.tryParse((value ?? '').replaceAll(RegExp(r'[^0-9]'), ''));

  Widget _dateField(
    String label,
    DateTime? date,
    ValueChanged<DateTime?> onChanged, {
    DateTime? lastDate,
  }) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? now,
          firstDate: DateTime(1900),
          lastDate: lastDate ?? DateTime(2035),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_month_outlined),
          isDense: true,
          errorText: date == null ? 'Chọn ngày cấp CCCD' : null,
        ),
        child: Text(
          date == null ? 'Chọn ngày' : landlordDate(date),
          style: TextStyle(color: date == null ? landlordMuted : landlordInk),
        ),
      ),
    ),
  );

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_tenantIssueDate == null) {
      showLandlordMessage(context, 'Chọn ngày cấp CCCD bên B.');
      return;
    }
    if (_end.isBefore(_start)) {
      showLandlordMessage(
        context,
        'Ngày kết thúc phải từ ngày bắt đầu trở đi.',
      );
      return;
    }
    if (!_cashEnabled && !_bankEnabled) {
      showLandlordMessage(context, 'Chọn ít nhất một phương thức thanh toán.');
      return;
    }
    Navigator.pop(
      context,
      _LeaseDraft(
        room: _room,
        landlordName: _landlordName.text,
        landlordPermanentAddress: _landlordAddress.text,
        landlordCitizenId: _landlordId.text.replaceAll(RegExp(r'[^0-9]'), ''),
        landlordContact: _landlordContact.text,
        tenantName: _name.text,
        tenantBirthYear: _birthYear.text,
        tenantCitizenId: _tenantId.text.replaceAll(RegExp(r'[^0-9]'), ''),
        tenantCitizenIssueDate: _tenantIssueDate,
        tenantPermanentAddress: _tenantAddress.text,
        phone: _phone.text,
        startDate: _start,
        endDate: _end,
        monthlyRent: _parseInt(_rent.text)!,
        deposit: _parseInt(_deposit.text)!,
        termMonths: _parseInt(_termMonths.text)!,
        electricityPrice: _parseInt(_electricity.text)!,
        waterPrice: _parseInt(_water.text)!,
        waterType: _waterType,
        vehicleFee: _parseInt(_vehicle.text)!,
        serviceFee: _parseInt(_service.text)!,
        dueDay: _parseInt(_dueDay.text)!,
        cashPaymentEnabled: _cashEnabled,
        cashPaymentLocation: _cashLocation.text,
        bankTransferEnabled: _bankEnabled,
        bankName: _bankName.text,
        bankAccountNumber: _bankAccount.text.replaceAll(RegExp(r'[^0-9]'), ''),
        occupantCount: _parseInt(_occupants.text)!,
        note: _note.text,
        status: _status,
      ),
    );
  }
}
