import 'package:bubbly/custom_view/app_bar_custom.dart';
import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/utils/url_res.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  final int type;

  WebViewScreen(this.type);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  bool isLoading = false;
  WebViewController controller = WebViewController();

  @override
  void initState() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            isLoading = true;
            setState(() {});
          },
          onPageFinished: (String url) {
            isLoading = false;
            setState(() {});
          },
        ),
      )
      ..loadRequest(Uri.parse(getWebUrl));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    return Scaffold(
      body: Column(
        children: [
          AppBarCustom(title: getTitle()),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(
                  controller: controller,
                ),
                isLoading ? LoaderDialog() : SizedBox()
              ],
            ),
          ),
        ],
      ),
    );
  }

  String getTitle() {
    String title = '';
    if (widget.type == 2) {
      title = LKey.termsOfUse.tr;
    } else if (widget.type == 3) {
      title = LKey.privacyPolicy.tr;
    }
    return title;
  }

  String get getWebUrl {
    String title = '';
    if (widget.type == 2) {
      title = UrlRes.termAndCondition;
    } else if (widget.type == 3) {
      title = UrlRes.privacyPolicy;
    }
    return title;
  }
}
