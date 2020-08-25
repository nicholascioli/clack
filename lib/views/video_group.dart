import 'dart:async';

import 'package:audioplayer/audioplayer.dart';
import 'package:clack/api.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/fragments/GridFragment.dart';
import 'package:clack/utility.dart';
import 'package:clack/views/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoGroupArguments {
  final Widget Function() headerBuilder;
  final ApiStream<VideoResult> stream;

  const VideoGroupArguments(
      {@required this.stream, @required this.headerBuilder});
}

class VideoGroup extends StatefulWidget {
  static final routeName = "/audio_group";

  @override
  _VideoGroupState createState() => _VideoGroupState();
}

class _VideoGroupState extends State<VideoGroup> {
  Widget Function() _headerBuilder;
  ApiStream<VideoResult> _videos;
  bool _hasInit = false;

  SharedPreferences _prefs;

  @override
  void initState() {
    // Get access to the shared preferences
    SharedPreferences.getInstance()
        .then((value) => setState(() => _prefs = value));

    // Continue init
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Extract the stream from the arguments
    if (!_hasInit) {
      VideoGroupArguments args = ModalRoute.of(context).settings.arguments;
      _headerBuilder = args.headerBuilder;
      _videos = args.stream;
      _videos.setOnChanged(() => setState(() {
            print("UPDATE!: ${_videos[0]}");
          }));
      _hasInit = true;
    }

    return Scaffold(
        appBar: AppBar(actions: [
          IconButton(
              icon: Icon(Icons.share),
              onPressed: () => _videos[0] == null || _prefs == null
                  ? {}
                  : Share.share(getMusicShare(_videos[0].music,
                      _prefs.getBool(SettingsView.sharingShowInfo))))
        ]),
        body: _videos[0] == null
            ? Center(
                child: SpinKitCubeGrid(
                    color: Theme.of(context).textTheme.headline1.color),
              )
            : _buildPage());
  }

  Widget _buildPage() => CustomScrollView(slivers: [
        SliverPadding(
            padding: EdgeInsets.only(top: 20, bottom: 20),
            sliver: SliverToBoxAdapter(child: _headerBuilder())),
        GridFragment(
            asSliver: true,
            stream: _videos,
            showPlayCount: false,
            showOriginal: true,
            heroTag: "soundGroup")
      ]);
}
