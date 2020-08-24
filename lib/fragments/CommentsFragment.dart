import 'package:clack/api/shared_types.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/utility.dart';
import 'package:clack/views/user_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:like_button/like_button.dart';
import 'package:tuple/tuple.dart';

import '../api.dart';

class CommentsFragment extends StatefulWidget {
  final ApiStream<Comment> comments;
  final void Function() onClose;
  final VideoResult owner;
  final int initialCount;

  CommentsFragment(
      {@required this.comments,
      @required this.onClose,
      @required this.owner,
      this.initialCount});

  @override
  _CommentsFragmentState createState() => _CommentsFragmentState();
}

class _CommentsFragmentState extends State<CommentsFragment> {
  final TextEditingController _commentInputController = TextEditingController();
  final FocusNode _textFocus = FocusNode();

  /// A list of every comment's replies and whether some are shown or not
  List<Tuple2<bool, ApiStream>> replies = [];

  @override
  void initState() {
    // Register handler for updating when comments arrive
    widget.comments.setOnChanged(() => setState(() {}));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle titleStyle = TextStyle(
        color: Theme.of(context).textTheme.headline6.color,
        fontWeight: FontWeight.bold);

    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: DraggableScrollableSheet(
            initialChildSize: 1.0,
            minChildSize: 0.5,
            builder: (context, scrollController) => Scaffold(
                  appBar: AppBar(
                    // We do not want a back button
                    automaticallyImplyLeading: false,

                    // Blend in with modal
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,

                    // Center title
                    centerTitle: true,
                    title: Text(
                        "${statToString(widget.comments[0] == null ? widget.initialCount : widget.comments[0].totalCount)} comments",
                        style: titleStyle),

                    // Close modal button
                    actions: [
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: widget.onClose,
                        color: titleStyle.color,
                      )
                    ],
                  ),
                  bottomSheet: _buildCommentInput(context),
                  body: (widget.comments[0] == null)
                      ? Container(
                          child: Center(
                          child: SpinKitCubeGrid(
                              color:
                                  Theme.of(context).textTheme.headline1.color),
                        ))
                      : CustomScrollView(
                          shrinkWrap: true,
                          controller: scrollController,
                          slivers: [
                              SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                      (context, index) => _buildComment(
                                          index, widget.comments[index])))
                            ]),
                )));
  }

  /// Builds the input area
  Widget _buildCommentInput(BuildContext context) {
    return Material(
        type: MaterialType.card,
        elevation: 4,
        child: Container(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            width: double.infinity,
            child: Row(children: [
              Expanded(
                  child: TextField(
                enabled: false,
                controller: _commentInputController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                textInputAction: TextInputAction.send,
                focusNode: _textFocus,
                decoration: InputDecoration(
                    border: InputBorder.none, hintText: "Say something..."),
              )),
              IconButton(
                icon: Icon(Icons.alternate_email),
                onPressed: () => showNotImplemented(context),
              ),
              IconButton(
                  icon: Icon(Icons.insert_emoticon),
                  // onPressed: () => _textFocus.requestFocus()
                  onPressed: () => showNotImplemented(context))
            ])));
  }

  // FIXME: That last argument is nasty
  /// Builds a single comment row
  Widget _buildCommentSliver(int index, Comment comment, bool isReply,
      {bool isSliver = true}) {
    TextStyle dateStyle = TextStyle(color: Colors.grey);
    TextStyle boldStyle = TextStyle(fontWeight: FontWeight.bold);
    TextStyle creatorStyle = TextStyle(color: Theme.of(context).accentColor);

    // TODO: Show loading or something
    if (comment == null) return null;

    var builder = () => Padding(
        padding: EdgeInsets.only(
            left: isReply ? 30 : 0,
            top: isReply ? 5 : 15,
            bottom: isReply ? 5 : 15),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                GestureDetector(
                    onTap: () => _handleViewUser(comment),
                    child: CircleAvatar(
                      backgroundImage:
                          NetworkImage(comment.user.avatarThumb.toString()),
                    )),
                SizedBox(width: 10),
                Expanded(
                    child: Padding(
                        padding: EdgeInsets.only(top: 3, right: 5),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                                onTap: () => _handleViewUser(comment),
                                child: RichText(
                                  text: TextSpan(
                                      text: comment.user.uniqueId,
                                      style: boldStyle,
                                      children: [
                                        comment.user.uniqueId ==
                                                widget.owner.author.uniqueId
                                            ? TextSpan(text: " - ", children: [
                                                TextSpan(
                                                    text: "Creator",
                                                    style: creatorStyle)
                                              ])
                                            : TextSpan()
                                      ]),
                                )),
                            SizedBox(height: 5),
                            RichText(
                                text: TextSpan(
                                    text: comment.text,
                                    style: DefaultTextStyle.of(context).style,
                                    children: [
                                      TextSpan(
                                          text:
                                              " ${_getDelta(comment.createTime)}",
                                          style: dateStyle),
                                    ]),
                                softWrap: true),
                          ],
                        ))),
              ])),
          Padding(
              padding: EdgeInsets.only(top: 10),
              child: LikeButton(
                likeBuilder: (isLiked) => Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey),
                countBuilder: (int count, bool isLiked, String text) {
                  return Text(statToString(count),
                      style: TextStyle(color: Colors.grey));
                },
                likeCountAnimationType: LikeCountAnimationType.none,
                isLiked: comment.userDigged,
                likeCount: comment.diggCount,
                countPostion: CountPostion.bottom,
                likeCountPadding: EdgeInsets.all(0),
                onTap: (previous) {
                  // showNotImplemented(context);
                  return Future.value(!previous);
                },
              ))
        ]));

    return isSliver ? SliverToBoxAdapter(child: builder()) : builder();
  }

  /// Builds a single comment and its optional replies
  Widget _buildComment(int index, Comment comment) {
    TextStyle viewMoreStyle =
        TextStyle(color: Colors.grey, fontWeight: FontWeight.bold);

    // Get the AiStream of replies ready
    if (comment != null && index >= replies.length) {
      replies.add(Tuple2(false, API.getCommentReplyStream(comment, 5)));
      replies[index].item2.autoFetch = false;
      replies[index].item2.setOnChanged(() => setState(() {}));
    }

    if (comment == null) return Container();

    // Do not show the reply comment as a possible extra comment
    int replyCount =
        comment.replyCommentTotal - (comment.replyComment != null ? 1 : 0);

    bool showReplies = replies[index].item1;
    ApiStream<Comment> currentReplies = replies[index].item2;

    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: CustomScrollView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            slivers: [
              // The comment
              _buildCommentSliver(index, comment, false),

              // Its pinned reply
              comment.replyComment != null
                  ? _buildCommentSliver(0, comment.replyComment, true)
                  : SliverToBoxAdapter(child: Container()),

              // Optionally show the results
              showReplies
                  ? SliverList(
                      delegate: SliverChildBuilderDelegate(
                          // Skip the reply comment, oherwise it gets doubled
                          (context, index) => comment.replyComment != null &&
                                  comment.replyComment.cid ==
                                      currentReplies[index].cid
                              ? Container()
                              : _buildCommentSliver(
                                  index, currentReplies[index], true,
                                  isSliver: false),
                          childCount: currentReplies.length))
                  : SliverToBoxAdapter(child: Container()),

              // Show option for replies, if available
              SliverToBoxAdapter(
                  child: replyCount == 0 ||
                          !currentReplies.hasMore ||
                          currentReplies.length == replyCount
                      ? Container()
                      : GestureDetector(
                          onTap: () => setState(() {
                                // Enable the replies
                                if (showReplies == false)
                                  replies[index] =
                                      Tuple2(true, replies[index].item2);

                                // Load the next set
                                currentReplies.fetch();
                              }),
                          child: Padding(
                              padding: EdgeInsets.only(left: 50),
                              child: RichText(
                                  text: TextSpan(
                                      text: !showReplies
                                          ? "View replies (${comment.replyCommentTotal})"
                                          : "View more (${comment.replyCommentTotal - currentReplies.length})",
                                      children: [
                                        WidgetSpan(
                                            alignment:
                                                PlaceholderAlignment.middle,
                                            child: Icon(
                                                currentReplies.isFetching
                                                    ? Icons.sync
                                                    : Icons.keyboard_arrow_down,
                                                color: viewMoreStyle.color,
                                                size: viewMoreStyle.fontSize))
                                      ],
                                      style: viewMoreStyle))))),
            ]));
  }

  void _handleViewUser(Comment comment) =>
      Navigator.of(context).pushNamed(UserInfo.routeName,
          arguments: UserInfoArgs(
            authorGetter: () => comment.user,
            onBack: (ctx) {
              Navigator.of(ctx).pop();
              return Future.value();
            },
          ));

  String _getDelta(DateTime created) {
    Duration delta = DateTime.now().difference(created);
    var formatter = new DateFormat.yMd();

    if (delta.inDays > 30)
      return formatter.format(created);
    else if (delta.inDays != 0)
      return "${delta.inDays}d";
    else if (delta.inHours != 0)
      return "${delta.inHours}h";
    else if (delta.inMinutes != 0)
      return "${delta.inMinutes}m";
    else
      return "${delta.inSeconds}s";
  }
}
