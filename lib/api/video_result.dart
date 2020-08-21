import 'package:clack/api/shared_types.dart';
import 'package:dataclass/dataclass.dart';

/// Stats related to a video.
///
/// This is a subset of results of a [VideoResult] object. It includes info
/// such as the comment count, play count, etc.
@dataClass
class VideoStats {
  /// The total number of comments for this video
  ///
  /// The comments themselves must be fetched with [API.getVideoCommentStream()].
  final int commentCount;

  /// The amount of likes (heart icon) for this video
  final int diggCount;

  /// The amount of play-throughs for this video
  final int playCount;

  /// The amount of times this video has been shared
  final int shareCount;

  VideoStats(
      {this.commentCount, this.diggCount, this.playCount, this.shareCount});

  /// Construct a [VideoStat] from a supplied [json] object.
  ///
  /// The members of said JSON object must include every field by name.
  factory VideoStats.fromJson(Map<String, dynamic> json) {
    return VideoStats(
        commentCount: json["commentCount"],
        diggCount: json["diggCount"],
        playCount: json["playCount"],
        shareCount: json["shareCount"]);
  }
}

/// A [Video]'s full info.
@dataClass
class VideoResult {
  /// Internal ID
  final String id;

  /// The time that this video was created
  final DateTime createTime;

  /// The description of this video
  final String desc;

  /// The owning [Author]
  final Author author;

  /// The [Music] used in this video
  final Music music;

  /// The [Video] itself
  final Video video;

  /// Stats related to this video
  final VideoStats stats;

  /// Whether or not the current user has liked this video
  final bool digged;

  VideoResult(
      {this.id,
      this.createTime,
      this.desc,
      this.author,
      this.music,
      this.video,
      this.stats,
      this.digged});

  /// Construct a [VideoResult] from a supplied [json] object.
  ///
  /// The members of said JSON object must include every field by name.
  factory VideoResult.fromJson(Map<String, dynamic> json) {
    return VideoResult(
        id: json["id"],
        createTime: DateTime.fromMillisecondsSinceEpoch(json["createTime"]),
        desc: json["desc"],
        author: Author.fromJson(json["author"]),
        music: Music.fromJson(json["music"]),
        video: Video.fromJson(json["video"]),
        stats: VideoStats.fromJson(json["stats"]),
        digged: json["digged"]);
  }
}
