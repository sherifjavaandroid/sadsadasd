import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/view/home/following_screen.dart';
import 'package:bubbly/view/home/for_u_screen.dart';
import 'package:bubbly/view/home/widget/agreement_home_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../live_stream/screen/live_stream_screen.dart';
import '../search/search_screen.dart';

// Import your screens here
// import 'package:bubbly/view/search/search_screen.dart';
// import 'package:bubbly/view/live/live_stream_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SessionManager sessionManager = SessionManager();
  int pageIndex = 1;

  @override
  void initState() {
    _homeAgreementDialog();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, MyLoading myLoading, child) {
        PageController controller =
            PageController(initialPage: 1, keepPage: true);
        return Scaffold(
          body: Stack(
            children: [
              PageView.builder(
                controller: controller,
                itemCount: 2,
                itemBuilder: (context, index) {
                  return index == 0 ? FollowingScreen() : ForYouScreen();
                },
                onPageChanged: (value) {
                  pageIndex = value;
                  myLoading.setIsForYouSelected(value == 1);
                },
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Live button (Top Left)
                      InkWell(
                        onTap: () {
                          // Navigate to LiveStreamScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LiveStreamScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 6.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: ColorRes.greyShade100.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_circle_outline,
                                color: ColorRes.colorTextLight,
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: FontRes.fNSfUiSemiBold,
                                  color: ColorRes.colorTextLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Center tabs (Following | For You)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              controller.animateToPage(0,
                                  duration: Duration(milliseconds: 500),
                                  curve: Curves.easeInToLinear);
                            },
                            child: Text(
                              LKey.following.tr,
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: FontRes.fNSfUiSemiBold,
                                color: pageIndex == 0
                                    ? ColorRes.colorTheme
                                    : ColorRes.greyShade100,
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 15),
                            height: 25,
                            width: 2,
                            color: ColorRes.colorTheme,
                          ),
                          InkWell(
                            onTap: () {
                              controller.animateToPage(1,
                                  duration: Duration(milliseconds: 500),
                                  curve: Curves.easeInToLinear);
                            },
                            child: Text(
                              LKey.forYou.tr,
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: FontRes.fNSfUiSemiBold,
                                color: pageIndex == 1
                                    ? ColorRes.colorTheme
                                    : ColorRes.colorTextLight,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Search button (Top Right)
                      InkWell(
                        onTap: () {
                          // Navigate to SearchScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.search,
                            color: ColorRes.colorTextLight,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _homeAgreementDialog() async {
    await Future.delayed(Duration.zero);
    Provider.of<MyLoading>(context, listen: false).getIsHomeDialogOpen
        ? showDialog(
            context: context,
            builder: (context) {
              return AgreementHomeDialog();
            },
            barrierDismissible: true)
        : SizedBox();
  }
}

