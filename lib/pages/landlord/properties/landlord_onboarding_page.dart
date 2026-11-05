import 'package:flutter/material.dart';

import '../../../data/app_persistence.dart';
import '../../../data/local_auth.dart';
import '../landlord_demo_store.dart';
import 'models/landlord_property.dart';

class LandlordOnboardingPage extends StatelessWidget {
  const LandlordOnboardingPage({
    super.key,
    this.onLogout,
    this.loading = false,
    this.loadFailed = false,
    this.onRetry,
  });

  final VoidCallback? onLogout;
  final bool loading;
  final bool loadFailed;
  final VoidCallback? onRetry;

  Future<void> _createProperty(BuildContext context) async {
    final draft =
        await showDialog<
          ({LandlordProperty property, int floors, int roomsPerFloor})
        >(context: context, builder: (_) => const _CreatePropertyDialog());
    if (draft == null || !context.mounted) return;
    try {
      RentalPortfolio.instance.add(
        draft.property,
        floors: draft.floors,
        roomsPerFloor: draft.roomsPerFloor,
      );
      await AppPersistence.current?.flush();
      if (!context.mounted) return;
      if (AppPersistence.current?.error.value != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã tạo hồ sơ nhà trọ trên màn hình nhưng chưa đồng bộ được. Hãy bấm Thử lưu lại ở đầu ứng dụng.',
            ),
          ),
        );
      }
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message.toString())));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa tạo được nhà trọ. Kiểm tra kết nối rồi thử lại.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),
    appBar: AppBar(
      title: const Text('Thiết lập tài khoản chủ trọ'),
      actions: [
        if (onLogout != null)
          TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Đăng xuất'),
          ),
      ],
    ),
    body: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 34,
                        child: Icon(Icons.apartment_rounded, size: 34),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        loading
                            ? 'Đang tải dữ liệu nhà trọ'
                            : loadFailed
                            ? 'Chưa tải được dữ liệu Firebase'
                            : 'Tạo hồ sơ nhà trọ đầu tiên',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        loading
                            ? 'Đang kiểm tra các nhà trọ đã được gán cho tài khoản.'
                            : loadFailed
                            ? 'Cần tải dữ liệu trước khi tạo nhà mới để tránh ghi đè thay đổi khác. Kiểm tra kết nối và thử lại.'
                            : 'Tài khoản này chưa được gán nhà trọ. Thông tin bạn tạo sẽ được lưu lên Firebase và dùng chung cho các chức năng phòng, hợp đồng, hóa đơn và người thuê.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          height: 1.55,
                          color: Color(0xFF667585),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (loading)
                        const CircularProgressIndicator()
                      else if (loadFailed)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Thử tải lại'),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _createProperty(context),
                            icon: const Icon(Icons.add_home_work_outlined),
                            label: const Text('Tạo nhà trọ'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CreatePropertyDialog extends StatefulWidget {
  const _CreatePropertyDialog();

  @override
  State<_CreatePropertyDialog> createState() => _CreatePropertyDialogState();
}

class _CreatePropertyDialogState extends State<_CreatePropertyDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _ward = TextEditingController();
  final _city = TextEditingController(text: 'TP. Hồ Chí Minh');
  final _owner = TextEditingController(
    text: LocalAuth.instance.session?.displayName ?? '',
  );
  final _phone = TextEditingController(
    text: LocalAuth.instance.session?.phoneIsSynthetic == true
        ? ''
        : LocalAuth.instance.session?.phoneNumber ?? '',
  );
  final _description = TextEditingController();
  final _floors = TextEditingController(text: '1');
  final _roomsPerFloor = TextEditingController(text: '1');

  @override
  void dispose() {
    for (final controller in [
      _name,
      _address,
      _ward,
      _city,
      _owner,
      _phone,
      _description,
      _floors,
      _roomsPerFloor,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'Trường này không được để trống.' : null;

  String? _count(String? value, int maximum) {
    final number = int.tryParse((value ?? '').trim());
    return number == null || number < 1 || number > maximum
        ? 'Nhập số từ 1 đến $maximum.'
        : null;
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final phone = _phone.text.replaceAll(RegExp(r'[^0-9+]'), '');
    if (!RegExp(r'^(\+?[0-9]{9,15})$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập số điện thoại hợp lệ.')),
      );
      return;
    }
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    Navigator.pop(context, (
      property: LandlordProperty(
        id: 'p-$now',
        name: _name.text.trim(),
        address: _address.text.trim(),
        ownerName: _owner.text.trim(),
        phone: phone,
        description: _description.text.trim(),
        city: _city.text.trim(),
        ward: _ward.text.trim(),
      ),
      floors: int.parse(_floors.text),
      roomsPerFloor: int.parse(_roomsPerFloor.text),
    ));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Thông tin nhà trọ'),
    content: SizedBox(
      width: 520,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_name, 'Tên nhà trọ'),
              _field(_address, 'Địa chỉ'),
              _field(_ward, 'Phường / xã'),
              _field(_city, 'Tỉnh / thành phố'),
              _field(_owner, 'Họ tên chủ trọ'),
              _field(
                _phone,
                'Số điện thoại',
                keyboardType: TextInputType.phone,
              ),
              _field(
                _description,
                'Giới thiệu nhà trọ',
                maxLines: 3,
                validator: (value) => (value ?? '').trim().length < 20
                    ? 'Giới thiệu cần ít nhất 20 ký tự.'
                    : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _floors,
                      'Số tầng',
                      keyboardType: TextInputType.number,
                      validator: (value) => _count(value, 30),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      _roomsPerFloor,
                      'Phòng mỗi tầng',
                      keyboardType: TextInputType.number,
                      validator: (value) => _count(value, 50),
                    ),
                  ),
                ],
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
      FilledButton.icon(
        onPressed: _submit,
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text('Tạo và đồng bộ'),
      ),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator ?? _required,
      decoration: InputDecoration(labelText: label),
    ),
  );
}
