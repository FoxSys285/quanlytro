import 'package:flutter/material.dart';

import 'layouts/admin_layout.dart';
import 'layouts/landlord_layout.dart';
import 'layouts/role_layout.dart';
import 'layouts/tenant_layout.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'An Cư',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF16836F),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          foregroundColor: Color(0xFF344252),
          iconTheme: IconThemeData(color: Color(0xFF344252)),
        ),
      ),
      home: const RoleLayoutPreview(),
    );
  }
}

/// Temporary preview switcher. Replace it with auth/role routing when those
/// flows are implemented; each role layout can be used independently.
class RoleLayoutPreview extends StatefulWidget {
  const RoleLayoutPreview({super.key});

  @override
  State<RoleLayoutPreview> createState() => _RoleLayoutPreviewState();
}

class _RoleLayoutPreviewState extends State<RoleLayoutPreview> {
  AppRole _role = AppRole.landlord;

  @override
  Widget build(BuildContext context) {
    void selectRole(AppRole role) => setState(() => _role = role);

    switch (_role) {
      case AppRole.tenant:
        return TenantLayout(onPreviewRoleSelected: selectRole);
      case AppRole.landlord:
        return LandlordLayout(onPreviewRoleSelected: selectRole);
      case AppRole.admin:
        return AdminLayout(onPreviewRoleSelected: selectRole);
    }
  }
}
