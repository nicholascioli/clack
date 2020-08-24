import 'dart:async';

import 'package:audioplayer/audioplayer.dart';
import 'package:clack/api.dart';
import 'package:clack/api/music_result.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/fragments/GridFragment.dart';
import 'package:clack/utility.dart';
import 'package:clack/views/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:icon_shadow/icon_shadow.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundGroupArguments {
  final ApiStream<MusicResult> stream;
  const SoundGroupArguments(this.stream);
}

class SoundGroup extends StatefulWidget {
  static final routeName = "/audio_group";

  @override
  _SoundGroupState createState() => _SoundGroupState();
}

class _SoundGroupState extends State<SoundGroup> {
  final TextStyle musicTitleTextStyle =
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  final TextStyle textStyle = TextStyle(color: Colors.grey);

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<AudioPlayerState> _updateSubscription;
  ApiStream<VideoResult> _videos;
  bool _hasInit = false;

  SharedPreferences _prefs;

  @override
  void dispose() {
    // Stop the player
    _player.stop();
    _updateSubscription.cancel();

    // Continue death
    super.dispose();
  }

  @override
  void initState() {
    // Update the UI when player changes state
    _updateSubscription =
        _player.onPlayerStateChanged.listen((event) => setState(() {}));

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
      SoundGroupArguments args = ModalRoute.of(context).settings.arguments;
      _videos = args.stream.transform((MusicResult r) => VideoResult(
          id: r.id,
          createTime: r.createTime,
          desc: r.text,
          author: r.author,
          music: r.musicInfo,
          video: r.video,
          stats: r.stats));
      _videos.setOnChanged(() => setState(() {
            print("UPDATE!: ${_videos[0]}");
          }));
    }
    _hasInit = true;

    return Scaffold(
        appBar: AppBar(
            actions: [
              IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () => _videos[0] == null || _prefs == null
                      ? {}
                      : Share.share(getMusicShare(_videos[0].music,
                          _prefs.getBool(SettingsView.sharingShowInfo))))
            ],
            title: Text(_videos[0] == null
                ? ""
                : "${_videos[0].music.title} by ${_videos[0].music.authorName}")),
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
            sliver: SliverToBoxAdapter(child: _buildHeader())),
        GridFragment(
            asSliver: true,
            stream: _videos,
            showPlayCount: false,
            showOriginal: true,
            heroTag: "soundGroup")
      ]);

  Widget _buildHeader() => IntrinsicHeight(
          child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                  flex: 1,
                  child: GestureDetector(
                      onTap: () => _player.state == AudioPlayerState.PLAYING
                          ? _player.pause()
                          : _player.play(_videos[0].music.playUrl.toString()),
                      child: AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                        image: NetworkImage(_videos[0]
                                            .music
                                            .coverLarge
                                            .toString()))),
                                child: Center(
                                  child: IconShadowWidget(
                                    Icon(
                                        _player.state !=
                                                AudioPlayerState.PLAYING
                                            ? Icons.play_arrow
                                            : Icons.pause,
                                        color: Colors.white,
                                        size: 50),
                                    shadowColor: Colors.black,
                                  ),
                                ),
                              ))))),
              Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_videos[0].music.title,
                            style: musicTitleTextStyle),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _videos[0].music.authorName,
                                style: textStyle,
                              ),
                              Text(
                                "? videos",
                                style: textStyle,
                              )
                            ]),
                        RaisedButton(
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bookmark_border),
                                  Text("Add to Favorites")
                                ]),
                            onPressed: () => showNotImplemented(context))
                      ],
                    ),
                  ))
            ]),
      ));
}
