import 'package:flutter/material.dart';

const appName = 'TroPremium';
const appLogoAsset = 'assets/images/tropremium_logo.png';

/// Shared brand mark for authentication and the role navigation menus.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    appLogoAsset,
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    semanticLabel: 'Logo $appName',
  );
}
