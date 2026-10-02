/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_link.dart
/// Purpose: Declares `VideoLink` — turns the link an admin pastes into one
///          the video player can actually stream.
/// Author: ASEC team
/// Created: 30/9/2026
///
/// GOOGLE DRIVE
/// ------------
/// A Drive "share" link (drive.google.com/file/d/{id}/view…) opens Google's
/// viewer PAGE, not the video, so the player cannot play it. The same file is
/// streamed from
///   https://drive.usercontent.google.com/download?id={id}&export=download&confirm=t
/// `confirm=t` skips the "can't scan this file for viruses" page Drive shows
/// for large files, and that host answers range requests, so seeking works.
///
/// The file must be shared as "Anyone with the link → Viewer", otherwise
/// Drive answers with a sign-in page and the player shows its error.
///
/// Every other link is returned unchanged. The link is converted when it is
/// PLAYED, not when it is saved, so the Drive link the admin pasted stays in
/// the form and can be opened in Drive as before.

abstract final class VideoLink {
  static final RegExp _filePath = RegExp(r'/file/d/([A-Za-z0-9_-]{10,})');

  /// The Drive file id in [url], or null when it is not a Drive file link.
  ///
  /// Accepts every shape Drive hands out:
  ///   drive.google.com/file/d/{id}/view?usp=sharing
  ///   drive.google.com/file/d/{id}/preview
  ///   drive.google.com/open?id={id}
  ///   drive.google.com/uc?id={id}&export=download
  ///   drive.usercontent.google.com/download?id={id}
  static String? driveId(String url) {
    final Uri? uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
    final String host = uri.host.toLowerCase();
    if (host != 'drive.google.com' &&
        host != 'docs.google.com' &&
        host != 'drive.usercontent.google.com') {
      return null;
    }
    final RegExpMatch? m = _filePath.firstMatch(uri.path);
    if (m != null) return m.group(1);
    final String? id = uri.queryParameters['id'];
    return (id != null && id.length >= 10) ? id : null;
  }

  static bool isDrive(String url) => driveId(url) != null;

  /// The cover image Drive makes for a video file (a frame from it), or
  /// null for a link that is not a Drive file. Works for files shared
  /// "Anyone with the link"; [width] is the size asked for, in pixels.
  static String? thumbnail(String url, {int width = 640}) {
    final String? id = driveId(url);
    if (id == null) return null;
    return 'https://drive.google.com/thumbnail?id=$id&sz=w$width';
  }

  /// The address to hand to the player.
  static String playable(String url) {
    final String? id = driveId(url);
    if (id == null) return url.trim();
    return 'https://drive.usercontent.google.com/download'
        '?id=$id&export=download&confirm=t';
  }
}
