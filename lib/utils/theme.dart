import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:flutter/material.dart';

bool isLightMode = true;

/// Theme light mode

ThemeData lightTheme(BuildContext context) {
  return ThemeData(
    primaryColorDark: ColorRes.white,
    scaffoldBackgroundColor: ColorRes.white,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    focusColor: Colors.transparent,
    colorScheme: ColorScheme(
      primary: Colors.grey.withValues(alpha: 0.4),
      error: ColorRes.colorTheme,
      brightness: Brightness.light,
      surface: ColorRes.greyShade100,
      secondary: ColorRes.colorTheme,
      onSurface: Colors.black,
      onSecondary: ColorRes.white,
      onPrimary: ColorRes.greyShade100,
      onError: Colors.red,
    ),
    fontFamily: FontRes.fNSfUiRegular,
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black),
      labelLarge: TextStyle(color: Colors.black),
    ),
    iconTheme: IconThemeData(color: Colors.black),
    useMaterial3: false,
  );
}

/// Theme dark mode
ThemeData darkTheme(BuildContext context) {
  return ThemeData(
    primaryColorDark: ColorRes.colorPrimaryDark,
    scaffoldBackgroundColor: ColorRes.colorPrimaryDark,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    focusColor: Colors.transparent,
    colorScheme: ColorScheme(
        primary: ColorRes.colorTextLight,
        error: ColorRes.colorTheme,
        brightness: Brightness.dark,
        surface: ColorRes.colorTextLight,
        onSurface: ColorRes.greyShade100,
        secondary: ColorRes.colorTheme,
        onSecondary: Colors.blue,
        onPrimary: Colors.red,
        onError: Colors.red),
    fontFamily: FontRes.fNSfUiRegular,
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: ColorRes.white),
      bodyMedium: TextStyle(color: ColorRes.white),
      labelLarge: TextStyle(color: ColorRes.white),
    ),
    iconTheme: IconThemeData(color: ColorRes.white),
    useMaterial3: false,
  );
}
