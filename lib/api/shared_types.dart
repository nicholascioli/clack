import 'package:dataclass/dataclass.dart';

/// A brief overview of a TT author.
///
/// This info is typically a subset of the results for most requests. See
/// [AuthorResult] for a more complete overview of an [Author].
@dataClass
class Author {
  /// Internal ID
  final String id;

  /// Secondary ID used for certain requests
  final String secUid;

  /// The username of the [Author].
  final String uniqueId;

  /// Full-quality version of an [Author]'s profile picture
  final Uri avatarLarger;

  /// Compressed version of an [Author]'s profile picture
  final Uri avatarMedium;

  /// Thumbnail version of an [Author]'s profile picture
  final Uri avatarThumb;

  /// Friendly nickname. [Author] configurable.
  final String nickname;

  /// Signature / Tagline. [Author] configurable.
  final String signature;

  /// Whether an [Author]'s liked videos are publicly available.
  ///
  /// See [API.getAuthorFavoritedVideoStream()] for more info.
  final bool openFavorite;

  /// Whether an [Author] is verified.
  final bool verified;

  /// The relation of this [Author] to the currently active user
  ///
  /// Possible values:
  /// - 0 => No one is following each other
  /// - 1 => You are following this user
  /// - 2 => You and this user are following each other
  final int relation;

  /// A link to this author's bio
  ///
  /// WARNING: This links through TT's servers. They _will_ track you
  /// using this link.
  final Uri bioLink;

  Author(
      {this.id,
      this.secUid,
      this.uniqueId,
      this.avatarLarger,
      this.avatarMedium,
      this.avatarThumb,
      this.nickname,
      this.signature,
      this.openFavorite,
      this.verified,
      this.relation,
      this.bioLink});

  /// Construct an [Author] from a supplied [json] object.
  ///
  /// The members of said JSON object must include every field by name.
  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
        id: json["id"],
        secUid: json["secUid"],
        uniqueId: json["uniqueId"],
        avatarLarger: Uri.parse(json["avatarLarger"]),
        avatarMedium: Uri.parse(json["avatarMedium"]),
        avatarThumb: Uri.parse(json["avatarThumb"]),
        nickname: json["nickname"],
        signature: json["signature"],
        openFavorite: json["openFavorite"],
        verified: json["verified"],
        relation: json["relation"],
        bioLink: json.containsKey("bioLink")
            ? Uri.parse(json["bioLink"]["link"])
            : null);
  }
}

/// Details of a TT music object
@dataClass
class Music {
  /// Internal ID
  final String id;

  /// The name of the owning [Author]
  final String authorName;

  /// The title of the music track
  final String title;

  /// A full-quality version of the cover art
  final Uri coverLarge;

  /// A compressed version of the cover art
  final Uri coverMedium;

  /// A thumbnail version of the cover art
  final Uri coverThumb;

  /// The URL for streaming the music track
  final Uri playUrl;

  /// Whether this music track is original to an author
  final bool original;

  /// The amount of videos that have this music
  ///
  /// Note: Not all requests have this. See [API.getMusicInfo]
  final int videoCount;

  const Music(
      {this.id,
      this.authorName,
      this.title,
      this.coverLarge,
      this.coverMedium,
      this.coverThumb,
      this.playUrl,
      this.original,
      this.videoCount});

  /// Construct a [Music] object from a supplied [json] object.
  ///
  /// The members of said JSON object must include every field by name.
  factory Music.fromJson(Map<String, dynamic> json, {int videoCount}) {
    return Music(
        id: json["id"],
        authorName: json["authorName"],
        title: json["title"],
        coverLarge: Uri.parse(json["coverLarge"]),
        coverMedium: Uri.parse(json["coverMedium"]),
        coverThumb: Uri.parse(json["coverThumb"]),
        playUrl: Uri.parse(json["playUrl"]),
        original: json["original"],
        videoCount: videoCount);
  }
}

/// Brief details of a TT video object.
///
/// This info is typically a subset of the results for most video requests.
/// For more info on a video, refer to [VideoResult].
@dataClass
class Video {
  /// Internal ID
  final String id;

  /// Width of the Video, in pixels
  final int width;

  /// Height of the Video, in pixels
  final int height;

  /// The duration of the video in seconds(?)
  final int duration; // TODO: Is this in seconds?

  /// The ratio of the video as a string.
  ///
  /// Contrary to what you would expect, this is a string describing the
  /// resolution of the video. ex. "720p".
  final String ratio;

  /// URL to a compressed image of the first frame of the video
  final Uri cover;

  /// URL to a GIF of a segment of the video
  final Uri dynamicCover;

  /// URL to the original quality image of the first frame of the video
  final Uri originCover; // Original quality frame

  /// URL to a compressed version of the video
  final Uri playAddr;

  /// URL to the full-quality version of the video
  final Uri downloadAddr;

  /// Whether or not the video is originally of this author
  final bool isOriginal;

  Video(
      {this.id,
      this.width,
      this.height,
      this.duration,
      this.ratio,
      this.cover,
      this.dynamicCover,
      this.originCover,
      this.playAddr,
      this.downloadAddr,
      this.isOriginal});

  /// Construct a [Video] object from a supplied [json] object.
  ///
  /// The members of said JSON object must include every field by name.
  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
        id: json["id"],
        width: json["width"],
        height: json["height"],
        duration: json["duration"],
        ratio: json["ratio"],
        cover: Uri.parse(json["cover"]),
        dynamicCover: Uri.parse(json["dynamicCover"]),
        originCover: Uri.parse(json["originCover"]),
        playAddr: Uri.parse(json["playAddr"]),
        downloadAddr: Uri.parse(json["downloadAddr"]),
        isOriginal: json["isOriginal"]);
  }
}

/// Shareable info of an [Author]
@dataClass
class ShareMeta {
  /// The title of the author
  ///
  /// This includes (typically) the [Author.uniqueId] and [AuthorStats].
  final String title;

  /// The [signature] line of an [Author].
  final String desc;

  ShareMeta({this.title, this.desc});

  /// Construct a [ShareMeta] object from a supplied [json] object.
  ///
  /// The members of said JSON object must include every field by name.
  factory ShareMeta.fromJson(Map<String, dynamic> json) {
    return ShareMeta(title: json["title"], desc: json["desc"]);
  }
}

/// A comment for a specific [VideoResult]
@dataClass
class Comment {
  /// Internal ID
  final String cid;

  /// The comment's message
  final String text;

  /// Internal mapped ID
  /// Note: Original is aweme_id
  final String awemeId;

  /// Time the comment was posted
  /// Note: Original is create_time
  final DateTime createTime;

  /// How many likes this comment has received
  /// Note: Original is digg_count
  final int diggCount;

  /// ?
  final int status;

  /// Stripped User info
  final Author user;

  /// ???
  /// Note: Original is reply_id
  final String replyId;

  /// Whether or not the current user has liked this comment
  /// Note: Original is user_digged
  final bool userDigged;

  /// ??? Possibly the reply to show?
  /// Note: Original is reply_comment
  final Comment replyComment;

  /// How many replies this comment has
  /// Note: Original is reply_comment_total
  final int replyCommentTotal;

  /// Whether or not the author of the original video liked this post.
  /// Note: Original is is_author_digged
  final bool isAuthorDigged;

  /// ???
  /// Note: Original is user_burried
  final bool userBuried;

  Comment(
      {this.cid,
      this.text,
      this.awemeId,
      this.createTime,
      this.diggCount,
      this.status,
      this.user,
      this.replyId,
      this.userDigged,
      this.replyComment,
      this.replyCommentTotal,
      this.isAuthorDigged,
      this.userBuried});

  factory Comment.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> user = json["user"];

    return Comment(
        cid: json["cid"],
        text: json["text"],
        awemeId: json["aweme_id"],
        createTime: DateTime.fromMillisecondsSinceEpoch(
            json["create_time"] * 1000), // Timestamp is in seconds
        diggCount: json["digg_count"],
        status: json["status"],
        user: Author(
            id: user["id"],
            nickname: user["nickname"],
            avatarThumb: Uri.parse(user["avatar_thumb"]["url_list"][0]),
            uniqueId: user["unique_id"],
            secUid: user["sec_uid"],

            // TODO: Figure out if this is always the case
            verified:
                user["custom_verify"] != null && user["custom_verify"] != ""),
        replyId: json["reply_id"],
        userDigged: json["user_digged"] == 1,
        replyComment:
            json.containsKey("reply_comment") && json["reply_comment"] != null
                ? Comment.fromJson(json["reply_comment"][0])
                : null,
        // This is optional for replies (sub-comments)
        replyCommentTotal: json.containsKey("reply_comment_total")
            ? json["reply_comment_total"]
            : 0,
        isAuthorDigged: json["is_author_digged"] == 1,
        userBuried: json["user_buried"] == 1);
  }
}

@dataClass
class TextExtra {
  /// The internal ID for this resource
  final String awemeId;

  /// The start position in the desc string
  final int start;

  /// The end position in the desc string
  final int end;

  /// The name of the hashtag, if present
  final String hashtagName;

  /// The ID of the hashtag, if present
  final String hashtagId;

  /// The type of TextExtra
  ///
  /// Note: 0 seems to mean USER while 1 means HASHTAG
  final int type;

  /// The User ID, if present
  final String userId;

  /// The User's uniqueId, if present
  final String userUniqueId;

  /// The User's secUid, if present
  final String secUid;

  const TextExtra(
      {this.awemeId,
      this.start,
      this.end,
      this.hashtagName,
      this.hashtagId,
      this.type,
      this.userId,
      this.userUniqueId,
      this.secUid});

  factory TextExtra.fromJson(Map<String, dynamic> json) {
    // Warning: TT is dumb and changes case for no reason
    dynamic Function(String) getter = (key) => json.containsKey(key)
        ? json[key]
        : json[key[0].toUpperCase() + key.substring(1)];

    return TextExtra(
        awemeId: getter("awemeId"),
        start: getter("start"),
        end: getter("end"),
        hashtagName: getter("hashtagName"),
        hashtagId: getter("hashtagId"),
        type: getter("type"),
        userId: getter("userId"),
        userUniqueId: getter("userUniqueId"),
        secUid: getter("secUid"));
  }
}
