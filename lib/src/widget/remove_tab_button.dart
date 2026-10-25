// Copyright 2024 Igor Kurilenko
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

/// The close button the overview shows on a tab by default, at its top right
/// corner, which removes the tab. Use it in a `removeTabButtonBuilder` to
/// keep its look and do something else when it's pressed, such as asking
/// first.
class RemoveTabButton extends StatelessWidget {
  /// Called when the button is pressed.
  final VoidCallback onPressed;

  /// Creates the close button, which calls [onPressed] when it's pressed.
  const RemoveTabButton({super.key, required this.onPressed});

  ButtonStyle get _buttonStyle => ButtonStyle(
    backgroundColor: WidgetStateProperty.all(
      Colors.black.withValues(alpha: 0.6),
    ),
  );

  Color get _buttonColor => Colors.white.withValues(alpha: 0.6);

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topRight,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: IconButton.filled(
        style: _buttonStyle,
        color: _buttonColor,
        onPressed: onPressed,
        icon: const Icon(Icons.close),
      ),
    ),
  );
}
