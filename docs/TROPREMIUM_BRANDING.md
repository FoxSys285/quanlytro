# TroPremium branding

The display name is **TroPremium** on Android, web and Windows. The Dart package,
Android application ID and database filenames retain their existing identifiers
so installed application data and Firebase configuration remain compatible.

The supplied TP / house / key badge was extracted using the built-in imagegen
tool with a transparent exterior. Source: `assets/branding/tropremium_master.png`.
Flutter uses `assets/images/tropremium_logo.png` on the login screen and in all
role navigation drawers. Android also shows the logo on its launch screen.

Regenerate the platform sizes on Windows with no extra dependencies:

```powershell
./tool/prepare_brand_assets.ps1
```

The script uses System.Drawing to trim the outer 24 pixels, resize the extracted
master, and export Android density variants, web icons, and the Windows ICO.
Adaptive Android icons use a 54dp badge inside the central 66dp safe circle of a 108dp foreground;
maskable web icons use a solid green background and a centered safe margin.

Imagegen edit prompt:

> Use case: background-extraction. Edit target: the supplied TroPremium logo image.
> Prepare a production square app logo PNG: crop away all excessive white canvas
> and remove ONLY the exterior white background outside the green rounded-square
> badge to actual alpha transparency. Keep the entire original green rounded-square
> badge, its double light-green border, exact TP letterforms, roof, four window
> squares, key shape, colors, gradients, proportions and shadows unchanged. Center
> the intact badge in a square canvas, occupying 96 percent of the canvas width and
> height with a very small even transparent safety margin. Preserve the white and
> pale green artwork INSIDE the badge. No new lettering, no redesign, no
> embellishments. This is faithful extraction/cropping of the supplied logo for
> Android launcher and in-app logo assets.
