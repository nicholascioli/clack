import 'dart:math';

import 'package:clack/api.dart';
import 'package:clack/api/author_result.dart';
import 'package:clack/views/full_image.dart';
import 'package:clack/api/shared_types.dart';
import 'package:clack/utility.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/views/video_feed.dart';
import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
  final bool isCurrentUser;

  const UserInfo(this.authorGetter, {this.isCurrentUser = false});

  /// Create a UserInfo for the currently logged-in user.
  static UserInfo currentUser() =>
      UserInfo(() => API.getLogin().user, isCurrentUser: true);

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
  }

  @override
  Widget build(BuildContext context) {
    // Change the AppBar's actions when viewing the current user
    List<Widget> actions;
    if (widget.isCurrentUser) {
      actions = [
        IconButton(
            icon: Icon(Icons.exit_to_app), onPressed: () => _showLogOutDialog())
      ];
    } else {
      actions = [
        IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _authorResult.then((authorResult) {
                  Share.share(getAuthorShare(authorResult),
                      subject:
                          "Check out @${authorResult.user.uniqueId} TikTok!");
                }))
      ];
    }

    // Build the view
    return WillPopScope(
        onWillPop: () => _handleBack(context),
        child: Scaffold(
            appBar: AppBar(
              title: Text(_author.nickname),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => _handleBack(context),
              ),
              actions: actions,
            ),
            body: DefaultTabController(
                length: 2,
                // Here we wrap in a NestedScrollView so that the nested Grid
                //   view containing the videos can be scrolled together with the
                //   general user info.
                child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
                                          arguments: FullImageArgs(
                                              _author.avatarLarger.toString())),
                                      // Here we use a [Hero] so that the thumbnail can
                                      // animate to and back from the [FullImage] when tapped
                                      child: Hero(
                                          tag: "full_image",
                                          child: AspectRatio(
                                              aspectRatio: 1,
                                              child: CircleAvatar(
                                                backgroundImage: NetworkImage(
                                                    _author.avatarMedium
                                                        .toString()),
                                              ))))),
                              Spacer()
                            ]),
                            (_author.verified
                                ? Row(children: [
                                    Spacer(),
                                    Padding(
                                        padding:
                                            EdgeInsets.only(top: 10, bottom: 5),
                                        child: Row(children: [
                                          Icon(Icons.check_circle,
                                              color: Theme.of(context)
                                                  .accentColor),
                                          SizedBox(width: 5),
                                          Text("verified account",
                                              style: softTextStyle)
                                        ])),
                                    Spacer()
                                  ])
                                : Container()),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("@${_author.uniqueId}",
                                    style: userTextStyle)
                              ],
                            ),
                            SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatsColumn(
                                    (v) => v.stats.followingCount, "Following"),
                                _buildStatsColumn(
                                    (v) => v.stats.followerCount, "Followers"),
                                _buildStatsColumn(
                                    (v) => v.stats.heart, "Hearts")
                              ],
                            ),
                            SizedBox(height: 10),
                            FutureBuilder(
                                future: _authorResult,
                                builder: (context,
                                    AsyncSnapshot<AuthorResult> snapshot) {
                                  if (snapshot.connectionState ==
                                          ConnectionState.done &&
                                      snapshot.hasData) {
                                    List<Widget> buttons;

                                    // If we aren't following, offer to follow
                                    if (snapshot.data.user.relation == 0) {
                                      buttons = [
                                        FlatButton(
                                            onPressed: () =>
                                                showNotImplemented(context),
                                            color: Colors.pink,
                                            child: Text("Follow"),
                                            textColor: Colors.white)
                                      ];
                                    } else {
                                      buttons = [
                                        FlatButton(
                                          onPressed: () =>
                                              showNotImplemented(context),
                                          color: Colors.pink,
                                          child: Text("Message"),
                                          textColor: Colors.white,
                                        ),
                                        OutlineButton(
                                          onPressed: null,
                                          child: Icon(Icons.playlist_add_check),
                                          color: Colors.black,
                                        )
                                      ];
                                    }

                                    return ButtonBar(
                                        alignment: MainAxisAlignment.center,
                                        children: buttons);
                                  } else {
                                    return Container();
                                  }
                                }),
                            Padding(
                                padding: EdgeInsetsDirectional.only(
                                    start: 30, end: 30, top: 15),
                                child: Text(
                                  _author.signature,
                                  style: softTextStyle,
                                  textAlign: TextAlign.center,
                                )),
                            SizedBox(height: 30),
                          ])),
                          // We need a SliverOverlapAbsorber here so that overlap
                          //    events in the nested child effect the parent
                          //  e.g. Everything scolls together
                          SliverOverlapAbsorber(
                              handle: NestedScrollView
                                  .sliverOverlapAbsorberHandleFor(context),
                              sliver: SliverAppBar(
                                  excludeHeaderSemantics: true,
                                  backgroundColor: Colors.white,
                                  forceElevated: innerBoxIsScrolled,
                                  pinned: true,
                                  title: TabBar(
                                    indicator: BoxDecoration(),
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
                                                padding:
                                                    EdgeInsets.only(bottom: 3),
                                                child: !_author.openFavorite &&
                                                        !widget.isCurrentUser
                                                    ? Icon(
                                                        Icons.lock,
                                                        size: 12,
                                                      )
                                                    : null)
                                          ]))
                                    ],
                                  )))
                        ],
                    // TODO: Figure out reliable padding for pinned SliverAppBar above
                    body: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: ExtendedTabBarView(
                          linkWithAncestor: true,
                          children: [
                            _buildVideoList(
                                _authorVideos,
                                (stats) => stats.videoCount,
                                (author) => author.stats.videoCount > 0,
                                false,
                                "Nothing to see here..."),
                            _buildVideoList(
                                _authorFavoritedVideos,
                                (stats) => stats.diggCount,
                                (_) =>
                                    _author.openFavorite ||
                                    widget.isCurrentUser,
                                true,
                                _author.openFavorite || widget.isCurrentUser
                                    ? "Nothing to see here..."
                                    : "@${_author.uniqueId} has hidden their liked videos.")
                          ],
                        ))))));
  }

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
  Widget _buildVideoList(
      ApiStream<VideoResult> stream,
      int Function(AuthorStats stats) count,
      bool Function(AuthorResult res) condition,
      bool showUserInfo,
      String emptyMessage) {
    final gridBuilder = (AuthorResult userInfo) => GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              mainAxisSpacing: 3, crossAxisSpacing: 3, crossAxisCount: 3),
          itemCount: max(count(userInfo.stats), 0),
          itemBuilder: (context, index) {
            return GestureDetector(
                onTap: () => Navigator.pushNamed(context, VideoFeed.routeName,
                    arguments: VideoFeedArgs(
                        stream, index, max(count(userInfo.stats), 0),
                        showUserInfo: showUserInfo, heroTag: "userInfo")),
                child: Container(
                    color: Colors.black,
                    child: Hero(
                        tag: "userInfo_video_page_$index",
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
                                            statToString(
                                                stream[index].stats.playCount),
                                            style: playCountTextStyle,
                                          )
                                        ])))
                        ]))));
          },
        );

    return FutureBuilder(
        future: _authorResult,
        builder: (context, AsyncSnapshot<AuthorResult> snapshot) {
          // Check if we have data to work with
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            // Check if we have videos to show
            if (condition(snapshot.data)) {
              return gridBuilder(snapshot.data);
            } else {
              // Otherwise, show empty text
              return Center(child: Text(emptyMessage));
            }
          } else {
            // Otherwise, show loading
            return Center(
                child: SpinKitFadingGrid(
              color: Colors.black,
              size: 50,
            ));
          }
        });
  }

  /// Moves back to the video when back is pressed
  Future<bool> _handleBack(BuildContext ctx) {
    DefaultTabController.of(ctx).index = 0;

    return Future.value(false);
  }

  Future<void> _showLogOutDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Log Out?"),
        content: Text(
            "Are you sure you want to log out? After logging out, the app will reload."),
        actions: [
          FlatButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FlatButton(
              child: Text("Log Out"),
              onPressed: () =>
                  API.logout().then((value) => Phoenix.rebirth(context)))
        ],
      ),
    );
  }
}
