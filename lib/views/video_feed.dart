import 'package:clack/api.dart';
import 'package:clack/utility.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/views/discover.dart';
import 'package:clack/views/notifications_view.dart';
import 'package:clack/views/profile_view.dart';
import 'package:clack/views/settings.dart';
import 'package:clack/views/user_info.dart';
import 'package:clack/views/video_page.dart';
import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which page to show in the left page of the [VideoFeed]
enum VideoFeedActivePage { VIDEO, SEARCH, NOTIFICATION, PROFILE }

/// Optional Arguments for constructing a [VideoFeed]
///
/// When used, signals that this [VideoFeed] is nested.
class VideoFeedArgs {
  /// The stream from which to fetch videos
  final ApiStream<VideoResult> stream;

  /// Which index to fetch from first
  final int startIndex;

  /// How many videos this feed should show
  ///
  /// When nested, this is typically how many videos an [Author] has or
  /// has liked.
  final int length;

  /// Whether or not to show the side page with author info
  ///
  /// This side page is shown optionally when browsing a video that is not nested
  /// in a users profile. By default, we show the page.
  final bool showUserInfo;

  /// Hero tag for animation transition
  ///
  /// Hero tags must be unique between views, so specify a unique prefix if
  /// multiple video lists are shown
  final String heroTag;

  const VideoFeedArgs(this.stream, this.startIndex, this.length,
      {this.showUserInfo = true, this.heroTag = ""});
}

/// A view showing a feed of videos and other options
///
/// This view is composed of a:
/// * [ViewPager] of [VideoPages]
/// * [Search]
/// * [UserInfo] of an [Author]
///
/// The [UserInfo] page is available to the right if this [VideoFeed] is not
/// nested and if the active page is the [ViewPager]. The user can switch
/// between the [ViewPager] and the other views by using the bottom bar of
/// buttons.
class VideoFeed extends StatefulWidget {
  static const routeName = "/video_feed";

  @override
  _VideoFeedState createState() => _VideoFeedState();
}

class _VideoFeedState extends State<VideoFeed> {
  /// The [ApiStream]<[VideoResult]> of trending videos
  ///
  /// This will always be the trending videos, but should be updated to
  /// eventually show the 'ForYou' page.
  ApiStream<VideoResult> _videos = API.getTrendingStream(30);

  /// The currently active [VideoPage]
  int _currentIndex = 0;

  /// The length of the [VideoFeed]. If set to null, indicates an endless list
  int _length;

  /// Is this [VideoFeed] nested?
  ///
  /// This is passed to the child [VideoPage] for showing a back button if
  /// nested and for disabling both the Bottom button bar and adjacent [UserInfo]
  /// when nested.
  bool _isNested = false;

  /// Has this [VideoFeed] initialized?
  ///
  /// This is needed because arguments to named routes cannot be extracted
  /// in the [initState()] method.
  bool _hasInit = false;

  /// Whether or not to show the user info page
  bool _showUserInfo = true;

  /// Are we currently on the Video page?
  ///
  /// This is used for disabling the [UserInfoPage] whenever
  /// we have switched to another page using the bottom navigation bar.
  bool _onVideoPage = true;

  String _heroTag = "";

  /// Needed for choosing video quality
  SharedPreferences _prefs;

  /// The page to show on the left tab
  VideoFeedActivePage _activePage = VideoFeedActivePage.VIDEO;

  @override
  void initState() {
    // Get the preferences
    SharedPreferences.getInstance()
        .then((value) => setState(() => _prefs = value));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Extract video and video stream, if present
    final VideoFeedArgs args = ModalRoute.of(context).settings.arguments;
    if (args != null && !this._hasInit) {
      this._videos = args.stream;
      this._currentIndex = args.startIndex;
      this._length = args.length;
      this._isNested = true;
      this._showUserInfo = args.showUserInfo;
      this._heroTag = args.heroTag;
    }
    this._hasInit = true;

    // Update view whenever new data from network
    this._videos.setOnChanged(() => setState(() {}));

    // Return the view
    return (this._showUserInfo && this._onVideoPage)
        ? _buildVideos()
        : _buildVideoWithBar();
  }

  /// Generates the TabView containing the variable left page and [UserInfo] right page
  Widget _buildVideos() => DefaultTabController(
        length: 2,
        // Here we use an [ExtendedTabBarView] so that the nested tab view
        // can scroll this parent
        child: ExtendedTabBarView(children: [
          _buildVideoWithBar(),
          UserInfo(
              args: UserInfoArgs(
            authorGetter: () => _videos[_currentIndex].author,
            onBack: (ctx) =>
                Future.value(DefaultTabController.of(ctx).index = 0),
          ))
        ]),
      );

  /// Generates the multi-page left tab
  Widget _buildVideoWithBar() {
    final cb = (v) => setState(() => _activePage = v);
    final views = Map.from({
      VideoFeedActivePage.VIDEO: () => _buildVideoPager(),
      VideoFeedActivePage.SEARCH: () => Discover(cb),
      VideoFeedActivePage.NOTIFICATION: () => NotificationView(cb),
      VideoFeedActivePage.PROFILE: () => ProfileView(cb)
    });
    return Scaffold(
        // We need the appBar to only show here when we have the videoPager, so that
        //   the back button appears when we are nested
        appBar: _isNested
            ? AppBar(backgroundColor: Colors.transparent, elevation: 0)
            : null,
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.black,
        bottomNavigationBar: !_isNested ? _buildBottomBar() : null,
        resizeToAvoidBottomInset: _activePage != VideoFeedActivePage.VIDEO,
        body: views[_activePage]());
  }

  /// Builds just the [VideoPage] [ViewPager]
  Widget _buildVideoPager() => RefreshIndicator(
      onRefresh: () async => await _videos.refresh(),
      child: PageView.builder(
        controller: PageController(keepPage: false, initialPage: _currentIndex),
        scrollDirection: Axis.vertical,
        itemCount: _length,
        itemBuilder: (context, i) {
          // Show loading symbol if we are awaiting API response
          final VideoResult v = _videos[i];
          if (v == null || _prefs == null) {
            return Center(child: SpinKitWave(color: Colors.white, size: 50.0));
          } else {
            return VideoPage(
                showUserPage: _showUserInfo,
                videoInfo: _videos[i],
                index: i,
                currentIndex: _currentIndex,
                heroTag: _heroTag,
                forceHd: _prefs.getBool(SettingsView.videoFullQualityKey));
          }
        },
        onPageChanged: (page) {
          print("MOVING: $page");

          // FIXME: This is slightly nasty. Is there no other way?
          setState(() => _currentIndex = page);
        },
      ));

  /// Builds the bottom bar used for navigating the left tab
  Widget _buildBottomBar() {
    /// Builds a specific [icon] tab which sets the [active] page when clicked
    final buildTab = (IconData icon, VideoFeedActivePage active,
            {void Function() afterClick}) =>
        IntrinsicWidth(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
              iconSize: 30,
              padding: EdgeInsets.all(2),
              icon: Icon(icon, color: Theme.of(context).accentIconTheme.color),
              onPressed: () {
                // Allow for switching between the states
                print("PUSHED! Setting from $_activePage to $active");

                // Change only when different
                if (_activePage != active) {
                  setState(() {
                    _activePage = active;

                    // Disable tabbing if not on the main page
                    this._onVideoPage =
                        _activePage == VideoFeedActivePage.VIDEO;
                  });
                }

                // If we have an action to do post-change, do so now
                if (afterClick != null) afterClick();
              }),
          _activePage == active
              ? Divider(
                  color: Theme.of(context).accentIconTheme.color,
                  height: 2,
                  thickness: 2,
                )
              : Container(height: 2)
        ]));

    return BottomAppBar(
        elevation: 0,
        child: ButtonBar(
          alignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildTab(Icons.home, VideoFeedActivePage.VIDEO,
                afterClick: () =>
                    _videos.refresh().then((value) => setState(() {}))),
            buildTab(Icons.search, VideoFeedActivePage.SEARCH),
            IconButton(
                iconSize: 45,
                padding: EdgeInsets.all(2),
                icon: Icon(Icons.block, color: Colors.red),
                onPressed: () => showNotImplemented(context)),
            buildTab(
                Icons.notifications_none, VideoFeedActivePage.NOTIFICATION),
            buildTab(Icons.person_outline, VideoFeedActivePage.PROFILE)
          ],
        ));
  }
}
