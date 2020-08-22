import 'package:clack/api/shared_types.dart';
import 'package:clack/utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:like_button/like_button.dart';

import '../api.dart';

class CommentsFragment extends StatefulWidget {
  final ApiStream<Comment> comments;
  final void Function() onClose;

  CommentsFragment({@required this.comments, @required this.onClose});

  @override
  _CommentsFragmentState createState() => _CommentsFragmentState();
}

class _CommentsFragmentState extends State<CommentsFragment> {
  TextStyle _countStyle =
      TextStyle(color: Colors.black, fontWeight: FontWeight.bold);

  @override
  void initState() {
    // Register handler for updating when comments arrive
    widget.comments.setOnChanged(() => setState(() {}));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: DraggableScrollableSheet(
            initialChildSize: 1.0,
            builder: (context, scrollController) => Scaffold(
                appBar: AppBar(
                  // We do not want a back button, so empty container
                  leading: Container(),

                  // Blend in with modal, so white
                  backgroundColor: Colors.white,

                  // Center title and make it black
                  centerTitle: true,
                  title: (widget.comments[0] == null)
                      ? null
                      : Text("${widget.comments[0].totalCount} comments",
                          style: _countStyle),

                  // Close modal button
                  actions: [
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: widget.onClose,
                      color: Colors.black,
                    )
                  ],
                ),
                body: (widget.comments[0] == null)
                    ? Container(
                        color: Colors.white,
                        child: Center(
                          child: SpinKitCubeGrid(color: Colors.black),
                        ))
                    : ListView.builder(
                        shrinkWrap: true,
                        controller: scrollController,
                        itemCount: widget.comments[0].totalCount,
                        itemBuilder: (ctx, index) => _buildComment(index)))));
  }

  Widget _buildComment(int index) {
    Comment comment = widget.comments[index];
    TextStyle dateStyle = TextStyle(color: Colors.grey);
    TextStyle viewMoreStyle =
        TextStyle(color: Colors.grey, fontWeight: FontWeight.bold);

    // TODO: Show loading or something
    if (comment == null) return null;

    return Padding(
        padding: EdgeInsets.all(10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            backgroundImage: NetworkImage(comment.user.avatarThumb.toString()),
          ),
          SizedBox(width: 10),
          Expanded(
              child: Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comment.user.uniqueId, style: _countStyle),
                      SizedBox(height: 5),
                      RichText(
                          text: TextSpan(
                              text: comment.text,
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                TextSpan(
                                    text: " ${_getDelta(comment.createTime)}",
                                    style: dateStyle),
                              ]),
                          softWrap: true),
                      SizedBox(height: 10),
                      Text("View replies (${comment.replyCommentTotal})",
                          style: viewMoreStyle)
                    ],
                  ))),
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
  }

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
