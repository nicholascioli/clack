import 'package:clack/api/shared_types.dart';
import 'package:dataclass/dataclass.dart';

enum NotificationType {
  ANNOUNCEMENT,
  FOLLOW,
}

Map<int, NotificationType> toNotificationType = {
  1: NotificationType.ANNOUNCEMENT,
  33: NotificationType.FOLLOW,
};

@dataClass
class NotificationResult {
  /// ???
  final int userId;

  /// ???
  final int nId;

  /// When this notification was created
  final DateTime createTime;

  /// Whether this notification has been marked as read by the user
  final bool hasRead;

  const NotificationResult({
    this.userId,
    this.nId,
    this.createTime,
    this.hasRead,
  });

  NotificationResult.json(Map<String, dynamic> json)
      : this(
          userId: json["user_id"],
          nId: json["nid"],
          createTime:
              DateTime.fromMillisecondsSinceEpoch(json["create_time"] * 1000),
          hasRead: json["has_read"],
        );

  factory NotificationResult.fromJson(Map<String, dynamic> json) {
    int type = json["type"];

    switch (toNotificationType[type]) {
      case NotificationType.ANNOUNCEMENT:
        return AnnouncementNotification.fromJson(json);
      case NotificationType.FOLLOW:
        return FollowNotification.fromJson(json);
      default:
        print(
            "WARNING: Unknown notification type! $type -> ${toNotificationType[type]}");
        return UnknownNotification(raw: json);
    }
  }
}

@dataClass
class UnknownNotification extends NotificationResult {
  final Map<String, dynamic> raw;

  const UnknownNotification({this.raw});
}

@dataClass
class AnnouncementNotification extends NotificationResult {
  /// Title of the announcement
  final String title;

  /// ???
  final String content;

  /// The type of announcement
  /// Note: No idea what these values mean. 0 appears to mean SYSTEM
  final int announcementType;

  /// Url to more info
  /// Note: No idea where to fetch this info...
  final Uri schemaUrl;

  const AnnouncementNotification({
    this.title,
    this.content,
    this.announcementType,
    this.schemaUrl,
  });

  AnnouncementNotification.json({
    Map<String, dynamic> json,
    this.title,
    this.content,
    this.announcementType,
    this.schemaUrl,
  }) : super.json(json);

  factory AnnouncementNotification.fromJson(Map<String, dynamic> json) {
    var ann = json["announcement"];

    return AnnouncementNotification.json(
      json: json,
      title: ann["title"],
      content: ann["content"],
      announcementType: ann["type"],
      schemaUrl: Uri.parse(ann["schema_url"]),
    );
  }
}

@dataClass
class FollowNotification extends NotificationResult {
  /// The user who has followed us
  final Author fromUser;

  /// ???
  final String content;

  const FollowNotification({
    this.fromUser,
    this.content,
  });

  FollowNotification.json({
    Map<String, dynamic> json,
    this.fromUser,
    this.content,
  }) : super.json(json);

  factory FollowNotification.fromJson(Map<String, dynamic> json) {
    var follow = json["follow"];
    var author = follow["from_user"];

    return FollowNotification.json(
      json: json,
      fromUser: Author(
        id: author["uid"],
        secUid: author["sec_uid"],
        avatarLarger: Uri.parse(author["avatar_larger"]["url_list"][0]),
        avatarMedium: Uri.parse(author["avatar_300x300"]["url_list"][0]),
        avatarThumb: Uri.parse(author["avatar_thumb"]["url_list"][0]),
        uniqueId: author["unique_id"],
        nickname: author["nickname"],
        signature: "",
        openFavorite: false,
        verified: author["verification_type"] == 1,
        relation: author["follow_status"],
      ),
      content: follow["content"],
    );
  }
}
