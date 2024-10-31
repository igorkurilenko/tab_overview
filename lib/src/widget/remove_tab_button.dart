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
import 'package:tab_overview/tab_overview.dart';

class RemoveTabButton<T> extends StatelessWidget {
  final TabOverviewController<T> controller;
  final T tab;

  const RemoveTabButton({
    super.key,
    required this.controller,
    required this.tab,
  });

  ButtonStyle get buttonStyle => ButtonStyle(
        backgroundColor: WidgetStateProperty.all(
          Colors.black.withOpacity(0.6),
        ),
      );

  Color get buttonColor => Colors.white.withOpacity(0.6);

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: IconButton.filled(
            style: buttonStyle,
            color: buttonColor,
            onPressed: _handlePress,
            icon: const Icon(Icons.close),
          ),
        ),
      );

  void _handlePress() => controller.remove(tab);
}
