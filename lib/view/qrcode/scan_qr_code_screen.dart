import 'dart:io';

import 'package:bubbly/custom_view/app_bar_custom.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/utils/assert_image.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/view/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class ScanQrCodeScreen extends StatefulWidget {
  @override
  _ScanQrCodeScreenState createState() => _ScanQrCodeScreenState();
}

class _ScanQrCodeScreenState extends State<ScanQrCodeScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppBarCustom(title: LKey.scanQrCode.tr),
          Expanded(
            child: Column(
              children: [
                Spacer(),
                Image.asset(icQrCode, color: ColorRes.colorTheme),
                Spacer(),
                Text(
                  LKey.scanQrCodeToSeeProfile.tr,
                  style: TextStyle(fontSize: 18),
                ),
                Spacer(),
                Container(
                  height: 250,
                  width: 250,
                  margin: EdgeInsets.only(top: 40, bottom: 50),
                  decoration: BoxDecoration(
                      border: Border.all(color: ColorRes.colorTheme, width: 4),
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: ColorRes.colorPrimary),
                  child: QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                  ),
                ),
                Spacer(),
                Consumer(
                  builder: (context, MyLoading myLoading, child) => Image(
                    height: 60,
                    image: AssetImage(
                      myLoading.isDark ? icLogoHorizontal : icLogoHorizontalLight,
                    ),
                  ),
                ),
                Spacer(flex: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });

      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen(type: 1, userId: result?.format.name ?? '-1')),
      );
    });
  }

}
