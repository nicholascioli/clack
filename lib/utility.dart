import 'package:clack/api/hashtag_result.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/generated/locale_keys.g.dart';
import 'package:clack/views/settings.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/author_result.dart';
import 'api/shared_types.dart';

/// Convert a number to locale-relevant compactness
///
/// e.g. in "en-US", 123456 => 123K
NumberFormat statToString(BuildContext ctx) =>
    NumberFormat.compact(locale: ctx.locale.toString());

/// Gets a string containing shareable info about an [authorResult]
String getAuthorShare(AuthorResult authorResult) =>
    "https://www.tiktok.com/@${authorResult.user.uniqueId}";

/// Gets a string containing shareable info about a [video]
String getVideoShare(VideoResult video) =>
    "https://www.tiktok.com/@${video.author.uniqueId}/video/${getVideoId(video)}";

// TODO: This needs work, as TT converts the title using more complex rules
/// Gets a string containing shareable info about a [music] track
String getMusicShare(Music music) =>
    "https://www.tiktok.com/music/${music.title.replaceAll(' ', '-').replaceAll(new RegExp(r"[\(\),?!.]"), '')}-${music.id}";

String getHashtagShare(HashtagResult ht) =>
    "https://www.tiktok.com/tag/${ht.title}";

/// Shows a dialog with the text 'NOT IMPLEMENTED'
void showNotImplemented(BuildContext context) => showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.not_implemented).tr(),
        content: Text(LocaleKeys.not_implemented_msg).tr(),
      ),
    );

ThemeData createTheme(
        {BuildContext context,
        Brightness brightness,
        Color primaryColor,
        Color bottomBarColor,
        Color iconColor}) =>
    new ThemeData(
        accentColor: primaryColor ?? Theme.of(context).accentColor,
        appBarTheme: new AppBarTheme(
            color: primaryColor ?? Theme.of(context).accentColor),
        bottomAppBarColor:
            bottomBarColor ?? Theme.of(context).bottomAppBarColor,
        buttonColor: primaryColor ?? Theme.of(context).accentColor,
        buttonTheme: new ButtonThemeData(
            buttonColor: primaryColor ?? Theme.of(context).accentColor,
            textTheme: ButtonTextTheme.primary),
        brightness: brightness ?? Theme.of(context).brightness,
        toggleableActiveColor: primaryColor ?? Theme.of(context).accentColor,
        accentIconTheme: new IconThemeData(
            color: iconColor ?? Theme.of(context).accentIconTheme.color));

Color valueToColor(int value) {
  // Return nothing if not valid
  if (value == null) return null;

  return Color(value);
}

Color getThemeColor(SharedPreferences prefs, String key) {
  if (key == SettingsView.themePrimaryColor)
    return valueToColor(prefs.getInt(SettingsView.themePrimaryColor)) ??
        Colors.pink;
  else if (key == SettingsView.themeBottomBarColor)
    return valueToColor(prefs.getInt(SettingsView.themeBottomBarColor)) ??
        Colors.black;
  else if (key == SettingsView.themeIconColor)
    return valueToColor(prefs.getInt(SettingsView.themeIconColor)) ??
        Colors.white;
  else
    throw ("Invalid theme color: $key");
}

/// Gets the ID from a [videoResult]
///
/// Note: This is necessary because some videos have two separate
/// IDs, with the nested ID being the correct ID to use for all requests
String getVideoId(VideoResult videoResult) =>
    videoResult.video.id != "awesome" ? videoResult.video.id : videoResult.id;

/// Get a string representation of a time delta
String getDelta(BuildContext context, DateTime created) {
  Duration delta = DateTime.now().difference(created);
  var formatter = new DateFormat.yMd(context.locale.languageCode);

  if (delta.inDays > 30)
    return formatter.format(created);
  else if (delta.inDays != 0)
    return LocaleKeys.day_suffix.tr(args: [delta.inDays.toString()]);
  else if (delta.inHours != 0)
    return LocaleKeys.hour_suffix.tr(args: [delta.inHours.toString()]);
  else if (delta.inMinutes != 0)
    return LocaleKeys.minute_suffix.tr(args: [delta.inMinutes.toString()]);
  else
    return LocaleKeys.second_suffix.tr(args: [delta.inSeconds.toString()]);
}
