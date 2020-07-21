import 'package:audioplayer/audioplayer.dart';
import 'package:clack/api.dart';
import 'package:clack/api/music_result.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/views/video_feed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:icon_shadow/icon_shadow.dart';

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
  ApiStream<VideoResult> _videos;
  bool _hasInit = false;

  @override
  void dispose() {
    // Stop the player
    _player.stop();

    // Continue death
    super.dispose();
  }

  @override
  void initState() {
    // Update the UI when player changes state
    _player.onPlayerStateChanged.listen((event) => setState(() {}));

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
          actions: [IconButton(icon: Icon(Icons.share), onPressed: () => null)],
        ),
        body: _videos[0] == null
            ? Center(
                child: SpinKitCubeGrid(color: Colors.black),
              )
            : _buildPage());
  }

  Widget _buildPage() => CustomScrollView(slivers: [
        SliverPadding(
            padding: EdgeInsets.only(top: 20, bottom: 20),
            sliver: SliverToBoxAdapter(child: _buildHeader())),
        _buildVideoList()
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
                            onPressed: () {})
                      ],
                    ),
                  ))
            ]),
      ));

  Widget _buildVideoList() => SliverGrid(
      delegate: SliverChildBuilderDelegate((context, index) => AspectRatio(
          aspectRatio: 1,
          child: GestureDetector(
              onTap: () {
                // Stop the music, if playing
                _player.stop();

                // Start the VideoFeed
                Navigator.pushNamed(context, VideoFeed.routeName,
                    arguments: VideoFeedArgs(_videos, index, null));
              },
              child: Container(
                  color: Colors.black,
                  child: Hero(
                      tag: "video_page_$index",
                      child: Stack(children: [
                        AspectRatio(
                            aspectRatio: 1,
                            child: FittedBox(
                                fit: BoxFit.fitWidth,
                                child: _videos[index] == null
                                    ? Padding(
                                        padding: EdgeInsets.all(40),
                                        child: SpinKitFadingCube(
                                            color: Colors.grey))
                                    : Image.network(_videos[index]
                                        .video
                                        .dynamicCover
                                        .toString()))),
                        Align(
                            alignment: Alignment.topLeft,
                            child: _videos[index] == null ||
                                    !_videos[index].video.isOriginal
                                ? Container()
                                : Padding(
                                    padding: EdgeInsets.all(5),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(5),
                                          topLeft: Radius.circular(5),
                                          topRight: Radius.circular(20),
                                          bottomRight: Radius.circular(20)),
                                      child: Container(
                                        color: Colors.yellow,
                                        child: Padding(
                                            padding: EdgeInsets.only(
                                                left: 5,
                                                top: 5,
                                                bottom: 5,
                                                right: 10),
                                            child: Text("Original")),
                                      ),
                                    )))
                      ])))))),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 3, mainAxisSpacing: 3));
}
