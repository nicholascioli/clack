import 'package:clack/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SignInWebview extends StatelessWidget {
  static final String routeName = "/log_in";
  final FlutterSecureStorage storage = new FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Log in"),
      ),
      body: InAppWebView(
        initialUrl: "https://m.tiktok.com/login",
        initialOptions: API.webViewOptions,

        // Here, we look for the cookie 'sid_guard'. Once found, we kill the
        //   webview since we have successfully logged in.
        onLoadStop: (controller, url) async {
          // See if we have the information yet
          Map<String, dynamic> data =
              await controller.evaluateJavascript(source: "__NEXT_DATA__");

          // Quit early otherwise
          if (data == null) return;

          Map<String, dynamic> base = data["query"]["\$initialProps"];
          String uniqueId = base["\$user"]["uniqueId"];
          String webId = base["\$wid"];
          Cookie token = await CookieManager.instance()
              .getCookie(url: url, name: "sid_guard");
          String lang = base["\$language"];

          // Save the cookie and ID
          await API.login(token, webId, uniqueId, lang);

          // Reload the app so that the video streams reload
          controller.loadUrl(url: "");
          _showLogInDialog(context);
        },
      ),
    );
  }

  Future<void> _showLogInDialog(BuildContext ctx) async {
    return showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Success!"),
        content: Text("You are now logged in. Press OK to reload."),
        actions: [
          FlatButton(
              child: Text("OK"), onPressed: () => Phoenix.rebirth(context)),
        ],
      ),
    );
  }
}
