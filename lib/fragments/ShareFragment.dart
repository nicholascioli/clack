import 'dart:io';

import 'package:clack/api.dart';
import 'package:clack/generated/locale_keys.g.dart';
import 'package:dataclass/dataclass.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';

@dataClass
class ShareDownloadInfo {
  final String fileName;
  final Uri url;

  const ShareDownloadInfo({
    @required this.fileName,
    @required this.url,
  });
}

class ShareFragment extends StatelessWidget {
  final String url;
  final ShareDownloadInfo downloadInfo;

  const ShareFragment({
    @required this.url,
    this.downloadInfo,
  });

  static show(
    BuildContext context, {
    @required String url,
    ShareDownloadInfo downloadInfo,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ShareFragment(
        url: url,
        downloadInfo: downloadInfo,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            Icon(Icons.drag_handle, color: Colors.grey),
            SizedBox(height: 20),

            // Link copy
            ListTile(
              title: Text(url),
              trailing: IconButton(
                icon: Icon(Icons.content_copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  Navigator.pop(context);
                },
              ),
            ),
            Divider(),
            SizedBox(height: 20),

            // Other options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Native share menu
                MaterialButton(
                  onPressed: () => Share.share(url),
                  color: Theme.of(context).accentColor,
                  textColor: Colors.white,
                  child: Icon(
                    Icons.share,
                    size: 24,
                  ),
                  padding: EdgeInsets.all(16),
                  shape: CircleBorder(),
                ),

                // Download
                // Note: This is only allowed on Android until I can test on iOS
                Visibility(
                  visible: downloadInfo != null &&
                      Theme.of(context).platform == TargetPlatform.android,
                  child: MaterialButton(
                    onPressed: () async {
                      // Make sure that we can download
                      if ((await _checkPermission()) == false) {
                        // If not, show info to user
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            content: Text(
                              LocaleKeys.download_permission_cancelled,
                            ).tr(),
                            actions: [
                              FlatButton(
                                child: Text(LocaleKeys.accept).tr(),
                                onPressed: () => Navigator.pop(context),
                              )
                            ],
                          ),
                        );

                        return;
                      }

                      await FlutterDownloader.enqueue(
                        url: downloadInfo.url.toString(),
                        savedDir: (await getExternalStorageDirectory()).path,
                        fileName: downloadInfo.fileName,
                        headers: {
                          HttpHeaders.userAgentHeader: API.USER_AGENT,
                          HttpHeaders.refererHeader: "https://www.tiktok.com/",
                        },
                      );

                      Navigator.pop(context);
                    },
                    color: Theme.of(context).accentColor,
                    textColor: Colors.white,
                    child: Icon(
                      Icons.file_download,
                      size: 24,
                    ),
                    padding: EdgeInsets.all(16),
                    shape: CircleBorder(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkPermission() async {
    final status = await Permission.storage.status;
    if (status != PermissionStatus.granted) {
      final result = await Permission.storage.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    } else {
      return true;
    }

    return false;
  }
}
