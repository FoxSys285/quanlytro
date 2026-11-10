import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quanlytro/pages/landlord/properties/components/landlord_property_editor.dart';
import 'package:quanlytro/pages/landlord/properties/components/landlord_property_image.dart';
import 'package:quanlytro/pages/landlord/properties/models/landlord_property.dart';
import 'package:quanlytro/pages/landlord/properties/services/property_image_picker.dart';
import 'package:quanlytro/pages/tenant/discovery/services/tenant_administrative_service.dart';

const _property = LandlordProperty(
  id: 'may',
  name: 'Mây House',
  address: '25 Nguyễn Gia Trí',
  ownerName: 'Nguyễn Văn An',
  phone: '0900000000',
  description: 'Nhà trọ mẫu',
);

Future<Uint8List> _imageBytes(WidgetTester tester) async {
  return (await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(Colors.blue, BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(16, 16);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return data!.buffer.asUint8List();
  }))!;
}

Future<void> _showEditor(
  WidgetTester tester, {
  required LandlordProperty property,
  required Future<SelectedPropertyImage?> Function() pickImage,
  required void Function(LandlordProperty?) onClosed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await showDialog<LandlordProperty>(
                context: context,
                builder: (_) => LandlordPropertyEditor(
                  property: property,
                  pickImage: pickImage,
                  locationService: TenantAdministrativeService(
                    client: MockClient(
                      (request) async => http.Response(
                        request.url.path.endsWith('/p/')
                            ? '[{"code":79,"name":"TP. Hồ Chí Minh"}]'
                            : '{"wards":[{"code":1,"name":"Phường 25"}]}',
                        200,
                        headers: {'content-type': 'application/json; charset=utf-8'},
                      ),
                    ),
                  ),
                ),
              );
              onClosed(result);
            },
            child: const Text('Mở chỉnh sửa'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Mở chỉnh sửa'));
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets('Image preview, save, cancel and remove at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bytes = await _imageBytes(tester);
      LandlordProperty? saved;
      await _showEditor(
        tester,
        property: _property,
        pickImage: () async =>
            SelectedPropertyImage(bytes: bytes, name: 'may-house.png'),
        onClosed: (value) => saved = value,
      );
      expect(find.text('Đường dẫn ảnh'), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(7));
      await tester.tap(find.text('Chọn ảnh'));
      await tester.pumpAndSettle();
      expect(find.text('may-house.png'), findsOneWidget);
      final preview = tester.widget<LandlordPropertyImage>(
        find.byType(LandlordPropertyImage),
      );
      expect(preview.bytes, bytes);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
      expect(_property.imageBytes, isNull);

      await tester.tap(find.text('Mở chỉnh sửa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn ảnh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text('Chọn tỉnh / thành phố từ danh sách.'), findsNothing);
      expect(find.text('Chọn xã / phường từ danh sách.'), findsNothing);
      expect(saved!.imageBytes, bytes);
      expect(saved!.imageName, 'may-house.png');
      expect(saved!.imageUrl, isEmpty);

      await _showEditor(
        tester,
        property: saved!,
        pickImage: () async => null,
        onClosed: (value) => saved = value,
      );
      expect(find.text('Đổi ảnh'), findsOneWidget);
      await tester.tap(find.text('Bỏ ảnh'));
      await tester.pumpAndSettle();
      expect(find.text('Chọn ảnh'), findsOneWidget);
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(saved!.imageBytes, isNull);
      expect(saved!.imageName, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Picker cancellation and errors preserve existing image', (
    tester,
  ) async {
    final bytes = await _imageBytes(tester);
    final property = LandlordProperty(
      id: _property.id,
      name: _property.name,
      address: _property.address,
      ownerName: _property.ownerName,
      phone: _property.phone,
      description: _property.description,
      imageBytes: bytes,
      imageName: 'anh-cu.png',
    );
    var attempts = 0;
    LandlordProperty? saved;
    await _showEditor(
      tester,
      property: property,
      pickImage: () async {
        if (attempts++ == 0) return null;
        throw const FormatException('Chọn ảnh có dung lượng tối đa 10 MB.');
      },
      onClosed: (value) => saved = value,
    );
    await tester.tap(find.text('Đổi ảnh'));
    await tester.pumpAndSettle();
    expect(find.text('anh-cu.png'), findsOneWidget);
    await tester.tap(find.text('Đổi ảnh'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn ảnh có dung lượng tối đa 10 MB.'), findsOneWidget);
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(saved!.imageBytes, bytes);
    expect(saved!.imageName, 'anh-cu.png');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Property coordinates require a valid pair and survive a save', (
    tester,
  ) async {
    LandlordProperty? saved;
    await _showEditor(
      tester,
      property: _property,
      pickImage: () async => null,
      onClosed: (value) => saved = value,
    );
    final latitude = find.byKey(const ValueKey('property-latitude'));
    final longitude = find.byKey(const ValueKey('property-longitude'));
    await tester.ensureVisible(latitude);
    await tester.enterText(latitude, '91');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    expect(find.text('Vĩ độ phải từ -90 đến 90.'), findsOneWidget);
    expect(find.text('Nhập đủ vĩ độ và kinh độ.'), findsOneWidget);

    await tester.enterText(latitude, '10,812345');
    await tester.enterText(longitude, '106.654321');
    expect(
      tester.widget<TextFormField>(latitude).controller!.text,
      '10,812345',
    );
    expect(
      tester.widget<TextFormField>(longitude).controller!.text,
      '106.654321',
    );
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(
      tester
          .stateList<FormFieldState<String>>(find.byType(TextFormField))
          .map((field) => field.errorText)
          .whereType<String>()
          .toList(),
      isEmpty,
    );
    expect(saved?.latitude, 10.812345);
    expect(saved?.longitude, 106.654321);
    final restored = LandlordProperty.fromMap(saved!.toMap());
    expect(restored.latitude, 10.812345);
    expect(restored.longitude, 106.654321);
  });
}
