import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:clack/api/api_stream.dart';
import 'package:clack/api/shared_types.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/fragments/CommentsFragment.dart';
import 'package:clack/fragments/MusicPlayerFragment.dart';
import 'package:clack/fragments/TextWithLinksFragment.dart';
import 'package:clack/fragments/UserHandleFragment.dart';
import 'package:clack/utility.dart';
import 'package:clack/views/sign_in_webview.dart';
import 'package:clack/views/video_group.dart';
import 'package:flutter/material.dart';
import 'package:icon_shadow/icon_shadow.dart';
import 'package:like_button/like_button.dart';
import 'package:marquee/marquee.dart';
import 'package:share/share.dart';
import 'package:wakelock/wakelock.dart';

import '../api.dart';

class VideoPage extends StatefulWidget {
  final VideoResult videoInfo;
  final int index, currentIndex;
  final bool showUserPage;
  final String heroTag;
  final bool forceHd;
  final bool hasBottomBar;

  /// Construct a [VideoPage]
  ///
  /// * [showUserPage] Is this view part of a PageView with the user info page?
  /// * [videoInfo] The info of the video to show
  /// * [index] The index of this video in relation to the owning [VideoFeed]
  /// * [currentIndex] The currently active index in the owning [VideoFeed]
  const VideoPage(
      {Key key,
      @required this.videoInfo,
      @required this.index,
      @required this.currentIndex,
      @required this.hasBottomBar,
      this.showUserPage = true,
      this.heroTag,
      this.forceHd = false})
      : super(key: key);

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage>
    with SingleTickerProviderStateMixin {
  BetterPlayerListVideoPlayerController _controller;
  BetterPlayerDataSource _src;
  BetterPlayerConfiguration _config;

  // BetterPlayer has no way of checking if a list video is playing :(
  bool _playing = true;

  /// Animation controller for the spinning music disk
  AnimationController _animation;

  /// Needed for triggering the heart animation programatically
  final GlobalKey<LikeButtonState> _globalKey = GlobalKey<LikeButtonState>();

  /// Size of the cover art of the [Music] animated button
  final double _musicRadius = 30.0;

  /// Size of the icons in the column of buttons
  final double _iconSize = 40.0;

  /// Whether we have manually liked this video or not
  /// Note: This is needed because VideoResult is final
  bool _manuallyLiked;

  /// Text style of the username text
  TextStyle _usernameTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          offset: Offset(2.0, 2.0),
          blurRadius: 3.0,
          color: Color.fromARGB(255, 0, 0, 0),
        ),
      ]);

  /// Text Style of all of the normal text
  final TextStyle _textStyle =
      TextStyle(color: Colors.white, fontSize: 15, shadows: [
    Shadow(
      offset: Offset(2.0, 2.0),
      blurRadius: 3.0,
      color: Color.fromARGB(255, 0, 0, 0),
    ),
  ]);

  /// Text style of the date
  final TextStyle _dateTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      shadows: [
        Shadow(offset: Offset(2.0, 2.0), blurRadius: 3.0, color: Colors.black)
      ]);

  /// Text style of the text under every button
  final TextStyle subTextStyle =
      TextStyle(color: Colors.white, fontSize: 12, shadows: [
    Shadow(
      offset: Offset(2.0, 2.0),
      blurRadius: 3.0,
      color: Color.fromARGB(255, 0, 0, 0),
    ),
  ]);

  /// A stream of comments for this video
  ApiStream<Comment> _comments;

  @override
  void initState() {
    super.initState();

    // Set up the video
    _controller = BetterPlayerListVideoPlayerController();

    _src = BetterPlayerDataSource(
      BetterPlayerDataSourceType.NETWORK,
      widget.forceHd
          ? widget.videoInfo.video.downloadAddr.toString()
          : widget.videoInfo.video.playAddr.toString(),
      headers: {
        HttpHeaders.userAgentHeader: API.USER_AGENT,
        HttpHeaders.refererHeader: "https://www.tiktok.com/",
      },
    );

    _config = BetterPlayerConfiguration(
      aspectRatio: widget.videoInfo.video.width / widget.videoInfo.video.height,
      autoPlay: true,
      controlsConfiguration: BetterPlayerControlsConfiguration(
        enableFullscreen: false,
        enableMute: false,
        enablePlayPause: false,
        enableProgressBar: false,
        enableProgressText: false,
        showControls: false,
      ),
      eventListener: (event) {
        switch (event.betterPlayerEventType) {
          case BetterPlayerEventType.PLAY:
          case BetterPlayerEventType.PAUSE:
            {
              var isPlaying =
                  event.betterPlayerEventType == BetterPlayerEventType.PLAY;

              // Set / release the wakelock
              Wakelock.isEnabled.then((haveLock) {
                if (!haveLock && isPlaying)
                  Wakelock.enable();
                else if (haveLock && !isPlaying) Wakelock.disable();
              });

              // If we have changed pages, restart our position
              if (widget.currentIndex != widget.index) {
                // Pause the video if it isn't the active page
                if (isPlaying) _controller.pause();

                // Seek to the beginning of the video on page changes
                _controller.seekTo(Duration.zero);
              }

              // Update the playing status
              setState(() => _playing = isPlaying);
              break;
            }
          default:
            {}
        }
      },
      fit: BoxFit.fitWidth,
      looping: true,
      placeholder: Image.network(
        widget.videoInfo.video.originCover.toString(),
        fit: BoxFit.fitWidth,
      ),
      showControlsOnInitialize: false,
    );

    // Set up the animation controller to spin the music button indefinitely
    _animation =
        AnimationController(vsync: this, duration: Duration(seconds: 5));
    _animation.repeat();

    // Copy value to temporary bool
    // Note: We check if null because not all videos have this property...
    _manuallyLiked =
        widget.videoInfo.digged != null ? widget.videoInfo.digged : false;

    // Get the comment stream ready
    _comments = API.getVideoCommentStream(widget.videoInfo, 20);
  }

  @override
  void dispose() {
    // Dispose of the animation
    _animation.stop();
    _animation.dispose();

    // Continue death
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Can this not be handled by the PageView?
    if ((widget.index - widget.currentIndex).abs() > 1) {
      this.dispose();
      return Container();
    }

    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        // The video / image preview
        Hero(
          tag: "${widget.heroTag}_video_page_${widget.index}",
          child: BetterPlayerListVideoPlayer(
            _src,
            configuration: _config,
            betterPlayerListVideoPlayerController: _controller,
          ),
        ),

        // Fullscreen controls
        GestureDetector(
          onTap: () => _playing ? _controller.pause() : _controller.play(),
          onDoubleTap: () => _globalKey.currentState.onTap(),
        ),

        // Info and buttons
        // Note: Padded here to make room for transparent bottom nav bar
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.only(
                left: 5, right: 5, bottom: widget.hasBottomBar ? 36 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(child: _buildTextInfo()),
                _buildButtons(),
              ],
            ),
          ),
        ),

        // Controls when paused
        IgnorePointer(
          child: Visibility(
            visible: !_playing,
            child: Center(
              child: IconShadowWidget(
                Icon(
                  Icons.play_arrow,
                  size: 64,
                  color: Colors.white,
                ),
                shadowColor: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Generates the text description and music info
  Widget _buildTextInfo() => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserHandleFragment(
                user: widget.videoInfo.author,
                style: _usernameTextStyle,
                onTap: () {
                  if (widget.showUserPage)
                    DefaultTabController.of(context).index = 1;
                },
                extra: WidgetSpan(
                    child: Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Text(
                            getDelta(context, widget.videoInfo.createTime),
                            style: _dateTextStyle)))),
            Visibility(
              visible: widget.videoInfo.desc.isNotEmpty,
              child: Padding(
                padding: EdgeInsets.only(top: 20),
                child: TextWithLinksFragment(
                  videoResult: widget.videoInfo,
                  style: _textStyle,
                  context: context,
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(mainAxisSize: MainAxisSize.max, children: [
              IconShadowWidget(
                Icon(
                  Icons.radio,
                  color: Colors.white,
                  size: 30,
                ),
                shadowColor: Colors.black,
              ),
              Expanded(
                  child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      height: _textStyle.fontSize * 1.5,
                      child: Marquee(
                        text:
                            "${widget.videoInfo.music.title} - ${widget.videoInfo.music.authorName}",
                        style: _textStyle,
                        blankSpace: 20.0,
                        velocity: 50.0,
                        pauseAfterRound: Duration(seconds: 2),
                        showFadingOnlyWhenScrolling: false,
                        fadingEdgeStartFraction: 0.1,
                        fadingEdgeEndFraction: 0.1,
                        startPadding: 5.0,
                      )))
            ]),
            SizedBox(height: 20)
          ]);

  Future<bool> _handleDigg(bool previous) async {
    // Show message if not logged in
    if (!API.isLoggedIn()) {
      Scaffold.of(context).showSnackBar(SnackBar(
        backgroundColor: Theme.of(context).bottomAppBarColor,
        content: Text("You must sign in to like a video.",
            style: TextStyle(color: Theme.of(context).accentIconTheme.color)),
        action: SnackBarAction(
          textColor: Theme.of(context).accentColor,
          label: "Sign in",
          onPressed: () =>
              Navigator.pushNamed(context, SignInWebview.routeName),
        ),
      ));
      return Future.value(false);
    }

    // Otherwise, attempt to like the video
    bool newValue = await API.diggVideo(widget.videoInfo, !previous);
    return newValue;
  }

  /// Generates the column of buttons located on the right
  Widget _buildButtons() => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    padding: EdgeInsets.all(0),
                    icon: CircleAvatar(
                      radius: _iconSize / 2,
                      foregroundColor: Colors.white,
                      backgroundImage: NetworkImage(
                          widget.videoInfo.author.avatarThumb.toString()),
                    ),
                    onPressed: () {
                      if (widget.showUserPage)
                        DefaultTabController.of(context).index = 1;
                    }),
                SizedBox(
                  height: 20,
                ),
                LikeButton(
                    key: _globalKey,
                    isLiked: _manuallyLiked,
                    padding: EdgeInsets.zero,
                    likeCountPadding: EdgeInsets.zero,
                    likeBuilder: (bool isLiked) => IconShadowWidget(
                        Icon(
                          Icons.favorite,
                          color: isLiked ? Colors.red : Colors.white,
                          size: _iconSize,
                        ),
                        shadowColor: Colors.black),
                    size: _iconSize,
                    onTap: _handleDigg),
                Text(
                    statToString(context)
                        .format(widget.videoInfo.stats.diggCount),
                    textAlign: TextAlign.center,
                    style: subTextStyle),
                SizedBox(
                  height: 20,
                ),
                IconButton(
                    padding: EdgeInsets.all(0),
                    icon: IconShadowWidget(
                        Icon(Icons.comment,
                            size: _iconSize, color: Colors.white),
                        shadowColor: Colors.black),
                    onPressed: () => _showComments()),
                Text(
                    statToString(context)
                        .format(widget.videoInfo.stats.commentCount),
                    textAlign: TextAlign.center,
                    style: subTextStyle),
                SizedBox(
                  height: 20,
                ),
                IconButton(
                  padding: EdgeInsets.all(0),
                  icon: IconShadowWidget(
                      Icon(Icons.share, size: _iconSize, color: Colors.white),
                      shadowColor: Colors.black),
                  onPressed: () => Share.share(getVideoShare(widget.videoInfo)),
                ),
                Text(
                    statToString(context)
                        .format(widget.videoInfo.stats.shareCount),
                    textAlign: TextAlign.center,
                    style: subTextStyle),
                SizedBox(
                  height: 40,
                ),
              ],
            ),
            GestureDetector(
                onTap: () {
                  // Open the page
                  Navigator.pushNamed(context, VideoGroup.routeName,
                      arguments: VideoGroupArguments(
                          stream:
                              API.getVideosForMusic(widget.videoInfo.music, 20),
                          headerBuilder: () => MusicPlayerFragment(
                              musicInfo: widget.videoInfo.music),
                          getShare: () =>
                              getMusicShare(widget.videoInfo.music)));
                },
                child: AnimatedBuilder(
                  animation: _animation,
                  child: CircleAvatar(
                    radius: _musicRadius,
                    backgroundImage: NetworkImage(
                        widget.videoInfo.music.coverThumb.toString()),
                  ),
                  builder: (BuildContext context, Widget _widget) {
                    return new Transform.rotate(
                      angle: _animation.value * 6.3,
                      child: _widget,
                    );
                  },
                )),
            SizedBox(height: 20)
          ]);

  void _showComments() {
    if (!API.isLoggedIn()) {
      Scaffold.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.black,
        content: Text("You must sign in to view comments.",
            style: TextStyle(color: Theme.of(context).accentIconTheme.color)),
        action: SnackBarAction(
          textColor: Theme.of(context).accentColor,
          label: "Sign in",
          onPressed: () =>
              Navigator.pushNamed(context, SignInWebview.routeName),
        ),
      ));
      return;
    }

    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: Scaffold.of(context).context,
        isScrollControlled: true,
        builder: (ctx) => CommentsFragment(
            comments: _comments,
            onClose: () => Navigator.pop(ctx),
            owner: widget.videoInfo,
            initialCount: widget.videoInfo.stats.commentCount));
  }
}
