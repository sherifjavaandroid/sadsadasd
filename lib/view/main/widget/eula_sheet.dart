import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/key_res.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EulaSheet extends StatefulWidget {
  final SessionManager sessionManager;

  const EulaSheet({Key? key, required this.sessionManager}) : super(key: key);

  @override
  State<EulaSheet> createState() => _EulaSheetState();
}

class _EulaSheetState extends State<EulaSheet> {
  WebViewController controller = WebViewController();
  @override
  void initState() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(ConstRes.agreementUrl));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, MyLoading myLoading, child) => Container(
        height: MediaQuery.of(context).size.height - AppBar().preferredSize.height * 1.5,
        decoration: BoxDecoration(
            color: myLoading.isDark ? ColorRes.colorPrimary : ColorRes.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
        child: Column(
          children: [
            Container(
                padding: EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Center(
                    child: Text(
                  LKey.endUserLicenseAgreement.tr,
                  style: TextStyle(fontSize: 16),
                ))),
            Divider(height: 1),
            SizedBox(height: 10),
            Expanded(
              child: WebViewWidget(
                controller: controller,
              ),
            ),
            InkWell(
              onTap: () {
                widget.sessionManager.saveBoolean(KeyRes.isAccepted, true);
                Navigator.pop(context);
              },
              child: Container(
                  alignment: Alignment.center,
                  height: 70,
                  color: myLoading.isDark ? ColorRes.colorPrimary : ColorRes.greyShade100,
                  child: SafeArea(
                      top: false,
                      child: Text(
                        LKey.accept.tr,
                      ))),
            ),
          ],
        ),
      ),
    );
  }
}
