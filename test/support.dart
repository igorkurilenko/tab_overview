// What the overview's tests share: pumping frames and flights, pulling a
// page down at a speed, and telling where widgets are and what the screen
// shows.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

/// A frame's time at 60 frames a second.
const oneFrame = Duration(milliseconds: 16);

/// Pumps [frames] frames, a frame's time apart.
Future<void> pumpFrames(WidgetTester tester, int frames) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(oneFrame);
  }
}

/// Pumps the frames of the flight [controller] is about to start or has
/// under way: the frame of the switch, then a frame at a time until no tab
/// flies. Calls [onFrame] after each of those, and returns what it returned.
Future<List<R>> pumpFlight<R>(
  WidgetTester tester,
  TabOverviewController<Object?> controller,
  FutureOr<R> Function() onFrame,
) async {
  final results = <R>[];
  await tester.pump();
  while (controller.isTransitioning) {
    await tester.pump(oneFrame);
    results.add(await onFrame());
  }
  return results;
}

/// Drags down from [at] by each of [moves] in turn, a frame apart, each
/// time-stamped, so the drag is let go of at the speed its last moves give
/// it: a move of 0 holds it still.
Future<void> pullDown(
  WidgetTester tester,
  Offset at,
  Iterable<double> moves,
) async {
  final gesture = await tester.startGesture(at);
  var time = Duration.zero;
  for (final dy in moves) {
    time += oneFrame;
    await gesture.moveBy(Offset(0, dy), timeStamp: time);
    await tester.pump(oneFrame);
  }
  await gesture.up(timeStamp: time);
}

/// Where on the screen each render box [finder] finds is, of those laid out
/// on it.
Iterable<Rect> rectsOf(WidgetTester tester, Finder finder) => tester
    .renderObjectList<RenderBox>(finder)
    .map((box) => box.localToGlobal(Offset.zero) & box.size)
    .where((rect) => rect.top.isFinite);

/// What the screen showed under a [RepaintBoundary], as last painted, pixel
/// by pixel, so a test can tell what shows: a widget a flight hides, or one
/// faded out all the way, shows nothing, however it's laid out.
class ScreenPixels {
  ScreenPixels._(this.width, this.height, this._bytes);

  final int width;
  final int height;
  final ByteData _bytes;

  /// Captures what [key]'s [RepaintBoundary] last painted, at one pixel a
  /// logical pixel.
  static Future<ScreenPixels> capture(
    WidgetTester tester,
    GlobalKey key,
  ) async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    late ScreenPixels pixels;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      pixels = ScreenPixels._(image.width, image.height, bytes!);
      image.dispose();
    });
    return pixels;
  }

  /// The red, green and blue of the pixel at [x], [y], from 0 to 255.
  (int, int, int) at(int x, int y) {
    final i = (y * width + x) * 4;
    return (_bytes.getUint8(i), _bytes.getUint8(i + 1), _bytes.getUint8(i + 2));
  }

  /// The pixels whose color passes [test]: how many, and the rect around
  /// them, or null if none do.
  ({int count, Rect? bounds}) where(bool Function(int r, int g, int b) test) {
    var count = 0;
    var left = width, top = height, right = -1, bottom = -1;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final (r, g, b) = at(x, y);
        if (!test(r, g, b)) continue;
        count++;
        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
      }
    }
    return (
      count: count,
      bounds: count == 0
          ? null
          : Rect.fromLTRB(
              left.toDouble(),
              top.toDouble(),
              right + 1.0,
              bottom + 1.0,
            ),
    );
  }
}
