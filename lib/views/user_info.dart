import 'package:clack/api.dart';
import 'package:clack/api/author_result.dart';
import 'package:clack/fragments/GridFragment.dart';
import 'package:clack/views/full_image.dart';
import 'package:clack/api/shared_types.dart';
import 'package:clack/utility.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/views/video_feed.dart';
import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
  final List<Widget> parentActions;
  final Future Function(BuildContext) onBack;

  const UserInfo(this.authorGetter,
      {this.isCurrentUser = false, this.parentActions, @required this.onBack});

  /// Create a UserInfo for the currently logged-in user.
  static UserInfo currentUser(
          {List<Widget> parentActions,
          @required Future Function(BuildContext) onBack}) =>
      UserInfo(() => API.getLogin().user,
          isCurrentUser: true, parentActions: parentActions, onBack: onBack);

  @override
  _UserInfoState createState() => _UserInfoState();
}

class _UserInfoState extends State<UserInfo>
    with SingleTickerProviderStateMixin {
  /// Text style for an [Author]'s username
  final userTextStyle = TextStyle(fontWeight: FontWeight.bold);

  /// Text style for an [Author]'s stats
  final statsTextStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 20);

  /// Text style for the text under the stats
  ///
  /// Following, Followers, and Hearts
  final softTextStyle =
      TextStyle(color: Colors.grey, fontSize: 12, height: 1.5);

  /// The {Author} to show
  Author _author;

  /// The full details of the author
  Future<AuthorResult> _authorResult;

  /// The [ApiStream]<[VideoResult]> of the [Author]'s videos
  ApiStream<VideoResult> _authorVideos;

  /// The [ApiStream]<[VideoResult]> of the [Author]'s liked videos
  ApiStream<VideoResult> _authorFavoritedVideos;

  /// The actions to show in the appbar.
  ///
  /// Prepends actions from [widget.parentActions]
  List<Widget> _actions;

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

    // Change the AppBar's actions when viewing the current user
    _actions = widget.parentActions != null ? widget.parentActions : [];
    if (!widget.isCurrentUser) {
      _actions.add(IconButton(
          icon: Icon(Icons.share),
          onPressed: () => _authorResult.then((authorResult) {
                Share.share(getAuthorShare(authorResult),
                    subject:
                        "Check out @${authorResult.user.uniqueId} TikTok!");
              })));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the view
    return WillPopScope(
        onWillPop: () => widget.onBack(context),
        child: Scaffold(
            appBar: AppBar(
              title: Text(_author.nickname),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => widget.onBack(context),
              ),
              actions: _actions,
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
                                  // Don't show follow buttons if current user
                                  if (widget.isCurrentUser) return Container();

                                  if (snapshot.connectionState ==
                                          ConnectionState.done &&
                                      snapshot.hasData) {
                                    List<Widget> buttons;

                                    // If we aren't following, offer to follow
                                    if (snapshot.data.user.relation == 0) {
                                      buttons = [
                                        RaisedButton(
                                            onPressed: () =>
                                                showNotImplemented(context),
                                            child: Text("Follow"))
                                      ];
                                    } else {
                                      buttons = [
                                        RaisedButton(
                                            onPressed: () =>
                                                showNotImplemented(context),
                                            child: Text("Message")),
                                        OutlineButton(
                                          onPressed: () =>
                                              showNotImplemented(context),
                                          child: Icon(Icons.playlist_add_check),
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
                                  backgroundColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  forceElevated: innerBoxIsScrolled,
                                  pinned: true,
                                  automaticallyImplyLeading: false,
                                  title: TabBar(
                                    indicator: BoxDecoration(),
                                    labelColor: Theme.of(context)
                                        .textTheme
                                        .headline1
                                        .color,
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
                    body: FutureBuilder(
                        future: _authorResult,
                        builder:
                            (context, AsyncSnapshot<AuthorResult> snapshot) {
                          // Check if we have data to work with
                          if (snapshot.connectionState ==
                                  ConnectionState.done &&
                              snapshot.hasData) {
                            final authorInfo = snapshot.data;

                            // Return the two grid lists
                            return Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: ExtendedTabBarView(
                                    linkWithAncestor: true,
                                    children: [
                                      GridFragment(
                                          stream: _authorVideos,
                                          count: authorInfo.stats.videoCount,
                                          showUserInfo: false,
                                          heroTag: "userVideos"),
                                      GridFragment(
                                          stream: _authorFavoritedVideos,
                                          count: authorInfo.stats.diggCount,
                                          emptyMessage:
                                              "@${authorInfo.user.uniqueId} has hidden their liked videos.",
                                          heroTag: "likedVideos")
                                    ]));
                          } else {
                            // Otherwise, show loading
                            return Center(
                                child: SpinKitFadingGrid(
                              color:
                                  Theme.of(context).textTheme.headline1.color,
                              size: 50,
                            ));
                          }
                        })))));
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
}
