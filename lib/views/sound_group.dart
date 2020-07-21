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

  ApiStream<VideoResult> _videos;
  bool _hasInit = false;

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
    //   SizedBox(height: 10),
    //   Row(
    //     mainAxisAlignment: MainAxisAlignment.center,
    //     children: [Text("@${_author.uniqueId}", style: userTextStyle)],
    //   ),
    //   SizedBox(height: 15),
    //   Row(
    //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //     children: [
    //       _buildStatsColumn((v) => v.stats.followingCount, "Following"),
    //       _buildStatsColumn((v) => v.stats.followerCount, "Followers"),
    //       _buildStatsColumn((v) => v.stats.heart, "Hearts")
    //     ],
    //   ),
    //   SizedBox(height: 10),
    //   // TODO: Make this change between 'Follow' and 'Message' / 'IconButton(?)
    //   //   based on whether the logged in user is following or not.
    //   ButtonBar(
    //     alignment: MainAxisAlignment.center,
    //     children: [
    //       OutlineButton(
    //         onPressed: () {},
    //         child: Text("Message"),
    //         textColor: Colors.black,
    //       ),
    //       OutlineButton.icon(
    //         onPressed: null,
    //         icon: Icon(Icons.person_add),
    //         label: Container(),
    //         textColor: Colors.black,
    //       )
    //     ],
    //   ),
    //   Padding(
    //       padding:
    //           EdgeInsetsDirectional.only(start: 30, end: 30, top: 15),
    //       child: Text(
    //         _author.signature,
    //         style: softTextStyle,
    //         textAlign: TextAlign.center,
    //       )),
    //   SizedBox(height: 30),
    // ])),
    // SliverStickyHeader(
    //     header: Container(
    //         decoration: BoxDecoration(
    //             color: Theme.of(context).canvasColor,
    //             boxShadow: [
    //               BoxShadow(
    //                   color: Colors.grey,
    //                   blurRadius: 3,
    //                   offset: Offset(0, 3))
    //             ]),
    //         child: TabBar(
    //           controller: _tabController,
    //           labelColor: Colors.black,
    //           unselectedLabelColor: Colors.grey,
    //           tabs: [
    //             Tab(icon: Icon(Icons.list)),
    //             Tab(
    //                 icon: Stack(
    //                     alignment: Alignment.bottomRight,
    //                     children: [
    //                   Icon(Icons.favorite_border),
    //                   Padding(
    //                       padding: EdgeInsets.only(bottom: 3),
    //                       child: !_author.openFavorite
    //                           ? Icon(
    //                               Icons.lock,
    //                               size: 12,
    //                             )
    //                           : null)
    //                 ]))
    //           ],
    //         )),
    //     // TODO: Allow for this to also be sscrolled together with
    //     //   its parent. Right now, it scrolls separately :(
    //     sliver: SliverFillRemaining(
    //         child: TabBarView(controller: _tabController, children: [
    //       _buildVideoList(_authorVideos),
    //       _author.openFavorite
    //           ? _buildVideoList(_authorFavoritedVideos)
    //           : Center(
    //               child: Text(
    //                   "@${_author.uniqueId} has hidden their liked videos."))
    //     ])))
    //     ],
    //   ),
    // );
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
                                Icon(Icons.play_arrow,
                                    color: Colors.white, size: 50),
                                shadowColor: Colors.black,
                              ),
                            ),
                          )))),
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
              onTap: () => Navigator.pushNamed(context, VideoFeed.routeName,
                  arguments: VideoFeedArgs(_videos, index, null)),
              child: Container(
                  color: Colors.black,
                  child: Stack(children: [
                    AspectRatio(
                        aspectRatio: 1,
                        child: FittedBox(
                            fit: BoxFit.fitWidth,
                            child: _videos[index] == null
                                ? Padding(
                                    padding: EdgeInsets.all(40),
                                    child:
                                        SpinKitFadingCube(color: Colors.grey))
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
                  ]))))),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 3, mainAxisSpacing: 3));
}
