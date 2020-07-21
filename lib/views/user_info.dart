import 'package:clack/api.dart';
import 'package:clack/api/author_result.dart';
import 'package:clack/views/full_image.dart';
import 'package:clack/api/shared_types.dart';
import 'package:clack/utility.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/views/video_feed.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:icon_shadow/icon_shadow.dart';
import 'package:share/share.dart';

/// Contains all info about an [Author]
///
/// This includes their profile picture, username, stats, and all
/// of their videos and liked videos (if available). Tapping on the profile
/// picture opens it in a [FullImage] while tapping on any of the video
/// thumbnails opens up a new [VideoFeed] showing only their videos.
class UserInfo extends StatefulWidget {
  static const routeName = "/user_info";
  final Author Function() authorGetter;
  const UserInfo(this.authorGetter);

  @override
  _UserInfoState createState() => _UserInfoState();
}

class _UserInfoState extends State<UserInfo>
    with SingleTickerProviderStateMixin {
  /// Text style for an [Author]'s username
  final userTextStyle =
      TextStyle(color: Colors.black, fontWeight: FontWeight.bold);

  /// Text style for an [Author]'s stats
  final statsTextStyle =
      TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20);

  /// Text style for the text under the stats
  ///
  /// Following, Followers, and Hearts
  final softTextStyle =
      TextStyle(color: Colors.grey, fontSize: 12, height: 1.5);

  /// Text style for the play count overlay on each video thumbnail
  final playCountTextStyle =
      TextStyle(color: Colors.white, fontSize: 15, shadows: [
    Shadow(
      offset: Offset(1.0, 1.0),
      blurRadius: 3.0,
      color: Color.fromARGB(255, 0, 0, 0),
    ),
  ]);

  /// The {Author} to show
  Author _author;

  /// The full details of the author
  Future<AuthorResult> _authorResult;

  /// The [ApiStream]<[VideoResult]> of the [Author]'s videos
  ApiStream<VideoResult> _authorVideos;

  /// The [ApiStream]<[VideoResult]> of the [Author]'s liked videos
  ApiStream<VideoResult> _authorFavoritedVideos;

  /// Tab controller for the video TabView
  ///
  /// This contains both the [Author]'s videos and liked videos
  TabController _tabController;

  @override
  void initState() {
    super.initState();

    // Fetch the author's info from the API
    _author = widget.authorGetter();
    _authorResult = API.getAuthorInfo(_author);
    _authorVideos = API.getAuthorVideoStream(_author, 40);
    _authorFavoritedVideos = API.getAuthorFavoritedVideoStream(_author, 40);

    _authorVideos.setOnChanged(() => setState(() {}));
    _authorFavoritedVideos.setOnChanged(() => setState(() {}));

    // Set up the nested controller
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
      onWillPop: () => _handleBack(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_author.nickname),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => _handleBack(context),
          ),
          actions: [
            IconButton(
                icon: Icon(Icons.share),
                onPressed: () => _authorResult.then((authorResult) {
                      Share.share(getAuthorShare(authorResult),
                          subject:
                              "Check out @${authorResult.user.uniqueId} TikTok!");
                    }))
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverList(
                delegate: SliverChildListDelegate.fixed([
              SizedBox(height: 20),
              // Profile Picture
              Row(children: [
                Spacer(),
                Expanded(
                    child: GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, FullImage.routeName,
                            arguments:
                                FullImageArgs(_author.avatarLarger.toString())),
                        // Here we use a [Hero] so that the thumbnail can
                        // animate to and back from the [FullImage] when tapped
                        child: Hero(
                            tag: "full_image",
                            child: AspectRatio(
                                aspectRatio: 1,
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                      _author.avatarMedium.toString()),
                                ))))),
                Spacer()
              ]),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Text("@${_author.uniqueId}", style: userTextStyle)],
              ),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatsColumn((v) => v.stats.followingCount, "Following"),
                  _buildStatsColumn((v) => v.stats.followerCount, "Followers"),
                  _buildStatsColumn((v) => v.stats.heart, "Hearts")
                ],
              ),
              SizedBox(height: 10),
              // TODO: Make this change between 'Follow' and 'Message' / 'IconButton(?)
              //   based on whether the logged in user is following or not.
              ButtonBar(
                alignment: MainAxisAlignment.center,
                children: [
                  OutlineButton(
                    onPressed: () {},
                    child: Text("Message"),
                    textColor: Colors.black,
                  ),
                  OutlineButton.icon(
                    onPressed: null,
                    icon: Icon(Icons.person_add),
                    label: Container(),
                    textColor: Colors.black,
                  )
                ],
              ),
              Padding(
                  padding:
                      EdgeInsetsDirectional.only(start: 30, end: 30, top: 15),
                  child: Text(
                    _author.signature,
                    style: softTextStyle,
                    textAlign: TextAlign.center,
                  )),
              SizedBox(height: 30),
            ])),
            SliverStickyHeader(
                header: Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).canvasColor,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey,
                              blurRadius: 3,
                              offset: Offset(0, 3))
                        ]),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(icon: Icon(Icons.list)),
                        Tab(
                            icon: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                              Icon(Icons.favorite_border),
                              Padding(
                                  padding: EdgeInsets.only(bottom: 3),
                                  child: !_author.openFavorite
                                      ? Icon(
                                          Icons.lock,
                                          size: 12,
                                        )
                                      : null)
                            ]))
                      ],
                    )),
                // TODO: Allow for this to also be sscrolled together with
                //   its parent. Right now, it scrolls separately :(
                sliver: SliverFillRemaining(
                    child: TabBarView(controller: _tabController, children: [
                  _buildVideoList(_authorVideos),
                  _author.openFavorite
                      ? _buildVideoList(_authorFavoritedVideos)
                      : Center(
                          child: Text(
                              "@${_author.uniqueId} has hidden their liked videos."))
                ])))
          ],
        ),
      ));

  /// Generates a column with a specific [AuthorStat].
  ///
  /// This includes the stat number and a small subtext description
  Widget _buildStatsColumn(
          int Function(AuthorResult) member, String lowerText) =>
      Column(
        children: [
          FutureBuilder(
              future: _authorResult,
              builder: (context, AsyncSnapshot<AuthorResult> snapshot) => Text(
                    snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData
                        ? statToString(member(snapshot.data))
                        : "-",
                    style: statsTextStyle,
                  )),
          Text(
            lowerText,
            style: softTextStyle,
          )
        ],
      );

  /// Generates a [GridView] with the videos of a specific stream
  ///
  /// The [stream] is resued by passing it to the [VideoFeed] upon construction.
  Widget _buildVideoList(ApiStream<VideoResult> stream) {
    return FutureBuilder(
        future: _authorResult,
        builder: (context, AsyncSnapshot<AuthorResult> snapshot) {
          return snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData
              ? GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      mainAxisSpacing: 3,
                      crossAxisSpacing: 3,
                      crossAxisCount: 3),
                  itemCount: snapshot.data.stats.videoCount,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, VideoFeed.routeName,
                            arguments: VideoFeedArgs(
                                stream, index, snapshot.data.stats.videoCount,
                                showUserInfo: false)),
                        child: Container(
                            color: Colors.black,
                            child: Hero(
                                tag: "video_page_$index",
                                child: Stack(children: [
                                  AspectRatio(
                                      aspectRatio: 1,
                                      child: FittedBox(
                                          fit: BoxFit.fitWidth,
                                          child: stream[index] == null
                                              ? Padding(
                                                  padding: EdgeInsets.all(40),
                                                  child: SpinKitFadingCube(
                                                      color: Colors.grey))
                                              : Image.network(stream[index]
                                                  .video
                                                  .dynamicCover
                                                  .toString()))),
                                  Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Padding(
                                          padding: EdgeInsets.all(5),
                                          child: stream[index] == null
                                              ? Container()
                                              : Row(children: [
                                                  IconShadowWidget(
                                                    Icon(
                                                      Icons.play_arrow,
                                                      color: Colors.white,
                                                    ),
                                                    shadowColor: Colors.black,
                                                  ),
                                                  Text(
                                                    statToString(stream[index]
                                                        .stats
                                                        .playCount),
                                                    style: playCountTextStyle,
                                                  )
                                                ])))
                                ]))));
                  },
                )
              : Center(
                  child: SpinKitFadingGrid(
                  color: Colors.black,
                  size: 50,
                ));
        });
  }

  /// Moves back to the video when back is pressed
  Future<bool> _handleBack(BuildContext ctx) {
    DefaultTabController.of(ctx).index = 0;

    return Future.value(false);
  }
}
