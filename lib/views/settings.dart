import 'package:clack/api.dart';
import 'package:clack/fragments/StringSetFragment.dart';
import 'package:clack/generated/locale_keys.g.dart';
import 'package:clack/utility.dart';
import 'package:clack/views/sign_in_webview.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:easy_localization/easy_localization.dart';
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
      appBar: AppBar(title: Text(LocaleKeys.page_settings).tr()),
      body: _prefs == null
          ? Container()
          : SettingsList(
              sections: [
                SettingsSection(
                    title: LocaleKeys.settings_section_account.tr(),
                    tiles: [
                      API.isLoggedIn()
                          ? SettingsTile(
                              title: LocaleKeys.sign_out.tr(),
                              leading: Icon(Icons.exit_to_app),
                              onTap: () => _showLogOutDialog())
                          : SettingsTile(
                              title: LocaleKeys.sign_in.tr(),
                              leading: Icon(Icons.person_outline),
                              onTap: () => Navigator.pushNamed(
                                  context, SignInWebview.routeName),
                            ),

                      // Language selection
                      SettingsTile(
                          title: LocaleKeys.settings_language.tr(),
                          leading: Icon(Icons.translate),
                          subtitle: context.locale.toLanguageTag(),
                          onTap: () => _handleLanguageSelect())
                    ]),
                SettingsSection(
                  title: LocaleKeys.settings_section_video.tr(),
                  tiles: [
                    SettingsTile.switchTile(
                      leading: Icon(Icons.hd),
                      title: LocaleKeys.settings_best_quality.tr(),
                      subtitle: LocaleKeys.settings_best_quality_desc.tr(),
                      onToggle: (value) => _prefs
                          .setBool(SettingsView.videoFullQualityKey, value)
                          .then((_) => setState(() {})),
                      switchValue:
                          _prefs.getBool(SettingsView.videoFullQualityKey),
                    )
                  ],
                ),
                SettingsSection(
                  title: LocaleKeys.settings_section_theme.tr(),
                  tiles: [
                    SettingsTile.switchTile(
                        leading: Icon(Icons.brightness_3),
                        title: LocaleKeys.settings_dark_mode.tr(),
                        subtitle: LocaleKeys.settings_dark_mode_desc.tr(),
                        onToggle: (value) => DynamicTheme.of(context)
                            .setBrightness(
                                value ? Brightness.dark : Brightness.light),
                        switchValue:
                            Theme.of(context).brightness == Brightness.dark),
                    SettingsTile(
                      leading: Icon(Icons.color_lens),
                      title: LocaleKeys.settings_color_primary.tr(),
                      subtitle: LocaleKeys.settings_color_primary_desc.tr(),
                      trailing: Container(
                          // FIXME: This is subpar. But how can we update?
                          key: UniqueKey(),
                          child: ColorIndicator(HSVColor.fromColor(
                              getThemeColor(
                                  _prefs, SettingsView.themePrimaryColor)))),
                      onTap: () => _handleColorPicker(
                          LocaleKeys.settings_color_primary.tr(),
                          getThemeColor(_prefs, SettingsView.themePrimaryColor),
                          (color) => createTheme(
                              context: context, primaryColor: color),
                          SettingsView.themePrimaryColor),
                    ),
                    SettingsTile(
                      leading: Icon(Icons.border_bottom),
                      title: LocaleKeys.settings_color_bottom_bar.tr(),
                      subtitle: LocaleKeys.settings_color_bottom_bar_desc.tr(),
                      trailing: Container(
                          // FIXME: This is subpar. But how can we update?
                          key: UniqueKey(),
                          child: ColorIndicator(HSVColor.fromColor(
                              getThemeColor(
                                  _prefs, SettingsView.themeBottomBarColor)))),
                      onTap: () => _handleColorPicker(
                          LocaleKeys.settings_color_bottom_bar.tr(),
                          getThemeColor(
                              _prefs, SettingsView.themeBottomBarColor),
                          (color) => createTheme(
                              context: context, bottomBarColor: color),
                          SettingsView.themeBottomBarColor),
                    ),
                    SettingsTile(
                      leading: Icon(Icons.home),
                      title: LocaleKeys.settings_color_icon.tr(),
                      subtitle: LocaleKeys.settings_color_icon_desc.tr(),
                      trailing: Container(
                          // FIXME: This is subpar. But how can we update?
                          key: UniqueKey(),
                          child: ColorIndicator(HSVColor.fromColor(
                              getThemeColor(
                                  _prefs, SettingsView.themeIconColor)))),
                      onTap: () => _handleColorPicker(
                          LocaleKeys.settings_color_icon.tr(),
                          getThemeColor(_prefs, SettingsView.themeIconColor),
                          (color) =>
                              createTheme(context: context, iconColor: color),
                          SettingsView.themeIconColor),
                    ),
                  ],
                ),
                SettingsSection(
                  title: LocaleKeys.settings_section_advanced.tr(),
                  tiles: [
                    SettingsTile(
                      title: LocaleKeys.settings_user_agent.tr(),
                      subtitle:
                          _prefs.getString(SettingsView.advancedUserAgentKey),
                      leading: Icon(Icons.public),
                      onTap: () => _showTextDialog(
                              LocaleKeys.settings_user_agent.tr(),
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
                        title: LocaleKeys.settings_reset.tr(),
                        subtitle: LocaleKeys.settings_reset_desc.tr(),
                        leading: Icon(Icons.refresh),
                        onTap: () => _showRefreshDialog())
                  ],
                )
              ],
            ),
    );
  }

  void _handleLanguageSelect() async {
    Locale nextLocale = await showDialog<Locale>(
        context: context,
        builder: (context) {
          Locale selected = context.locale;
          return AlertDialog(
              title: Text(LocaleKeys.settings_language).tr(),
              actions: [
                FlatButton(
                  child: Text(LocaleKeys.cancel).tr(),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
                FlatButton(
                  child: Text(LocaleKeys.accept).tr(),
                  onPressed: () => Navigator.of(context).pop(selected),
                )
              ],
              content: StatefulBuilder(
                builder: (context, setState) => Container(
                    width: double.minPositive,
                    child: ListView.separated(
                        shrinkWrap: true,
                        itemBuilder: (context, index) => RadioListTile<Locale>(
                            title: Text(context.supportedLocales[index]
                                .toLanguageTag()),
                            value: context.supportedLocales[index],
                            groupValue: selected,
                            onChanged: (v) => setState(() => selected = v)),
                        separatorBuilder: (_, __) => Divider(),
                        itemCount: context.supportedLocales.length)),
              ));
        });

    // See if we are switching or not
    if (nextLocale == null || nextLocale == context.locale) return;

    print("SWITCHING LANG TO ${nextLocale.toLanguageTag()}");
    context.locale = nextLocale;

    // Restart the app
    Phoenix.rebirth(context);
  }

  void _handleColorPicker(String title, Color old,
      ThemeData Function(Color color) themeSetter, String prefKey) async {
    Color result = old;
    void Function(Color c, void Function(void Function() innner) refresh)
        setColor = (c, refresh) => refresh(() => result = c);

    bool cancelled = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: StatefulBuilder(
                  builder: (context, refreshView) => SingleChildScrollView(
                          child: Column(children: [
                        MaterialPicker(
                            pickerColor: old,
                            enableLabel: true,
                            onColorChanged: (c) => setColor(c, refreshView)),
                        Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Row(children: [
                              Expanded(
                                  child: Text(LocaleKeys.label_color_selected)
                                      .tr()),
                              Container(
                                  key: UniqueKey(),
                                  child: ColorIndicator(
                                      HSVColor.fromColor(result)))
                            ]))
                      ]))),
              actions: [
                FlatButton(
                  child: Text(LocaleKeys.cancel).tr(),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                FlatButton(
                  child: Text(LocaleKeys.accept).tr(),
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
          title: Text(LocaleKeys.settings_reset).tr(),
          content: Text(LocaleKeys.reset_warning).tr(),
          actions: [
            FlatButton(
              child: Text(LocaleKeys.cancel).tr(),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FlatButton(
              child: Text(LocaleKeys.settings_reset).tr(),
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
        title: Text(LocaleKeys.sign_out).tr(),
        content: Text(LocaleKeys.sign_out_warning).tr(),
        actions: [
          FlatButton(
            child: Text(LocaleKeys.cancel).tr(),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FlatButton(
              child: Text(LocaleKeys.sign_out).tr(),
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
