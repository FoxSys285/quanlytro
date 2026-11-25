import 'package:flutter/material.dart';

import '../../../data/app_persistence.dart';
import '../../../data/local_auth.dart';
import '../landlord_theme.dart';

import '../landlord_glass.dart';
import '../landlord_ui.dart';
import '../landlord_demo_store.dart';
import 'models/landlord_dichvu.dart';

// Tên Class chính bằng tiếng Việt
class LandlordDichVuBangGiaPage extends StatefulWidget {
  const LandlordDichVuBangGiaPage({super.key});

  @override
  State<LandlordDichVuBangGiaPage> createState() =>
      _LandlordDichVuBangGiaPageState();
}

class _LandlordDichVuBangGiaPageState extends State<LandlordDichVuBangGiaPage> {
  // 1. DỮ KIỆN (Kho lưu trữ và biến trạng thái đưa lên đầu)
  final _store = LandlordDemoStore.activeInstance;

  bool _isUtilityRate(LandlordService service) =>
      service.id == 'electricity' || service.id == 'water';

  List<LandlordService> get _danhSachTienIch =>
      _store.services.where(_isUtilityRate).toList()..sort((a, b) {
        if (a.id == b.id) return 0;
        return a.id == 'electricity' ? -1 : 1;
      });

  List<LandlordService> get _danhSachDichVu =>
      _store.services.where((service) => !_isUtilityRate(service)).toList();

  // 2. VÒNG ĐỜI VÀ LẮNG NGHE DỮ LIỆU
  @override
  void initState() {
    super.initState();
    _store.addListener(_capNhat);
  }

  void _capNhat() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _store.removeListener(_capNhat);
    super.dispose();
  }

  // 3. CÁC HÀM XỬ LÝ (Viết trước hàm build)
  // Hàm chọn icon tương ứng với tên dịch vụ
  IconData _layIconDichVu(String tenDichVu) {
    final tenVietThuong = tenDichVu.toLowerCase();
    if (tenVietThuong.contains('điện')) {
      return Icons.bolt_outlined;
    } else if (tenVietThuong.contains('nước')) {
      return Icons.water_drop_outlined;
    } else if (tenVietThuong.contains('internet') ||
        tenVietThuong.contains('wifi')) {
      return Icons.wifi_rounded;
    } else if (tenVietThuong.contains('xe')) {
      return Icons.two_wheeler_outlined;
    } else {
      return Icons.room_service_outlined;
    }
  }

  Future<void> _moFormGiaTienIch(LandlordService service) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ServiceEditorDialog(
        service: service,
        utilityRate: true,
        onSave: (name, unit, basis, price) async {
          _store.saveService(
            existing: service,
            name: name,
            unit: unit,
            basis: basis,
            price: price,
          );
          await _flushServiceChanges();
        },
      ),
    );
    if (saved != true || !mounted) return;
    showLandlordMessage(
      context,
      'Đã cập nhật ${service.id == 'electricity' ? 'tiền điện' : 'tiền nước'}.',
    );
  }

  Future<void> _moFormDichVu({LandlordService? dichVuCanSua}) async {
    var stagedService = dichVuCanSua;
    var deleted = false;
    final originalRoomTypes = {
      for (final type in _store.roomTypes) type.id: type,
    };
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ServiceEditorDialog(
        service: dichVuCanSua,
        onSave: (name, unit, basis, price) async {
          stagedService = _store.saveService(
            existing: stagedService,
            name: name,
            unit: unit,
            basis: basis,
            price: price,
          );
          await _flushServiceChanges();
        },
        onDelete: dichVuCanSua == null
            ? null
            : () async {
                _store.deleteService(dichVuCanSua);
                try {
                  await _flushServiceChanges();
                  deleted = true;
                } catch (_) {
                  _store.restoreDeletedService(
                    dichVuCanSua,
                    roomTypes: originalRoomTypes,
                  );
                  rethrow;
                }
              },
      ),
    );
    if (saved != true || !mounted) return;
    showLandlordMessage(
      context,
      deleted ? 'Đã xóa dịch vụ.' : 'Đã lưu dịch vụ ${stagedService!.name}.',
    );
  }

  Future<void> _flushServiceChanges() async {
    final persistence = AppPersistence.current;
    if (persistence == null && LocalAuth.instance.isCloudMode) {
      throw StateError('Chưa kết nối phiên lưu Firebase.');
    }
    await persistence?.flush();
  }

  // 4. HÀM BUILD ĐẶT Ở DƯỚI CÙNG
  @override
  Widget build(BuildContext context) {
    return LandlordFeaturePage(
      title: 'Dịch vụ & Bảng giá',
      subtitle: 'Cấu hình đơn giá điện, nước và dịch vụ của nhà trọ.',
      icon: Icons.price_change_outlined,
      children: [
        LandlordGlassSection(
          title: 'Bảng giá điện nước',
          subtitle: 'Hai khoản phí cơ bản luôn có sẵn và không thể xóa.',
        ),
        for (final dichVu in _danhSachTienIch)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LandlordGlassCard(
              onTap: () => _moFormGiaTienIch(dichVu),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4EFFF),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      _layIconDichVu(dichVu.name),
                      color: landlordBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dichVu.id == 'electricity'
                              ? 'Tiền điện'
                              : 'Tiền nước',
                          style: TextStyle(
                            color: LandlordPalette.of(context).ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatLandlordMoney(dichVu.price)} / ${dichVu.unit} · ${dichVu.basis}',
                          style: TextStyle(
                            color: LandlordPalette.of(context).muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip:
                        'Chỉnh sửa ${dichVu.id == 'electricity' ? 'tiền điện' : 'tiền nước'}',
                    onPressed: () => _moFormGiaTienIch(dichVu),
                    icon: const Icon(Icons.edit_outlined),
                    color: landlordBlue,
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        LandlordGlassSection(
          title: 'Dịch vụ khác',
          subtitle: '${_danhSachDichVu.length} dịch vụ đang được quản lý.',
          trailing: FilledButton.icon(
            onPressed: () => _moFormDichVu(),
            style: FilledButton.styleFrom(
              backgroundColor: landlordBlue,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Thêm dịch vụ'),
          ),
        ),
        if (_danhSachDichVu.isEmpty)
          const LandlordGlassCard(
            child: Center(child: Text('Chưa có dịch vụ khác.')),
          ),
        for (final dichVu in _danhSachDichVu)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LandlordGlassCard(
              onTap: () => _moFormDichVu(dichVuCanSua: dichVu),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4EFFF),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      _layIconDichVu(dichVu.name),
                      color: landlordBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dichVu.name,
                          style: TextStyle(
                            color: LandlordPalette.of(context).ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatLandlordMoney(dichVu.price)} / ${dichVu.unit} · ${dichVu.basis}',
                          style: TextStyle(
                            color: LandlordPalette.of(context).muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: dichVu.active,
                    activeThumbColor: landlordBlue,
                    onChanged: (giaTriKichHoat) {
                      _store.setServiceActive(dichVu, giaTriKichHoat);
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ServiceEditorDialog extends StatefulWidget {
  const _ServiceEditorDialog({
    required this.service,
    required this.onSave,
    this.onDelete,
    this.utilityRate = false,
  });

  final LandlordService? service;
  final Future<void> Function(String name, String unit, String basis, int price)
  onSave;
  final Future<void> Function()? onDelete;
  final bool utilityRate;

  @override
  State<_ServiceEditorDialog> createState() => _ServiceEditorDialogState();
}

class _ServiceEditorDialogState extends State<_ServiceEditorDialog> {
  static const _bases = [
    'Theo chỉ số',
    'Theo phòng',
    'Theo người',
    'Theo cái / xe',
    'Cố định',
  ];
  static const _templates = [
    ('Internet', 'phòng', '100000', 'Theo phòng'),
    ('Gửi xe máy', 'cái', '80000', 'Theo cái / xe'),
    ('Vệ sinh', 'người', '20000', 'Theo người'),
  ];

  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.service?.name ?? '');
  late final _unit = TextEditingController(text: widget.service?.unit ?? '');
  late final _price = TextEditingController(
    text: widget.service?.price.toString() ?? '',
  );
  late String _basis = _bases.contains(widget.service?.basis)
      ? widget.service!.basis
      : _bases.first;
  late String _utilityUnit =
      widget.service?.unit.toLowerCase().contains('người') == true
      ? 'người'
      : 'm³';
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final isElectricity = widget.service?.id == 'electricity';
      final name = widget.utilityRate
          ? widget.service!.name
          : _name.text.trim();
      final unit = widget.utilityRate
          ? (isElectricity ? widget.service!.unit : _utilityUnit)
          : _unit.text.trim();
      final basis = widget.utilityRate
          ? (isElectricity || _utilityUnit == 'm³'
                ? 'Theo chỉ số'
                : 'Theo người')
          : _basis;
      await widget.onSave(name, unit, basis, int.parse(_price.text.trim()));
      if (mounted) Navigator.of(context).pop(true);
    } catch (failure) {
      if (mounted) {
        setState(() {
          _error = switch (failure) {
            ArgumentError(:final message) => message.toString(),
            StateError(:final message) => message.toString(),
            _ => 'Không lưu được dịch vụ. Vui lòng thử lại.',
          };
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final onDelete = widget.onDelete;
    if (_saving || onDelete == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await onDelete();
      if (mounted) Navigator.of(context).pop(true);
    } catch (failure) {
      if (mounted) {
        setState(() {
          _error = AppPersistence.saveFailureMessage(failure);
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final isElectricity = service?.id == 'electricity';
    final title = widget.utilityRate
        ? (isElectricity ? 'Bảng giá tiền điện' : 'Bảng giá tiền nước')
        : service == null
        ? 'Thêm dịch vụ'
        : 'Sửa dịch vụ';
    return LandlordFormDialog(
      canClose: !_saving,
      title: title,
      subtitle: widget.utilityRate
          ? (isElectricity
                ? 'Cập nhật đơn giá điện áp dụng cho kWh tiêu thụ.'
                : 'Cập nhật đơn giá và cách tính tiền nước.')
          : 'Thiết lập đơn giá và cách tính dịch vụ.',
      icon: widget.utilityRate
          ? (isElectricity ? Icons.bolt_outlined : Icons.water_drop_outlined)
          : Icons.price_change_outlined,
      footer: Row(
        children: [
          if (widget.onDelete != null)
            Expanded(
              child: TextButton.icon(
                onPressed: _saving ? null : _delete,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD64545),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Xóa'),
              ),
            )
          else
            const Spacer(),
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          const SizedBox(width: 7),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: landlordBlue,
              foregroundColor: Colors.white,
            ),
            icon: _saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: 17),
            label: Text(_saving ? 'Đang lưu...' : 'Lưu'),
          ),
        ],
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.utilityRate && service == null) ...[
              const Text('Chọn mẫu nhanh:'),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final template in _templates)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(template.$1),
                          selected: _name.text == template.$1,
                          onSelected: _saving
                              ? null
                              : (_) {
                                  setState(() {
                                    _name.text = template.$1;
                                    _unit.text = template.$2;
                                    _price.text = template.$3;
                                    _basis = template.$4;
                                  });
                                },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (!widget.utilityRate)
              TextFormField(
                controller: _name,
                enabled: !_saving,
                decoration: landlordModernInputDecoration('Tên dịch vụ'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Nhập tên dịch vụ.' : null,
              ),
            if (!widget.utilityRate) const SizedBox(height: 8),
            if (!widget.utilityRate)
              TextFormField(
                controller: _unit,
                enabled: !_saving,
                decoration: landlordModernInputDecoration(
                  'Đơn vị',
                  hintText: 'kWh, m³, cái, phòng...',
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Nhập đơn vị dịch vụ.'
                    : null,
              ),
            if (!widget.utilityRate) const SizedBox(height: 8),
            TextFormField(
              controller: _price,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: landlordModernInputDecoration(
                widget.utilityRate
                    ? (isElectricity
                          ? 'Đơn giá điện (đ/kWh)'
                          : 'Đơn giá nước (đ)')
                    : 'Đơn giá (đ)',
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
              validator: (value) {
                final price = int.tryParse((value ?? '').trim());
                return price == null || price < 0
                    ? 'Nhập đơn giá là số nguyên không âm.'
                    : null;
              },
            ),
            if (widget.utilityRate && !isElectricity) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                key: ValueKey(_utilityUnit),
                initialValue: _utilityUnit,
                isExpanded: true,
                decoration: landlordModernInputDecoration('Đơn vị tính'),
                items: const [
                  DropdownMenuItem(value: 'm³', child: Text('m³')),
                  DropdownMenuItem(value: 'người', child: Text('người')),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _utilityUnit = value);
                        }
                      },
              ),
            ],
            if (!widget.utilityRate) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                key: ValueKey(_basis),
                initialValue: _basis,
                isExpanded: true,
                decoration: landlordModernInputDecoration('Cách tính'),
                items: [
                  for (final basis in _bases)
                    DropdownMenuItem(value: basis, child: Text(basis)),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _basis = value);
                      },
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
