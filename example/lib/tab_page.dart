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

// What the main example looks like: a tab's page, its close button and the
// buttons under the tabs, apart from the tab switcher, which main.dart builds.

import 'package:flutter/material.dart';

import 'style/style.dart';

/// A tab's page: its number, large, on white. The grid shows it, scaled
/// down, as the tab's thumbnail.
class TabPage extends StatelessWidget {
  const TabPage(this.number, {super.key, this.onTap});

  final int number;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: ColoredBox(
        color: theme.colorScheme.surfaceContainerLowest,
        child: Center(
          child: Text(
            '$number',
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: _numberSize,
              letterSpacing: headingLetterSpacing(_numberSize),
            ),
          ),
        ),
      ),
    );
  }

  static const double _numberSize = 96;
}

/// The button that closes a tab, at its top right corner: a white cross on
/// a dark disc.
class CloseTabButton extends StatelessWidget {
  const CloseTabButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topRight,
    child: Padding(
      padding: const EdgeInsets.all(S.s3),
      child: IconButton.filled(
        tooltip: 'Close tab',
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: .45),
          foregroundColor: Colors.white,
        ),
        icon: const Unicon(UniconData.close, size: S.s4),
      ),
    ),
  );
}

/// The buttons under the tabs, white icons on discs: a dark gray one switches
/// between the grid and the pages, and two in the accent close the active
/// tab and add one.
class TabButtons extends StatelessWidget {
  const TabButtons({
    super.key,
    required this.onSwitchView,
    required this.onClose,
    required this.onAdd,
  });

  final VoidCallback onSwitchView;
  final VoidCallback onClose;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton.filled(
          tooltip: 'Switch view',
          onPressed: onSwitchView,
          style: IconButton.styleFrom(
            backgroundColor: colors.inverseSurface,
            foregroundColor: colors.onInverseSurface,
          ),
          icon: const Unicon(UniconData.overview),
        ),
        IconButton.filled(
          tooltip: 'Close the active tab',
          onPressed: onClose,
          style: IconButton.styleFrom(foregroundColor: colors.onPrimary),
          icon: const Unicon(UniconData.remove),
        ),
        IconButton.filled(
          tooltip: 'New tab',
          onPressed: onAdd,
          style: IconButton.styleFrom(foregroundColor: colors.onPrimary),
          icon: const Unicon(UniconData.add),
        ),
      ],
    );
  }
}
