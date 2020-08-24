import 'package:clack/api.dart';
import 'package:clack/fragments/StringSetFragment.dart';
import 'package:clack/utility.dart';
import 'package:clack/views/sign_in_webview.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsView extends StatefulWidget {
  static final String routeName = "/settings";

  // Keys for the preferences
  static final String videoFullQualityKey = "VIDEO_FULL_QUALITY";
  static final String sharingShowInfo = "SHARING_SHOW_INFO";
  static final String themePrimaryColor = "THEME_PRIMARY_COLOR";
  static final String themeBottomBarColor = "THEME_BOTTOM_BAR_COLOR";
  static final String themeIconColor = "THEME_ICON_COLOR";
  static final String advancedUserAgentKey = "ADVANCED_USER_AGENT";

  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  SharedPreferences _prefs;

  @override
  void initState() {
    // Fetch settings
    SharedPreferences.getInstance().then((v) => setState(() => _prefs = v));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: _prefs == null
          ? Container()
          : SettingsList(
              sections: [
                SettingsSection(title: "Account", tiles: [
                  API.isLoggedIn()
                      ? SettingsTile(
                          title: "Sign out",
                          leading: Icon(Icons.exit_to_app),
                          onTap: () => _showLogOutDialog())
                      : SettingsTile(
                          title: "Sign in",
                          leading: Icon(Icons.person_outline),
                          onTap: () => Navigator.pushNamed(
                              context, SignInWebview.routeName),
                        )
                ]),
                SettingsSection(
                  title: "Video",
                  tiles: [
                    SettingsTile.switchTile(
                      leading: Icon(Icons.hd),
                      title: "Always use best quality",
                      subtitle: "Warning: This will use more data",
                      onToggle: (value) => _prefs
                          .setBool(SettingsView.videoFullQualityKey, value)
                          .then((_) => setState(() {})),
                      switchValue:
                          _prefs.getBool(SettingsView.videoFullQualityKey),
                    )
                  ],
                ),
                SettingsSection(
                  title: "Sharing",
                  tiles: [
                    SettingsTile.switchTile(
                        leading: Icon(Icons.share),
                        title: "Share info",
                        subtitle:
                            "Share links with relevant info. Disable to only share the link itself.",
                        onToggle: (value) => _prefs
                            .setBool(SettingsView.sharingShowInfo, value)
                            .then((_) => setState(() {})),
                        switchValue:
                            _prefs.getBool(SettingsView.sharingShowInfo))
                  ],
                ),
                SettingsSection(
                  title: "Theme",
                  tiles: [
                    SettingsTile.switchTile(
                        leading: Icon(Icons.brightness_3),
                        title: "Enable dark mode",
                        subtitle: "Save my retinas!",
                        onToggle: (value) => DynamicTheme.of(context)
                            .setBrightness(
                                value ? Brightness.dark : Brightness.light),
                        switchValue:
                            Theme.of(context).brightness == Brightness.dark),
                    SettingsTile(
                      leading: Icon(Icons.color_lens),
                      title: "Primary Color",
                      subtitle: "Color to use for buttons and themed text",
                      trailing: Container(
                          // FIXME: This is subpar. But how can we update?
                          key: UniqueKey(),
                          child: ColorIndicator(HSVColor.fromColor(
                              getThemeColor(
                                  _prefs, SettingsView.themePrimaryColor)))),
                      onTap: () => _handleColorPicker(
                          "Primary Color",
                          getThemeColor(_prefs, SettingsView.themePrimaryColor),
                          (color) => createTheme(
                              context: context, primaryColor: color),
                          SettingsView.themePrimaryColor),
                    ),
                    SettingsTile(
                      leading: Icon(Icons.border_bottom),
                      title: "Bottom Bar Color",
                      subtitle: "Color to use for the bottom bar",
                      trailing: Container(
                          // FIXME: This is subpar. But how can we update?
                          key: UniqueKey(),
                          child: ColorIndicator(HSVColor.fromColor(
                              getThemeColor(
                                  _prefs, SettingsView.themeBottomBarColor)))),
                      onTap: () => _handleColorPicker(
                          "Bottom Bar Color",
                          getThemeColor(
                              _prefs, SettingsView.themeBottomBarColor),
                          (color) => createTheme(
                              context: context, bottomBarColor: color),
                          SettingsView.themeBottomBarColor),
                    ),
                    SettingsTile(
                      leading: Icon(Icons.home),
                      title: "Bottom Bar Icon Color",
                      subtitle: "Color to use for the bottom bar's icons",
                      trailing: Container(
                          // FIXME: This is subpar. But how can we update?
                          key: UniqueKey(),
                          child: ColorIndicator(HSVColor.fromColor(
                              getThemeColor(
                                  _prefs, SettingsView.themeIconColor)))),
                      onTap: () => _handleColorPicker(
                          "Bottom Bar Icon Color",
                          getThemeColor(_prefs, SettingsView.themeIconColor),
                          (color) =>
                              createTheme(context: context, iconColor: color),
                          SettingsView.themeIconColor),
                    ),
                  ],
                ),
                SettingsSection(
                  title: "Advanced",
                  tiles: [
                    SettingsTile(
                      title: "User Agent",
                      subtitle:
                          _prefs.getString(SettingsView.advancedUserAgentKey),
                      leading: Icon(Icons.public),
                      onTap: () => _showTextDialog(
                              "User Agent",
                              _prefs.getString(
                                      SettingsView.advancedUserAgentKey) ??
                                  API.USER_AGENT)
                          .then((value) {
                        // Ignore when cancelled
                        if (value.isEmpty) return;

                        _prefs
                            .setString(SettingsView.advancedUserAgentKey, value)
                            .then((_) => setState(() {}));
                      }),
                    ),
                    SettingsTile(
                        title: "Reset to Default",
                        subtitle:
                            "Clear all user settings. (Note: Will NOT log you out)",
                        leading: Icon(Icons.refresh),
                        onTap: () => _showRefreshDialog())
                  ],
                )
              ],
            ),
    );
  }

  void _handleColorPicker(String title, Color old,
      ThemeData Function(Color color) themeSetter, String prefKey) async {
    Color result = old;
    void Function(Color c) setColor = (c) {
      result = c;
      print("KILL ME: $result");
    };

    bool cancelled = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: MaterialPicker(
                  pickerColor: old,
                  enableLabel: true,
                  onColorChanged: (c) => setColor(c)),
              actions: [
                FlatButton(
                  child: Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                FlatButton(
                  child: Text("Ok"),
                  onPressed: () => Navigator.of(context).pop(false),
                )
              ],
            ));

    // Do nothing if cancelled
    // Note: The != true is so that a null `cancelled` fails as well
    if (cancelled == true) return;

    // Update the key in the preferences
    await _prefs.setInt(prefKey, result.value);

    // Update the color
    ThemeData newData = themeSetter(result);
    DynamicTheme.of(context).setThemeData(newData);
  }

  void _showRefreshDialog() {
    showDialog(
        context: context,
        child: AlertDialog(
          title: Text("Reset to Default?"),
          content: Text(
              "Are you sure you wish to clear the current settings? Note: This will not log you out of your account."),
          actions: [
            FlatButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FlatButton(
              child: Text("Reset to Default"),
              onPressed: () {
                // Clear the old settings
                _prefs.clear().then((value) => DynamicTheme.of(context)
                    .setThemeData(createTheme(
                        context: context,
                        primaryColor: getThemeColor(
                            _prefs, SettingsView.themePrimaryColor),
                        bottomBarColor: getThemeColor(
                            _prefs, SettingsView.themeBottomBarColor),
                        iconColor:
                            getThemeColor(_prefs, SettingsView.themeIconColor),
                        brightness: SchedulerBinding
                            .instance.window.platformBrightness)));

                // Exit the navigator
                Navigator.of(context).pop();
              },
            )
          ],
        ));
  }

  Future<void> _showLogOutDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Sign Out?"),
        content: Text(
            "Are you sure you want to sign out? After signing out, the app will reload."),
        actions: [
          FlatButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FlatButton(
              child: Text("Sign Out"),
              onPressed: () =>
                  API.logout().then((value) => Phoenix.rebirth(context)))
        ],
      ),
    );
  }

  Future<String> _showTextDialog(String label, String oldValue) async =>
      await showDialog<String>(
          context: context,
          child: StringSetFragment(label: label, initialValue: oldValue));
}
