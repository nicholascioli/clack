import 'package:clack/api/shared_types.dart';
import 'package:clack/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icon_shadow/icon_shadow.dart';

class UserHandleFragment extends StatelessWidget {
  final Author user;
  final TextStyle style;
  final void Function() onTap;
  final InlineSpan extra;
  final bool verifiedOverride;

  const UserHandleFragment(
      {@required this.user,
      @required this.style,
      this.onTap,
      this.extra,
      this.verifiedOverride = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
        text: TextSpan(style: this.style, children: [
      // The username itself, clickable if allowed
      this.onTap != null
          ? WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                  onTap: this.onTap,
                  child: Text(LocaleKeys.user_unique_id, style: this.style)
                      .tr(args: [user.uniqueId])))
          : TextSpan(
              text: LocaleKeys.user_unique_id.tr(args: [user.uniqueId]),
              style: this.style),

      // An optional verified checkmark
      this.user.verified || this.verifiedOverride
          ? WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                  padding: EdgeInsets.only(left: 3),
                  child: IconShadowWidget(
                    Icon(Icons.check_circle,
                        color: Theme.of(context).accentColor),
                    showShadow: this.style.shadows != null,
                    shadowColor: Colors.black,
                  )))
          : TextSpan(),

      // Optional extra text
      this.extra != null ? this.extra : TextSpan()
    ]));
  }
}
