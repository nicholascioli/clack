import 'package:clack/api/api_stream.dart';
import 'package:clack/api/hashtag_result.dart';
import 'package:clack/api/shared_types.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/utility.dart';
import 'package:clack/views/user_info.dart';
import 'package:clack/views/video_feed.dart';
import 'package:clack/views/video_group.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import 'HashtagInfoFragment.dart';

class TextWithLinksFragment extends StatelessWidget {
  final VideoResult videoResult;
  final TextStyle style;
  final BuildContext context;
  final void Function() onTap;

  const TextWithLinksFragment(
      {this.videoResult, this.style, this.context, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Generate all of the links + text
    List<TextSpan> hyperlinks =
        videoResult.textExtra.asMap().map(_buildHyperlink).values.toList();

    // Just show the normal text if it has no hyperlinks
    if (hyperlinks.length == 0)
      return Text(this.videoResult.desc, style: style);

    return RichText(text: TextSpan(children: hyperlinks, style: style));
  }

  MapEntry<int, TextSpan> _buildHyperlink(int index, TextExtra info) {
    final int lastEnd = index != 0 ? videoResult.textExtra[index - 1].end : 0;
    final bool isDuet = info.awemeId != null && info.awemeId.isNotEmpty;
    final String innerText = videoResult.desc.substring(info.start, info.end);
    final duetStyle =
        TextStyle(color: Colors.black, fontWeight: FontWeight.bold);

    return MapEntry(
        index,
        TextSpan(children: [
          TextSpan(
              text: videoResult.desc.substring(lastEnd, info.start),
              style: style),
          WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                  onTap: () async {
                    // Call parent onTap first
                    onTap();

                    if (isDuet) {
                      // final videoInfo = await API.getVideoInfo(info.awemeId);
                      // TODO: Convert to named
                      Navigator.of(context).pushNamed(VideoFeed.routeName,
                          arguments: VideoFeedArgs(
                              ApiStream(
                                1,
                                (count, cursor) async => ApiResult(false, 0,
                                    [await API.getVideoInfo(info.awemeId)]),
                              ),
                              0,
                              1));
                    } else if (info.type == 1) {
                      HashtagResult ht =
                          await API.getHashtagInfo(info.hashtagName);

                      Navigator.of(context).pushNamed(VideoGroup.routeName,
                          arguments: VideoGroupArguments(
                              stream: API.getVideosForHashtag(ht, 20),
                              headerBuilder: () => HashtagInfoFragment(
                                    initialHashtag: ht,
                                    initialIsActual: true,
                                  ),
                              getShare: (shareExtra) =>
                                  getHashtagShare(ht, shareExtra)));
                    } else {
                      Navigator.of(context).pushNamed(UserInfo.routeName,
                          arguments: UserInfoArgs(
                              authorGetter: () =>
                                  Author(uniqueId: info.userUniqueId),
                              onBack: (ctx) {
                                Navigator.of(ctx).pop();
                                return;
                              }));
                    }
                  },
                  child: isDuet
                      ? Card(
                          elevation: 0,
                          color: Colors.grey,
                          child: Padding(
                              padding: EdgeInsets.only(right: 5),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_arrow,
                                        color: duetStyle.color),
                                    Text(innerText, style: duetStyle),
                                  ])))
                      : Text(innerText,
                          style: style.apply(
                              decoration: TextDecoration.underline))))
        ]));
  }
}
