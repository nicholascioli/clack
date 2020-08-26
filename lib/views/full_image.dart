import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// Arguments passed to construct a [FullImage]
class FullImageArgs {
  final String imageUrl;
  const FullImageArgs(this.imageUrl);
}

/// A view containing a full-screen image
///
/// This view can be scaled freely and is dismissable by either tapping
/// the image or hitting back.
class FullImage extends StatelessWidget {
  static const routeName = "/full_image";

  static const String heroTag = "full_image";

  static Widget launcher(
          {@required Widget child,
          @required BuildContext context,
          @required String url}) =>
      Hero(
          tag: heroTag,
          child: GestureDetector(
              onTap: () => Navigator.of(context)
                  .pushNamed(routeName, arguments: FullImageArgs(url)),
              child: child));

  @override
  Widget build(BuildContext context) {
    // Grab arguments from named route
    FullImageArgs args = ModalRoute.of(context).settings.arguments;

    return Scaffold(
        body: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: PhotoView(
        imageProvider: NetworkImage(args.imageUrl),
        minScale: PhotoViewComputedScale.contained,
        heroAttributes: PhotoViewHeroAttributes(
            tag: FullImage.heroTag, transitionOnUserGestures: true),
      ),
    ));
  }
}
