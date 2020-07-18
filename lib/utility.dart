import 'package:clack/api/video_result.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import 'api/author_result.dart';

/// Convert a numerical stat into a friendly string.
///
/// Divides numbers into 3 categories and then rounds to 1 decimal place:
/// * k (1,000)
/// * m (1,000,000)
/// * b (1,000,000,000)
///
/// ex. 12,345,678 -> 12.3m
String statToString(int stat) {
  const billion = 1000000000;
  const million = 1000000;
  const thousand = 1000;

  // Default is to show full number with no suffix
  Tuple2<int, String> scaleFactor = Tuple2(1, "");
  if (stat > billion)
    scaleFactor = Tuple2(billion, "b");
  else if (stat > million)
    scaleFactor = Tuple2(million, "m");
  else if (stat > thousand) scaleFactor = Tuple2(thousand, "k");

  return "${(stat / scaleFactor.item1).toStringAsFixed(scaleFactor.item2.isEmpty ? 0 : 1)}${scaleFactor.item2}";
}

/// Gets a string containing shareable info about an [authorResult]
String getAuthorShare(AuthorResult authorResult) =>
    "${authorResult.shareMeta.title} \n${authorResult.shareMeta.desc} \n\nhttps://tiktok.com/@${authorResult.user.uniqueId}";

/// Gets a string containing shareable info about a [video]
String getVideoShare(VideoResult video) =>
    "Check out @${video.author.uniqueId}'s video! \n${video.desc}\n\nhttps://www.tiktok.com/@${video.author.uniqueId}/video/${video.id}";

/// Shows a dialog with the text 'NOT IMPLEMENTED'
void showNotImplemented(BuildContext context) => showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("NOT IMPLEMENTED!"),
        content: Text("This feature will (maybe) be added at a later date."),
      ),
    );
