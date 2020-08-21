import 'package:clack/api.dart';
import 'package:clack/utility.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/views/sound_group.dart';
import 'package:flutter/material.dart';
import 'package:icon_shadow/icon_shadow.dart';
import 'package:marquee/marquee.dart';
import 'package:share/share.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

/// VideoPage
///
/// A single video shown in the VideoFeed
///
/// Note: We need to keep track of the owning video, so we
/// require the creator to pass in a [VideoResult].
class VideoPage extends StatefulWidget {
  final VideoResult videoInfo;
  final int index, currentIndex;
  final bool showUserPage;
  final String heroTag;

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
      this.showUserPage = true,
      this.heroTag})
      : super(key: key);

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage>
    with SingleTickerProviderStateMixin {
  VideoPlayerController _controller;
  AnimationController _animation;

  bool _manuallyLiked;
  bool _manuallyPaused = false;

  /// Size of the icons in the column of buttons
  final double _iconSize = 40.0;

  /// Size of the cover art of the [Music] animated button
  final double _musicRadius = 30.0;

  /// Text Style of all of the normal text
  final TextStyle _textStyle =
      TextStyle(color: Colors.white, fontSize: 15, shadows: [
    Shadow(
      offset: Offset(2.0, 2.0),
      blurRadius: 3.0,
      color: Color.fromARGB(255, 0, 0, 0),
    ),
  ]);

  /// Text style of the username text
  final TextStyle _usernameTextStyle = TextStyle(
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

  /// Text style of the text under every button
  final TextStyle subTextStyle =
      TextStyle(color: Colors.white, fontSize: 12, shadows: [
    Shadow(
      offset: Offset(2.0, 2.0),
      blurRadius: 3.0,
      color: Color.fromARGB(255, 0, 0, 0),
    ),
  ]);

  // TODO: Implement a comment stream for fetching this video's comments
  // ApiStream<dynamic> _comments;

  @override
  void initState() {
    super.initState();

    // Set up the [VideoController] to play (and loop) this video
    _setupVideo(widget.videoInfo);

    // Make sure that we WakeLock if there is a video playing. We disable on dispose
    _controller.addListener(() => Wakelock.isEnabled.then((haveLock) {
          if (!haveLock && _controller.value.isPlaying)
            Wakelock.enable();
          else if (haveLock && !_controller.value.isPlaying) Wakelock.disable();
        }));

    // Set up the animation controller to spin the music button indefinitely
    _animation =
        AnimationController(vsync: this, duration: Duration(seconds: 5));
    _animation.repeat();

    // Copy value to temporary bool
    // Note: We check if null because not all videos have this property...
    _manuallyLiked =
        widget.videoInfo.digged != null ? widget.videoInfo.digged : false;

    // Get the comment stream ready
    // _comments = API.getVideoCommentStream(widget.videoInfo, 20);
  }

  @override
  void dispose() {
    // Pause any playing videos
    _controller.pause();

    // Make sure to release the WakeLock, if we have it
    Wakelock.disable();

    // Dispose of the controller, if it exist
    _controller.dispose();

    // Dispose of the animation
    _animation.stop();
    _animation.dispose();

    // Continue death
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(),
      backgroundColor: Colors.black,
    );
  }

  /// Builds the entire page
  Widget _buildPage() {
    // Handle auto-playing when set as the active page
    if (_controller.value.initialized) {
      if (widget.index != widget.currentIndex)
        _controller.pause();
      else if (!_manuallyPaused) _controller.play();
    }

    // Create the view
    return Stack(children: [
      // First child is the video or thumbnail, depending on whether or not
      //   the video has loaded
      // Note: This is wrapped in a [Hero] so that this [VideoPage] can animate
      //   between itself and any page that shows an overview of videos.
      Hero(
          tag: "${widget.heroTag}_video_page_${widget.index}",
          child: ClipRect(
              child: OverflowBox(
                  maxHeight: double.infinity,
                  child: AspectRatio(
                      aspectRatio: widget.videoInfo.video.width /
                          widget.videoInfo.video.height,
                      child: _controller.value.initialized
                          ? GestureDetector(
                              onTap: () => setState(() {
                                    if (_controller.value.isPlaying) {
                                      _controller.pause();
                                      _manuallyPaused = true;
                                    } else {
                                      _controller.play();
                                      _manuallyPaused = false;
                                    }
                                  }),
                              child: VideoPlayer(_controller))
                          : Image.network(widget.videoInfo.video.originCover
                              .toString()))))),
      // Then we show relevant text info
      Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(child: _buildTextInfo()),
                    _buildButtons(),
                  ]))),
      // Then we (optionally) show the controls
      Align(
        alignment: Alignment.center,
        child: !_controller.value.isPlaying
            ? IconShadowWidget(
                Icon(
                  Icons.play_arrow,
                  size: 80,
                  color: Colors.white,
                ),
                shadowColor: Colors.black,
              )
            : Container(),
      )
    ]);
  }

  /// Generates the text description and music info
  Widget _buildTextInfo() => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "@${widget.videoInfo.author.uniqueId}",
              style: _usernameTextStyle,
            ),
            (widget.videoInfo.desc.isNotEmpty
                ? SizedBox(height: 20)
                : Container()),
            Text(
              widget.videoInfo.desc,
              style: _textStyle,
              softWrap: true,
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
                IconButton(
                    padding: EdgeInsets.all(0),
                    icon: IconShadowWidget(
                        Icon(Icons.favorite,
                            size: _iconSize,
                            color: _manuallyLiked ? Colors.red : Colors.white),
                        shadowColor: Colors.black),
                    onPressed: () => API
                        .diggVideo(widget.videoInfo, !_manuallyLiked)
                        .then(
                            (value) => setState(() => _manuallyLiked = value))),
                Text(statToString(widget.videoInfo.stats.diggCount),
                    textAlign: TextAlign.center, style: subTextStyle),
                SizedBox(
                  height: 20,
                ),
                IconButton(
                    padding: EdgeInsets.all(0),
                    icon: IconShadowWidget(
                        Icon(Icons.comment,
                            size: _iconSize, color: Colors.white),
                        shadowColor: Colors.black),
                    onPressed: () => showNotImplemented(context)),
                Text(statToString(widget.videoInfo.stats.commentCount),
                    textAlign: TextAlign.center, style: subTextStyle),
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
                Text(statToString(widget.videoInfo.stats.shareCount),
                    textAlign: TextAlign.center, style: subTextStyle),
                SizedBox(
                  height: 40,
                ),
              ],
            ),
            GestureDetector(
                onTap: () {
                  // Stop the video
                  _manuallyPaused = true;
                  _controller.pause();

                  // Open the page
                  Navigator.pushNamed(context, SoundGroup.routeName,
                      arguments: SoundGroupArguments(
                          API.getVideosForMusic(widget.videoInfo.music, 20)));
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

  /// Sets up the [VideoController] to autoplay and loop the [vid]
  void _setupVideo(VideoResult vid) async {
    // If we have somehow run this with the same video, then do nothing
    if (_controller != null &&
        _controller.dataSource == vid.video.downloadAddr.toString()) return;

    // Make a new one using the VideoResult
    var oldController = _controller;
    _controller =
        VideoPlayerController.network(vid.video.downloadAddr.toString());
    oldController?.pause()?.then((value) => oldController.dispose());

    // Initialize the video so that it may start playing
    _controller.initialize().then((value) => setState(() {}));

    // Configure the video to loop indefinitely and start playback
    _controller.setLooping(true);
    _controller.play();
  }
}
