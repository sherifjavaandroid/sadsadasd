import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/modal/sound/sound.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/view/music/search_music.dart';
import 'package:bubbly/view/music/widget/discover_page.dart';
import 'package:bubbly/view/music/widget/favourite_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class MusicScreen extends StatefulWidget {
  final Function(SoundList?, String) onSelectMusic;

  MusicScreen(this.onSelectMusic);

  @override
  _MusicScreenState createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  PageController pageController = PageController();
  FocusNode searchFocusNode = new FocusNode();
  List<SoundList> soundList = [];
  bool isPlay = false;
  SoundList? lastSoundListData;

  AudioPlayer audioPlayer = AudioPlayer();
  Function(String)? onSearchChangeValue;

  @override
  void initState() {
    searchFocusNode.addListener(() {
      Provider.of<MyLoading>(context, listen: false)
          .setIsSearchMusic(searchFocusNode.hasFocus);
      soundList = [];
    });
    pageController = PageController(
        initialPage:
            Provider.of<MyLoading>(context, listen: false).getMusicPageIndex,
        keepPage: true);
    super.initState();
  }

  @override
  void dispose() {
    audioPlayer.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, MyLoading myLoading, child) {
      return Container(
        height:
            MediaQuery.of(context).size.height - AppBar().preferredSize.height,
        decoration: BoxDecoration(
            color:
                myLoading.isDark ? ColorRes.colorPrimaryDark : ColorRes.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                        left: soundList.isNotEmpty ? 0 : 15,
                        top: 15,
                        right: 15),
                    padding: EdgeInsets.only(left: 15, right: 15, bottom: 5),
                    height: 45,
                    decoration: BoxDecoration(
                      color: myLoading.isDark
                          ? ColorRes.colorPrimary
                          : ColorRes.greyShade100,
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        onSearchChangeValue!(value);
                        myLoading.setMusicSearchText(value);
                        myLoading.setLastSelectSoundId("");
                      },
                      onTap: () {
                        audioPlayer.release();
                      },
                      focusNode: searchFocusNode,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: LKey.search.tr,
                      ),
                      cursorColor: ColorRes.colorTextLight,
                    ),
                  ),
                ),
                Visibility(
                  visible: soundList.isEmpty && myLoading.isSearchMusic,
                  child: InkWell(
                    onTap: () {
                      if (myLoading.musicSearchText.isEmpty) {
                        FocusScope.of(context).unfocus();
                        audioPlayer.release();
                        myLoading.setIsSearchMusic(false);
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.only(top: 15),
                      child: Text(
                        myLoading.musicSearchText.isNotEmpty
                            ? LKey.search.tr
                            : LKey.cancel.tr,
                      ),
                      width: 60,
                    ),
                  ),
                ),
              ],
            ),
            Visibility(
                visible: !myLoading.isSearchMusic,
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            pageController.animateToPage(0,
                                duration: Duration(milliseconds: 200),
                                curve: Curves.linear);
                          },
                          child: Center(
                            child: Text(
                              LKey.discover.tr,
                              style: TextStyle(
                                color: myLoading.getMusicPageIndex == 0
                                    ? ColorRes.colorPink
                                    : ColorRes.colorTextLight,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            pageController.animateToPage(1,
                                duration: Duration(milliseconds: 200),
                                curve: Curves.linear);
                          },
                          child: Center(
                            child: Text(
                              LKey.favourite.tr,
                              style: TextStyle(
                                color: myLoading.getMusicPageIndex == 1
                                    ? ColorRes.colorPink
                                    : ColorRes.colorTextLight,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            SizedBox(height: myLoading.isSearchMusic ? 10 : 0),
            Container(
              height: 0.2,
              color: ColorRes.colorTextLight,
            ),
            SizedBox(height: 5),
            Expanded(
                child: !myLoading.isSearchMusic
                    ? PageView(
                        controller: pageController,
                        onPageChanged: (value) {
                          myLoading.setLastSelectSoundId("");
                          myLoading.setMusicPageIndex(value);
                          audioPlayer.release();
                        },
                        children: [
                          DiscoverPage(
                            onMoreClick: (value) {
                              soundList = value;
                              myLoading.setIsSearchMusic(true);
                            },
                            onPlayClick: (data) {
                              playMusic(data, 1, myLoading);
                            },
                          ),
                          FavouritePage(
                            onClick: (data) {
                              playMusic(data, 2, myLoading);
                            },
                          ),
                        ],
                      )
                    : SearchMusic(
                        onSoundClick: (data) {
                          playMusic(data, 3, myLoading);
                        },
                        onSearchTextChange: onSearchChange,
                        soundList: soundList)),
          ],
        ),
      );
    });
  }

  void playMusic(SoundList data, int type, MyLoading myLoading) async {
    if (myLoading.isDownloadClick) {
      CommonUI.showLoader(context);
      myLoading.setIsDownloadClick(false);
      File musicFile = await DefaultCacheManager()
          .getSingleFile('${ConstRes.itemBaseUrl}${data.sound}');
      widget.onSelectMusic(lastSoundListData, musicFile.path);

      Navigator.pop(context); // Stop Loader
      Navigator.pop(context); // Remove Sheet
      return;
    }
    if (lastSoundListData == data) {
      if (isPlay) {
        isPlay = false;
        audioPlayer.pause();
      } else {
        isPlay = true;
        audioPlayer.resume();
      }
      myLoading.setLastSelectSoundIsPlay(isPlay);
      return;
    }
    lastSoundListData = data;
    myLoading.setLastSelectSoundId(lastSoundListData!.sound! + type.toString());
    myLoading.setLastSelectSoundIsPlay(true);
    audioPlayer
        .play(UrlSource(ConstRes.itemBaseUrl + "${lastSoundListData?.sound}"));
    isPlay = true;
    setState(() {});
  }

  onSearchChange(Function(String p1) p1) {
    onSearchChangeValue = p1;
  }
}
