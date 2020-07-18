import 'package:dataclass/dataclass.dart';
import 'package:clack/api/shared_types.dart';

/// Stats relating to an [Author]
///
/// This is a subset of the results of an [AuthorResult] and includes info
/// such as follower count, heart count, etc.
@dataClass
class AuthorStats {
  final int followingCount;
  final int followerCount;
  final int heartCount;
  final int videoCount;
  final int diggCount;
  final int heart;

  AuthorStats(
      {this.followingCount,
      this.followerCount,
      this.heartCount,
      this.videoCount,
      this.diggCount,
      this.heart});

  /// Construct an [AuthorStats] object from a supplied [json] object.
  ///
  /// The members of said JSON object must include every field by name.
  factory AuthorStats.fromJson(Map<String, dynamic> json) {
    return AuthorStats(
        followingCount: json["followingCount"],
        followerCount: json["followerCount"],
        heartCount: json["heartCount"],
        videoCount:
            json["videoCount"] - 1, // For some reason, they give us max + 1?
        diggCount: json["diggCount"],
        heart: json["heart"]);
  }
}

/// An [Author]'s full info
///
/// See [API.getAuthorInfo()].
@dataClass
class AuthorResult {
  /// The [Author]'s brief info
  ///
  /// This field is labelled 'user' to match the API results of TT. It is,
  /// however, very much an [Author].
  final Author user;

  /// The [AuthorStats] for this [Author]
  final AuthorStats stats;

  /// The [ShareMeta] for this [Author]
  final ShareMeta shareMeta;

  AuthorResult({this.user, this.stats, this.shareMeta});

  /// Construct an [AuthorResult] object from a supplied [json] object.
  ///
  /// The members of said JSON object must include every field by name.
  factory AuthorResult.fromJson(Map<String, dynamic> json) {
    return AuthorResult(
        user: Author.fromJson(json["user"]),
        stats: AuthorStats.fromJson(json["stats"]),
        shareMeta: ShareMeta.fromJson(json["shareMeta"]));
  }
}
