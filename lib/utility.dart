import 'package:clack/api/video_result.dart';
import 'package:clack/views/settings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';

import 'api/author_result.dart';
import 'api/shared_types.dart';

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
String getAuthorShare(AuthorResult authorResult, bool showInfo) =>
    (showInfo
        ? "${authorResult.shareMeta.title} \n${authorResult.shareMeta.desc} \n\n"
        : "") +
    "https://tiktok.com/@${authorResult.user.uniqueId}";

/// Gets a string containing shareable info about a [video]
String getVideoShare(VideoResult video, bool showInfo) =>
    (showInfo
        ? "Check out @${video.author.uniqueId}'s video! \n${video.desc}\n\n"
        : "") +
    "https://www.tiktok.com/@${video.author.uniqueId}/video/${getVideoId(video)}";

// TODO: This needs work, as TT converts the title using more complex rules
/// Gets a string containing shareable info about a [music] track
String getMusicShare(Music music, bool showInfo) =>
    (showInfo ? "Check out videos with the song '${music.title}'!\n\n" : "") +
    "https://www.tiktok.com/music/${music.title.replaceAll(' ', '-').replaceAll(new RegExp(r"[\(\),?!.]"), '')}-${music.id}";

/// Shows a dialog with the text 'NOT IMPLEMENTED'
void showNotImplemented(BuildContext context) => showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("NOT IMPLEMENTED!"),
        content: Text("This feature will (maybe) be added at a later date."),
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
