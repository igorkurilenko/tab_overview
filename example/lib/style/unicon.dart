// Copyright 2026 Igor Kurilenko
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'svg_path.dart';

/// A [Unicons](https://iconscout.com/unicons) line icon, painted from its SVG
/// path data, with no icon font and no SVG package, as in rose_app. The path
/// is parsed once per glyph and cached, then drawn, and tinted, by a
/// [CustomPainter].
class Unicon extends StatelessWidget {
  const Unicon(this.data, {super.key, this.size, this.color});

  /// The SVG path `d` data, in a 24 × 24 view box. See [UniconData].
  final String data;

  /// Defaults to the ambient [IconTheme]'s size, or 24.
  final double? size;

  /// Defaults to the ambient [IconTheme]'s color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final size = this.size ?? iconTheme.size ?? 24;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _UniconPainter(
          data,
          color ?? iconTheme.color ?? const Color(0xFF000000),
        ),
      ),
    );
  }
}

const double _viewBox = 24;

class _UniconPainter extends CustomPainter {
  _UniconPainter(this.data, this.color);

  final String data;
  final Color color;

  // Parsing is pure geometry, so it's cached across rebuilds and instances.
  static final _cache = <String, Path>{};

  @override
  void paint(Canvas canvas, Size size) {
    final path = _cache[data] ??= parseSvgPath(data);
    final scale = math.min(size.width, size.height) / _viewBox;
    canvas
      ..save()
      ..translate(
        (size.width - _viewBox * scale) / 2,
        (size.height - _viewBox * scale) / 2,
      )
      ..scale(scale)
      ..drawPath(
        path,
        Paint()
          ..isAntiAlias = true
          ..color = color,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_UniconPainter old) =>
      old.data != data || old.color != color;
}

/// The path data of the Unicons line icons the examples use, from Unicons
/// 4.0.0, which is under the Apache License 2.0. Names say what each is for in
/// the examples, rather than its Unicons file name.
abstract final class UniconData {
  /// Switches between the grid of thumbnails and the pages. Unicons' `apps`.
  static const overview =
      r'M10,13H3a1,1,0,0,0-1,1v7a1,1,0,0,0,1,1h7a1,1,0,0,0,1-1V14A1,1,0,0,0,10,13ZM9,20H4V15H9ZM21,2H14a1,1,0,0,0-1,1v7a1,1,0,0,0,1,1h7a1,1,0,0,0,1-1V3A1,1,0,0,0,21,2ZM20,9H15V4h5Zm1,4H14a1,1,0,0,0-1,1v7a1,1,0,0,0,1,1h7a1,1,0,0,0,1-1V14A1,1,0,0,0,21,13Zm-1,7H15V15h5ZM10,2H3A1,1,0,0,0,2,3v7a1,1,0,0,0,1,1h7a1,1,0,0,0,1-1V3A1,1,0,0,0,10,2ZM9,9H4V4H9Z';

  /// Closes the tab it's on. Unicons' `multiply`.
  static const close =
      r'M13.41,12l6.3-6.29a1,1,0,1,0-1.42-1.42L12,10.59,5.71,4.29A1,1,0,0,0,4.29,5.71L10.59,12l-6.3,6.29a1,1,0,0,0,0,1.42,1,1,0,0,0,1.42,0L12,13.41l6.29,6.3a1,1,0,0,0,1.42,0,1,1,0,0,0,0-1.42Z';

  /// Closes the active tab. Unicons' `minus`.
  static const remove = r'M19,11H5a1,1,0,0,0,0,2H19a1,1,0,0,0,0-2Z';

  /// Adds a tab. Unicons' `plus`.
  static const add =
      r'M19,11H13V5a1,1,0,0,0-2,0v6H5a1,1,0,0,0,0,2h6v6a1,1,0,0,0,2,0V13h6a1,1,0,0,0,0-2Z';
}
