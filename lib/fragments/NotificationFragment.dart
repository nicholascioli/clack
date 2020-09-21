import 'package:clack/api.dart';
import 'package:clack/api/notification_result.dart';
import 'package:clack/generated/locale_keys.g.dart';
import 'package:clack/utility.dart';
import 'package:clack/views/user_info.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NotificationFragment extends StatelessWidget {
  final NotificationResult notification;

  const NotificationFragment({@required this.notification});

  @override
  Widget build(BuildContext context) {
    switch (notification.runtimeType) {
      case UnknownNotification:
        UnknownNotification un = notification;
        return _buildBody(
          context,
          date: DateTime.now(),
          leading: CircleAvatar(child: Icon(Icons.help)),
          content: Text(un.raw.toString()),
        );
      case AnnouncementNotification:
        AnnouncementNotification ann = notification;
        return _buildBody(
          context,
          date: ann.createTime,
          leading: CircleAvatar(child: Icon(Icons.info)),
          title: Text(LocaleKeys.notification_announcement_title).tr(),
          content: Text(ann.title),
        );
      case FollowNotification:
        FollowNotification fn = notification;
        return _buildBody(
          context,
          date: fn.createTime,
          onTap: () => Navigator.pushNamed(
            context,
            UserInfo.routeName,
            arguments: UserInfoArgs(
              authorGetter: () => fn.fromUser,
              onBack: (ctx) {
                Navigator.of(ctx).pop();
                return Future.value();
              },
            ),
          ),
          leading: CircleAvatar(
              backgroundImage:
                  NetworkImage(fn.fromUser.avatarThumb.toString())),
          title: Text(LocaleKeys.notification_follow_title)
              .tr(args: [fn.fromUser.uniqueId]),
          trailing: RaisedButton(
              child: Text(fn.fromUser.relation == 0
                      ? LocaleKeys.label_follow
                      : LocaleKeys.label_followed)
                  .tr(),
              onPressed: fn.fromUser.relation == 0
                  ? () => API.followAuther(fn.fromUser, true)
                  : null),
        );
      default:
        throw UnimplementedError("Invalid Notification type! $notification");
    }
  }

  Widget _buildBody(
    BuildContext context, {
    DateTime date,
    Widget leading,
    Widget title,
    Widget content,
    Widget trailing,
    void Function() onTap,
  }) =>
      Card(
        child: ListTile(
          onTap: onTap,
          leading: leading,
          title: title,
          subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(getDelta(context, date)),
                Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: content,
                    ) ??
                    SizedBox.shrink(),
              ]),
          trailing: trailing,
        ),
      );
}
