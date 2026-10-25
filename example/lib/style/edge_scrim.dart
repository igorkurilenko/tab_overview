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

import 'package:flutter/material.dart';

import 'tokens.dart';

enum _Edge { top, bottom }

/// The backdrop of controls floating over scrolling content at an edge, as
/// rose_app's: a shade of the surface's [color] reaching from the edge to a
/// little past [child], as in Signal. The content fades into it and stays
/// faintly visible behind the controls. Its eased ramp leaves no line where
/// it starts.
class EdgeScrim extends StatelessWidget {
  /// At the top, the shade reaching down past [child].
  const EdgeScrim.top({
    super.key,
    required this.color,
    this.beyond = S.s10,
    required this.child,
  }) : _edge = _Edge.top;

  /// At the bottom, the shade reaching up past [child].
  const EdgeScrim.bottom({
    super.key,
    required this.color,
    this.beyond = S.s10,
    required this.child,
  }) : _edge = _Edge.bottom;

  final _Edge _edge;

  /// The surface's own color, which the content fades into.
  final Color color;

  /// How far the shade reaches past [child], away from the edge.
  final double beyond;

  final Widget child;

  /// How far from its far side the shade reaches [_cover].
  double get _rampHeight => beyond + S.s9;

  /// How much the shade covers the content past the ramp, and at the edge.
  static const _cover = 0.85;
  static const _coverAtEdge = 1.0;

  /// Steps of each eased half: a linear ramp shows where it starts.
  static const _rampSteps = 8;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: IgnorePointer(
          child: LayoutBuilder(
            builder: (context, box) {
              final height = box.maxHeight;
              final ramp = height > 0
                  ? (_rampHeight / height).clamp(0.0, 1.0)
                  : 0.0;
              // Eased from none to [_cover] over the ramp, then on to the
              // edge's; both halves start and end flat.
              final stops = <(double, double)>[
                for (var i = 0; i <= _rampSteps; i++)
                  (
                    ramp * i / _rampSteps,
                    _cover * Curves.easeInOut.transform(i / _rampSteps),
                  ),
                for (var i = 1; i <= _rampSteps; i++)
                  (
                    ramp + (1 - ramp) * i / _rampSteps,
                    _cover +
                        (_coverAtEdge - _cover) *
                            Curves.easeInOut.transform(i / _rampSteps),
                  ),
              ];
              final top = _edge == _Edge.top;
              return DecoratedBox(
                decoration: BoxDecoration(
                  // From the far side to the edge.
                  gradient: LinearGradient(
                    begin: top ? Alignment.bottomCenter : Alignment.topCenter,
                    end: top ? Alignment.topCenter : Alignment.bottomCenter,
                    colors: [
                      for (final (_, cover) in stops)
                        color.withValues(alpha: cover),
                    ],
                    stops: [for (final (stop, _) in stops) stop],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      Padding(
        padding: _edge == _Edge.top
            ? EdgeInsets.only(bottom: beyond)
            : EdgeInsets.only(top: beyond),
        child: child,
      ),
    ],
  );
}
