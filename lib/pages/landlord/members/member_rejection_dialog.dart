import 'package:flutter/material.dart';

class MemberRejectionDialog extends StatefulWidget {
  const MemberRejectionDialog({super.key});
  @override
  State<MemberRejectionDialog> createState() => MemberRejectionDialogState();
}

class MemberRejectionDialogState extends State<MemberRejectionDialog> {
  final _controllerLyDo = TextEditingController();
  final _khoaBieuMau = GlobalKey<FormState>();

  @override
  void dispose() {
    _controllerLyDo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Từ chối thành viên'),
      content: Form(
        key: _khoaBieuMau,
        child: TextFormField(
          controller: _controllerLyDo,
          decoration: const InputDecoration(labelText: 'Lý do từ chối'),
          validator: (giaTri) {
            if (giaTri == null || giaTri.trim().isEmpty) {
              return 'Nhập lý do từ chối.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            if (_khoaBieuMau.currentState!.validate()) {
              Navigator.pop(context, _controllerLyDo.text.trim());
            }
          },
          child: const Text('Từ chối'),
        ),
      ],
    );
  }
}
