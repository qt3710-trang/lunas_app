# LUNAS branding

## Local source artwork

- `lunas_logo.png`: official unchanged logo for Intro/Login and icon source.
  https://res.cloudinary.com/f7blqtfj/image/upload/v1793526207/b753f703-6152-43f1-b9bf-8f4663d41937.png
- `lunas_splash_logo.png`: official unchanged transparent splash logo.
  https://res.cloudinary.com/f7blqtfj/image/upload/v1793527803/ta%CC%81ch_ne%CC%82%CC%80n.png
- `lunas_app_icon.png`: centered 1090px crop of the original 1254px square,
  removing only outer background margins. The colored mark is not cropped.
  Visual enlargement is 1254 / 1090 = 15.05% at the same launcher icon size.
- `lunas_splash_mark.png`: transparent source with empty alpha margins trimmed,
  centered on a square canvas with 16px padding, without distorting the logo.
- The old `lunas_splash.png` artwork is retained but no longer configured or
  bundled as a Flutter asset. It is not used by native splash resources.

Both supplied logo images contain the symbol without lettering. Intro does not
invent extra LUNAS text. Flutter uses `Image.asset` with `BoxFit.contain`; the
Login logo increases from 148 to 177.6 logical pixels (+20%). Intro uses 260px
and scrolls on short screens. Existing copy, buttons and navigation are kept.

## Native generation

Images are resampled with macOS CoreGraphics, the same method as the initial
branding update. No launcher/splash dependency or initialization delay is added.
All images are local and require no Cloudinary connection at runtime.

- Android legacy icon sizes: 48/72/96/144/192px.
- Android adaptive icon: 108dp transparent foreground canvas containing the
  cropped icon at 60dp. Its colored mark remains inside the 66dp safe circle.
  Background #FDF9F5 comes from the original logo.
- Android before API 31: transparent splash logo centered at 280dp.
- Android API 31+: transparent 288dp canvas; normalized logo is about 175.58dp
  wide. The furthest nontransparent pixel is within a 90dp radius, leaving 6dp
  inside the system's 192dp circular mask. It is much larger than the old logo
  contained within the decorative square. Light/dark launch themes agree.
- Native splash background is exactly #FBF6F2 (`AppColors.cream`, the existing
  Intro/scaffold color), including the iOS launch storyboard.
- iOS LunasAppIcon catalog retains its 19 size/scale entries, with opaque
  App Store artwork. LunasSplash contains transparent 280/560/840px images.
- Display name is exactly `LUNAS HAIR STUDIO` on both platforms; package ID,
  bundle ID, Dart project name, Firebase settings and business logic are kept.

Android 12+ restricts splash images to the OS icon area, so the splash mark is
smaller than the iOS/pre-12 version. No Flutter waiting screen is added.
Launchers may abbreviate the long display name. Native changes require rebuild
and reinstall rather than hot reload. Full Xcode and working iOS Firebase
configuration are required for iOS runtime checks; neither is changed here.

## Files changed in this refinement

Relative to the uncommitted branding state at the start of this task.

Modified:

```text
android/app/src/main/AndroidManifest.xml
android/app/src/main/res/drawable-hdpi/lunas_splash_android12.png
android/app/src/main/res/drawable-hdpi/lunas_splash_artwork.png
android/app/src/main/res/drawable-mdpi/lunas_splash_android12.png
android/app/src/main/res/drawable-mdpi/lunas_splash_artwork.png
android/app/src/main/res/drawable-v21/launch_background.xml
android/app/src/main/res/drawable-xhdpi/lunas_splash_android12.png
android/app/src/main/res/drawable-xhdpi/lunas_splash_artwork.png
android/app/src/main/res/drawable-xxhdpi/lunas_splash_android12.png
android/app/src/main/res/drawable-xxhdpi/lunas_splash_artwork.png
android/app/src/main/res/drawable-xxxhdpi/lunas_splash_android12.png
android/app/src/main/res/drawable-xxxhdpi/lunas_splash_artwork.png
android/app/src/main/res/drawable/launch_background.xml
android/app/src/main/res/mipmap-hdpi/lunas_launcher.png
android/app/src/main/res/mipmap-hdpi/lunas_launcher_foreground.png
android/app/src/main/res/mipmap-mdpi/lunas_launcher.png
android/app/src/main/res/mipmap-mdpi/lunas_launcher_foreground.png
android/app/src/main/res/mipmap-xhdpi/lunas_launcher.png
android/app/src/main/res/mipmap-xhdpi/lunas_launcher_foreground.png
android/app/src/main/res/mipmap-xxhdpi/lunas_launcher.png
android/app/src/main/res/mipmap-xxhdpi/lunas_launcher_foreground.png
android/app/src/main/res/mipmap-xxxhdpi/lunas_launcher.png
android/app/src/main/res/mipmap-xxxhdpi/lunas_launcher_foreground.png
android/app/src/main/res/values-night-v31/styles.xml
android/app/src/main/res/values-v31/styles.xml
android/app/src/main/res/values/lunas_branding.xml
assets/branding/README.md
ios/Runner/Assets.xcassets/LunasAppIcon.appiconset/Icon-App-1024x1024@1x.png
ios/Runner/Assets.xcassets/LunasAppIcon.appiconset/Icon-App-20x20@1x.png
ios/Runner/Assets.xcassets/LunasAppIcon.appiconset/Icon-App-20x20@2x.png
ios/Runner/Assets.xcassets/LunasAppIcon.appiconset/Icon-App-20x20@3x.png
ios/Runner/Assets.xcassets/LunasAppIcon.appiconset/Icon-App-29x29@1x.png
ios/Runner/Assets.xcassets/LunasAppIcon.appiconset/Icon-App-29x29@2x.png
ios/Runner/Assets.xcassets/LunasAppIcon.appiconset/Icon-App-29x29@3x.png
ios/Runner/Assets.xcassets/LunasAppIcon.appiconset/Icon-App-40x40@1x.png
ios/Runner/Assets.xcassets/LunasAppIcon.appiconset/Icon-App-40x40@2x.png
ios/Runner/Assets.xcassets/LunasAppIcon.appiconset/Icon-App-40x40@3x.png
ios/Runner/Assets.xcassets/LunasAppIcon.appiconset/Icon-App-60x60@2x.png
ios/Runner/Assets.xcassets/LunasAppIcon.appiconset/Icon-App-60x60@3x.png
ios/Runner/Assets.xcassets/LunasAppIcon.appiconset/Icon-App-76x76@1x.png
ios/Runner/Assets.xcassets/LunasAppIcon.appiconset/Icon-App-76x76@2x.png
ios/Runner/Assets.xcassets/LunasAppIcon.appiconset/Icon-App-83.5x83.5@2x.png
ios/Runner/Assets.xcassets/LunasSplash.imageset/lunas_splash@1x.png
ios/Runner/Assets.xcassets/LunasSplash.imageset/lunas_splash@2x.png
ios/Runner/Assets.xcassets/LunasSplash.imageset/lunas_splash@3x.png
ios/Runner/Base.lproj/LaunchScreen.storyboard
ios/Runner/Info.plist
lib/screens/auth/login_screen.dart
lib/screens/intro/intro_screen.dart
pubspec.yaml
```

Created:

```text
assets/branding/lunas_app_icon.png
assets/branding/lunas_splash_logo.png
assets/branding/lunas_splash_mark.png
```
