import 'package:clack/api.dart';
import 'package:clack/api/api_stream.dart';
import 'package:clack/api/author_result.dart';
import 'package:clack/fragments/GridFragment.dart';
import 'package:clack/fragments/ShareFragment.dart';
import 'package:clack/fragments/UserHandleFragment.dart';
import 'package:clack/generated/locale_keys.g.dart';
import 'package:clack/views/full_image.dart';
import 'package:clack/api/shared_types.dart';
import 'package:clack/utility.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/views/video_feed.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';

class UserInfoArgs {
  final Author Function() authorGetter;
  final bool isCurrentUser;
  final List<Widget> parentActions;
  final Future<void> Function(BuildContext) onBack;

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
  bool _isFollowing = false;
  String _nickname = "";

  /// The actions to show in the appbar.
  ///
  /// Prepends actions from [widget.parentActions]
  List<Widget> _actions;

  @override
  void initState() {
    super.initState();

    // Fetch the author's info from the API
    _sparseAuthor = widget.args.authorGetter();
    _authorResult = API.getAuthorInfo(_sparseAuthor);
    _authorResult.then((value) {
      // Do nothing if we died early
      if (!mounted) return;

      setState(() {
        _isFollowing = (value.user.relation != 0);
        _nickname = value.user.nickname;
      });
    });

    // Change the AppBar's actions when viewing the current user
    _actions =
        widget.args.parentActions != null ? widget.args.parentActions : [];
    if (!widget.args.isCurrentUser) {
      _actions.add(
        IconButton(
          icon: Icon(Icons.share),
          onPressed: () => _authorResult.then(
            (authorResult) => ShareFragment.show(
              context,
              url: getAuthorShare(authorResult),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme dependent text color
    final userTextStyle = TextStyle(
        color: Theme.of(context).textTheme.bodyText1.color,
        fontWeight: FontWeight.bold);

    return WillPopScope(
      onWillPop: () => widget.args.onBack(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_sparseAuthor.nickname ?? _nickname),
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
                  _authorFavoritedVideos.setOnChanged(() => setState(() {}));

                  // Start loading the videos
                  _authorVideos.fetch();
                  _authorFavoritedVideos.fetch();

                  // Don't allow this to set the streams again
                  _hasInit = true;
                }

                return NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverList(
                      delegate: SliverChildListDelegate.fixed(
                        [
                          SizedBox(height: 20),
                          // Profile Picture
                          Row(children: [
                            Spacer(),
                            Expanded(
                              child: FullImage.launcher(
                                context: context,
                                url: result.user.avatarLarger.toString(),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: CircleAvatar(
                                    backgroundImage: NetworkImage(
                                        result.user.avatarMedium.toString()),
                                  ),
                                ),
                              ),
                            ),
                            Spacer()
                          ]),

                          // The username
                          SizedBox(height: 10),
                          Column(
                            children: [
                              UserHandleFragment(
                                user: result.user,
                                style: userTextStyle,
                              )
                            ],
                          ),

                          // Social interaction buttons
                          SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatsColumn(
                                  result,
                                  result.stats.followingCount,
                                  LocaleKeys.user_following),
                              _buildStatsColumn(
                                  result,
                                  result.stats.followerCount,
                                  LocaleKeys.user_followers),
                              _buildStatsColumn(result, result.stats.heart,
                                  LocaleKeys.user_hearts)
                            ],
                          ),

                          // Social buttons
                          !widget.args.isCurrentUser && API.isLoggedIn()
                              ? Padding(
                                  padding: EdgeInsets.only(top: 10),
                                  child: Visibility(
                                      child: ButtonBar(
                                          alignment: MainAxisAlignment.center,
                                          children: [
                                            RaisedButton(
                                                onPressed: () =>
                                                    showNotImplemented(context),
                                                child: Text(
                                                        LocaleKeys.send_message)
                                                    .tr()),
                                            OutlineButton(
                                              onPressed: () =>
                                                  showNotImplemented(context),
                                              child: Icon(
                                                  Icons.playlist_add_check),
                                            )
                                          ]),
                                      replacement: ButtonBar(
                                        alignment: MainAxisAlignment.center,
                                        children: [
                                          RaisedButton(
                                            onPressed: () => API
                                                .followAuther(
                                                  result.user,
                                                  !_isFollowing,
                                                )
                                                .then(
                                                  (value) => setState(() =>
                                                      _isFollowing = value),
                                                ),
                                            child: Text(LocaleKeys.label_follow)
                                                .tr(),
                                          ),
                                        ],
                                      ),
                                      visible: _isFollowing))
                              : Container(),

                          // The author's optional signature
                          result.user.signature.isNotEmpty
                              ? Padding(
                                  padding: EdgeInsetsDirectional.only(
                                      start: 30, end: 30, top: 15),
                                  child: Text(
                                    result.user.signature,
                                    style: softTextStyle,
                                    textAlign: TextAlign.center,
                                  ))
                              : Container(),

                          // The optional link to bio
                          ButtonBar(
                              alignment: MainAxisAlignment.center,
                              children: [
                                result.user.bioLink != null
                                    ? Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 50),
                                        child: FlatButton.icon(
                                            icon: Icon(Icons.link),
                                            label: Flexible(
                                                child: Text(
                                                    result.user.bioLink
                                                        .toString(),
                                                    softWrap: false,
                                                    overflow:
                                                        TextOverflow.ellipsis)),
                                            onPressed: () => launch(result
                                                .user.bioLink
                                                .toString())))
                                    : Container()
                              ]),
                        ],
                      ),
                    ),

                    // We need a SliverOverlapAbsorber here so that overlap
                    //    events in the nested child effect the parent
                    //  e.g. Everything scolls together
                    SliverOverlapAbsorber(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                          context),
                      sliver: SliverAppBar(
                        excludeHeaderSemantics: true,
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        forceElevated: innerBoxIsScrolled,
                        pinned: true,
                        automaticallyImplyLeading: false,
                        title: TabBar(
                          indicator: BoxDecoration(),
                          labelColor:
                              Theme.of(context).textTheme.headline1.color,
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
                                      child: !result.user.openFavorite &&
                                              !widget.args.isCurrentUser
                                          ? Icon(
                                              Icons.lock,
                                              size: 12,
                                            )
                                          : null)
                                ]))
                          ],
                        ),
                      ),
                    )
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
                                ? LocaleKeys.user_empty_liked_videos.tr()
                                : LocaleKeys.user_hidden_liked_videos
                                    .tr(args: [result.user.uniqueId]),
                            heroTag: "likedVideos")
                      ],
                    ),
                  ),
                );
              } else {
                return Center(
                    child: SpinKitCubeGrid(
                        color: Theme.of(context).textTheme.headline1.color,
                        size: 50));
              }
            },
          ),
        ),
      ),
    );
  }

  /// Generates a column with a specific [AuthorStat].
  ///
  /// This includes the stat number and a small subtext description
  Widget _buildStatsColumn(AuthorResult result, int stat, String lowerText) =>
      Column(
        children: [
          Text(
            statToString(context).format(stat),
            style: statsTextStyle,
          ),
          Text(
            lowerText,
            style: softTextStyle,
          ).tr()
        ],
      );
}
