import 'package:clack/api.dart';
import 'package:clack/api/author_result.dart';
import 'package:clack/fragments/GridFragment.dart';
import 'package:clack/views/full_image.dart';
import 'package:clack/api/shared_types.dart';
import 'package:clack/utility.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/views/settings.dart';
import 'package:clack/views/video_feed.dart';
import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserInfoArgs {
  final Author Function() authorGetter;
  final bool isCurrentUser;
  final List<Widget> parentActions;
  final Future Function(BuildContext) onBack;

  const UserInfoArgs(
      {@required this.authorGetter,
      this.isCurrentUser = false,
      this.parentActions,
      @required this.onBack});
}

/// Contains all info about an [Author]
///
/// This includes their profile picture, username, stats, and all
/// of their videos and liked videos (if available). Tapping on the profile
/// picture opens it in a [FullImage] while tapping on any of the video
/// thumbnails opens up a new [VideoFeed] showing only their videos.
class UserInfo extends StatefulWidget {
  static const routeName = "/user_info";

  final UserInfoArgs args;

  const UserInfo({@required this.args});

  /// Create a UserInfo for the currently logged-in user.
  static UserInfo currentUser(
          {List<Widget> parentActions,
          @required Future Function(BuildContext) onBack}) =>
      UserInfo(
          args: UserInfoArgs(
              authorGetter: () => API.getLogin().user,
              isCurrentUser: true,
              parentActions: parentActions,
              onBack: onBack));

  static UserInfo fromNamed(BuildContext ctx) =>
      UserInfo(args: ModalRoute.of(ctx).settings.arguments);

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
  Author _sparseAuthor;

  /// The full details of the author
  Future<AuthorResult> _authorResult;

  ApiStream<VideoResult> _authorVideos;
  ApiStream<VideoResult> _authorFavoritedVideos;
  bool _hasInit = false;

  /// The actions to show in the appbar.
  ///
  /// Prepends actions from [widget.parentActions]
  List<Widget> _actions;

  /// The preferences for this app
  SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();

    // Fetch the author's info from the API
    _sparseAuthor = widget.args.authorGetter();
    _authorResult = API.getAuthorInfo(_sparseAuthor);

    // Change the AppBar's actions when viewing the current user
    _actions =
        widget.args.parentActions != null ? widget.args.parentActions : [];
    if (!widget.args.isCurrentUser) {
      _actions.add(IconButton(
          icon: Icon(Icons.share),
          onPressed: () => _authorResult.then((authorResult) {
                Share.share(
                    getAuthorShare(authorResult,
                        _prefs.getBool(SettingsView.sharingShowInfo)),
                    subject:
                        "Check out @${authorResult.user.uniqueId} TikTok!");
              })));
    }

    // Get the prefs
    SharedPreferences.getInstance()
        .then((value) => setState(() => _prefs = value));
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
      onWillPop: () => widget.args.onBack(context),
      child: Scaffold(
          appBar: AppBar(
            title: Text(_sparseAuthor.nickname),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => widget.args.onBack(context),
            ),
            actions: _actions,
          ),
          body: DefaultTabController(
              length: 2,
              // Here we wrap in a NestedScrollView so that the nested Grid
              //   view containing the videos can be scrolled together with the
              //   general user info.
              child: FutureBuilder(
                future: _authorResult,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    AuthorResult result = snapshot.data;

                    if (!_hasInit) {
                      // Fetch the author's video stream
                      _authorVideos = API.getAuthorVideoStream(result.user, 40);
                      _authorFavoritedVideos =
                          API.getAuthorFavoritedVideoStream(result.user, 40);

                      _authorVideos.setOnChanged(() => setState(() {}));
                      _authorFavoritedVideos
                          .setOnChanged(() => setState(() {}));

                      // Start loading the videos
                      _authorVideos.fetch();
                      _authorFavoritedVideos.fetch();

                      // Don't allow this to set the streams again
                      _hasInit = true;
                    }

                    return NestedScrollView(
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
                                              arguments: FullImageArgs(result
                                                  .user.avatarLarger
                                                  .toString())),
                                          // Here we use a [Hero] so that the thumbnail can
                                          // animate to and back from the [FullImage] when tapped
                                          child: Hero(
                                              tag: "full_image",
                                              child: AspectRatio(
                                                  aspectRatio: 1,
                                                  child: CircleAvatar(
                                                    backgroundImage:
                                                        NetworkImage(result
                                                            .user.avatarMedium
                                                            .toString()),
                                                  ))))),
                                  Spacer()
                                ]),
                                (result.user.verified
                                    ? Row(children: [
                                        Spacer(),
                                        Padding(
                                            padding: EdgeInsets.only(
                                                top: 10, bottom: 5),
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
                                    Text("@${result.user.uniqueId}",
                                        style: userTextStyle)
                                  ],
                                ),
                                SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatsColumn(
                                        result,
                                        result.stats.followingCount,
                                        "Following"),
                                    _buildStatsColumn(
                                        result,
                                        result.stats.followerCount,
                                        "Followers"),
                                    _buildStatsColumn(
                                        result, result.stats.heart, "Hearts")
                                  ],
                                ),
                                SizedBox(height: 10),
                                FutureBuilder(
                                    future: _authorResult,
                                    builder: (context,
                                        AsyncSnapshot<AuthorResult> snapshot) {
                                      // Don't show follow buttons if current user
                                      if (widget.args.isCurrentUser)
                                        return Container();

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
                                              child: Icon(
                                                  Icons.playlist_add_check),
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
                                      result.user.signature,
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
                                      backgroundColor: Theme.of(context)
                                          .scaffoldBackgroundColor,
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
                                                  alignment:
                                                      Alignment.bottomRight,
                                                  children: [
                                                Icon(Icons.favorite_border),
                                                Padding(
                                                    padding: EdgeInsets.only(
                                                        bottom: 3),
                                                    child: !result.user
                                                                .openFavorite &&
                                                            !widget.args
                                                                .isCurrentUser
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
                                  GridFragment(
                                      stream: _authorVideos,
                                      count: result.stats.videoCount,
                                      showUserInfo: false,
                                      heroTag: "userVideos"),
                                  GridFragment(
                                      stream: _authorFavoritedVideos,
                                      count: result.stats.diggCount,
                                      emptyMessage: widget.args.isCurrentUser
                                          ? "Liked videos will show up here."
                                          : "@${result.user.uniqueId} has hidden their liked videos.",
                                      heroTag: "likedVideos")
                                ])));
                  } else {
                    return Center(
                        child: SpinKitCubeGrid(
                            color: Theme.of(context).textTheme.headline1.color,
                            size: 50));
                  }
                },
              ))));

  /// Generates a column with a specific [AuthorStat].
  ///
  /// This includes the stat number and a small subtext description
  Widget _buildStatsColumn(AuthorResult result, int stat, String lowerText) =>
      Column(
        children: [
          Text(
            statToString(stat),
            style: statsTextStyle,
          ),
          Text(
            lowerText,
            style: softTextStyle,
          )
        ],
      );
}
