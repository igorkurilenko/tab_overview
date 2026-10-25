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

// What a chat's card and its page both show, and what flies between them.

import 'package:flutter/material.dart';
import 'package:tab_overview/tab_overview.dart';

import 'chat.dart';

/// The parts of a chat that fly between its card and its page, as
/// [TabHero]s: its avatar, its name, and the text of its last message.
enum ChatPart { avatar, name, lastMessage }

/// A message's text, on its card and on its page: the body type, its lines
/// closer than body copy's, as a chat's are. One style on both, so a
/// message of one line is of one size on both, and only moves as it flies.
TextStyle? messageStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.3);

/// A chat's name, on its card, and [scale] times as big in its bar, so it
/// only grows as it flies.
class ChatName extends StatelessWidget {
  const ChatName(this.chat, {super.key, this.scale = 1});

  final Chat chat;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium!;
    return Text(
      chat.name,
      style: style.copyWith(
        fontSize: style.fontSize! * scale,
        letterSpacing: (style.letterSpacing ?? 0) * scale,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Someone's avatar: the initials of [name] on a disc of its own color.
class Avatar extends StatelessWidget {
  const Avatar(this.name, {super.key, required this.size});

  final String name;
  final double size;

  // Pale discs with darker initials, as in Signal.
  static const _colors = [
    (Color(0xFFE6E0FF), Color(0xFF5A3FD1)),
    (Color(0xFFDDF3E4), Color(0xFF1F7A45)),
    (Color(0xFFFFE4D6), Color(0xFFB4501C)),
    (Color(0xFFDCEBFF), Color(0xFF1E5FB3)),
    (Color(0xFFFFE0EC), Color(0xFFB0285F)),
    (Color(0xFFF1EAD8), Color(0xFF7A5B12)),
  ];

  @override
  Widget build(BuildContext context) {
    final (background, foreground) =
        _colors[name.codeUnits.fold(0, (sum, unit) => sum + unit) %
            _colors.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        _initialsOf(name),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontSize: size * .4,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

/// The first letters of [name]'s first two words.
String _initialsOf(String name) => name
    .split(' ')
    .where((word) => word.isNotEmpty)
    .take(2)
    .map((word) => word.substring(0, 1).toUpperCase())
    .join();
