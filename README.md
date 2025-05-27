# Shortzz

# Date: 17 April 2025

## Summary

- Removed FFmpeg library in the plugin.
- Added camera library support for iOS.
- Fixed `mergeAudioAndVideo` functionality in the camera.
- Fixed issues with saving video and adding watermark.

#### Updated Files

- [.gitignore](.gitignore)
- [build.gradle](android/build.gradle)
- [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)
- api_service.dart
- app_res.dart
- [build.gradle](android/app/build.gradle)
- camera_screen.dart
- main_screen.dart
- music_screen.dart
- preview_screen.dart
- [pubspec.yaml](pubspec.yaml)
- [settings.gradle](android/settings.gradle)
- share_sheet.dart
- const_res.dart
- main_screen.dart
- README.md

#### Added Files

- None

#### Deleted Files

- None

#### Rename Files

- **[lib/view/main/widget/eula_sheet.dart](lib/view/main/widget/eula_sheet.dart)**  
  Renamed from: `end_user_license_agreement.dart`

----------------------------------------------------------------------------------------------------
# Date: 15 March 2025

## Summary

- Fixed camera preview view.
- Updated `build.gradle` for Android.
- Updated `camerax_version` for `bubbly_camera`.
- Removed FFmpeg library and created a custom plugin.
- Removed `flutter_downloader: ^1.12.0`.
- Updated `pubspec.yaml` file.
- Bug fixes and performance improvements.

#### Updated Files

- add_btn_sheet.dart
- agreement_home_dialog.dart
- AndroidManifest.xml
- api_service.dart
- [AppDelegate.swift](ios/Runner/AppDelegate.swift)
- audience_top_bar.dart
- blur_tab.dart
- broad_cast_screen.dart
- [build.gradle](android/app/build.gradle)
- [build.gradle](CameraPlugin/camera/android/build.gradle)
- camera_screen.dart
- chat_area.dart
- confirmation_dialog.dart
- dialog_coins_plan.dart
- edit_profile_screen.dart
- favourite_page.dart
- gift_sheet.dart
- [gradle-wrapper.properties](android/gradle/wrapper/gradle-wrapper.properties)
- image_preview.dart
- image_video_msg_screen.dart
- item_following.dart
- item_search_video.dart
- item_video.dart
- languages_screen.dart
- live_stream_bottom_filed.dart
- live_stream_chat_list.dart
- live_stream_end_screen.dart
- live_stream_screen.dart
- main.dart
- main_screen.dart
- music_screen.dart
- my_qr_code_screen.dart
- notifiation_screen.dart
- preview_screen.dart
- profile_card.dart
- profile_video_screen.dart
- pubspec.yaml
- README.md
- redeem_screen.dart
- report_screen.dart
- scan_qr_code_screen.dart
- setting_center_area.dart
- [settings.gradle](android/settings.gradle)
- share_sheet.dart
- tab_bar_view_custom.dart
- [theme.dart](lib/utils/theme.dart)
- upload_screen.dart
- verification_screen.dart
- videos_by_sound.dart
- wallet_screen.dart

#### Added Files

- NONE

#### Deleted Files

- MyApplication.kt

----------------------------------------------------------------------------------------------------

# Date: 14 FEB 2025

## Summary

- Library Update in `pubspec.yaml` file

#### Updated Files

- build.gradle
- preview_screen.dart
- pubspec.yaml
- settings.gradle

#### Added Files

- None

#### Deleted Files

- None

----------------------------------------------------------------------------------------------------

# Date: 21 JAN 2025

## Summary

- Remove Firebase token saving from the main screen.
- Remove the `sign_in_with_apple: ^6.1.4` library.
- Update other libraries in the `pubspec.yaml` file.

#### Updated Files

- login_sheet.dart
- main.dart
- pubspec.yaml
- sign_in_screen.dart
- sign_up_screen.dart
- build.gradle
- gradle-wrapper.properties
- settings.gradle

----------------------------------------------------------------------------------------------------

# Date: 23 October 2024

## Summary

- Reel download issue fixed
- Video preview orientation corrected
- Bug fixes and performance improvements

#### Updated Files

- [settings.gradle](android/settings.gradle)
- [pubspec.yaml](pubspec.yaml)
- Podfile
- api_service.dart
- camera_screen.dart
- const_res.dart
- english_en.dart
- item_video.dart
- login_sheet.dart
- preview_screen.dart
- share_sheet.dart
- wallet_screen.dart
- for_u_screen.dart
- item_following.dart
- main.dart
- preview_screen.dart
- upload_screen.dart
- video_list_screen.dart
- video_view.dart
- videos_by_hashtag.dart

#### Added Files

- None

#### Deleted Files

- None

----------------------------------------------------------------------------------------------------

# Date: 19 September 2024

## Summary

- replace library `mobile_scanner: ^5.2.3`  to `qr_code_scanner_plus: ^2.0.6`
- comment bug fixed
- upload sheet add `DetectableTextEditingController`
- Update pubspec.yaml file some library

#### Updated Files
- comment_screen.dart
- pubspec.yaml
- scan_qr_code_screen.dart
- upload_screen.dart

#### Added Files
None

#### Deleted Files
None

----------------------------------------------------------------------------------------------------

# Date: 1 August 2024

## Summary

- Remove Library - `carousel_slider`
- Change Library -
-
Remove `image_gallery_saver` Add `saver_gallery`   
  Remove `qr_code_scanner` Add `mobile_scanner`

#### Updated Files

- [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)
- [Info.plist](ios/Runner/Info.plist)
- [pubspec.yaml](pubspec.yaml)
- [settings.gradle](android/settings.gradle)
- main.dart
- app_res.dart
- scan_qr_code_screen.dart
- camera_screen.dart
- following_screen.dart
- gift_sheet.dart
- languages_keys.dart
- share_sheet.dart
- arabic_ar.dart
- chinese_zh.dart
- danish_da.dart
- dutch_nl.dart
- english_en.dart
- france_fr.dart
- german_de.dart
- greek_el.dart
- hindi_hi.dart
- indonesian_id.dart
- japanese_ja.dart
- korean_ko.dart
- norwegian_bokmal_nb.dart
- polish_pl.dart
- portuguese_pt.dart
- russian_ru.dart
- spanish_es.dart
- thai_th.dart
- turkish_tr.dart
- vietnamese_vi.dart

#### Added Files

None

#### Deleted Files

- messages_all.dart
- messages_en.dart
- intl_en.arb
- l10n.dart

----------------------------------------------------------------------------------------------------

# Date: 19 June 2024

## Summary
- Apple Sign in
- Comment sheet loader
- `const_res.dart` file add video limit maxUploadMB and maxUploadSecond

#### Updated Files
- [pubspec.yaml](pubspec.yaml)
- [build.gradle](android/app/build.gradle)
- api_service.dart
- camera_screen.dart
- comment_screen.dart
- common_ui.dart
- const_res.dart
- login_sheet.dart

#### Added Files

None

#### Deleted Files

None

----------------------------------------------------------------------------------------------------

# Date: 12 June 2024

## Summary
- User Camera Don't Allow Permission Screen

#### Updated Files
- [AppDelegate.swift](ios/Runner/AppDelegate.swift)
- [Info.plist](ios/Runner/Info.plist)
- [Podfile](ios/Podfile)
- [pubspec.yaml](pubspec.yaml)
- [SwiftFlutterDailogPlugin.swift](CameraPlugin/camera/ios/Classes/SwiftFlutterDailogPlugin.swift)
- assert_image.dart
- camera_screen.dart
- end_user_license_agreement.dart
- item_video.dart
- live_stream_view_model.dart
- main.dart
- main_screen.dart
- settings.gradle
- share_sheet.dart
- videos_by_sound.dart

#### Added Files

- ic_camera_permission.png
- microphone.png
- no-video.png

#### Deleted Files

- bubble_corner.png
- bubble_single.png
- bubble_single_small.png
- bubbles.png
- bubbles_small.png
- camera.jpg
- idol.jpg
- malaika.jpg

----------------------------------------------------------------------------------------------------

# Date: 10 May 2024

## Summary
- Add In App Purchase
- Migrate Gradle Files
- Library update
- Remove app_tracking_transparency Library and Add Consent Form for Ad Mob

#### Updated Files
- api_service.dart
- common_ui.dart
- dialog_coins_plan.dart
- wallet_screen.dart
- upload_screen.dart
- webview_screen.dart
- item_video.dart
- login_sheet.dart
- main.dart
- main_screen.dart
- broad_cast_screen_view_model.dart
- end_user_license_agreement.dart
- camera_screen.dart
- [AndroidManifest.xml](/android/app/src/debug/AndroidManifest.xml)
- [AndroidManifest.xml](/android/app/src/main/AndroidManifest.xml)
- [AndroidManifest.xml](/android/app/src/profile/AndroidManifest.xml)
- [BubblyCameraPlugin.kt](/CameraPlugin/camera/android/src/main/kotlin/com/retrytech/bubbly_camera)
- [build.gradle](/android/app/build.gradle)
- [build.gradle](/android)
- [build.gradle](/CameraPlugin/camera/android/build.gradle)
- [CameraXView.kt](/CameraPlugin/camera/android/src/main/kotlin/com/retrytech/bubbly_camera/CameraXView.kt)
- [gradle.properties](/android/gradle.properties)
- [gradle-wrapper.properties](/android/gradle/wrapper/gradle-wrapper.properties)
- [MainActivity.kt](/android/app/src/main/kotlin/com/retrytech/bubbly/MainActivity.kt)
- [settings.gradle](/android/settings.gradle)
- pubspec.yaml

#### Added Files
- proguard-rules.pro
- [ads_service.dart](/lib/service/ads_service.dart)

#### Deleted Files
- MyPlayStoreBilling.java