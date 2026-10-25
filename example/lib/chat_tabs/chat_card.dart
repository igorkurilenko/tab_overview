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

// A chat's card in the overview, which opens into the chat's page.

import 'package:flutter/material.dart';
import 'package:tab_overview/tab_overview.dart';

import '../style/style.dart';
import 'chat.dart';
import 'chat_parts.dart';

/// The space around a card's content.
const chatCardPadding = S.s3;

/// A card's shape, an Apple Watch Ultra's screen's: 205 by 251 points.
const chatCardAspectRatio = 205 / 251;

/// The widest a card gets: the grid lays out as many columns as it can of
/// cards no wider, so a screen no wider than one card, a watch's, has one.
const chatCardMaxWidth = 220.0;

/// The radius of a card's corners, about as round as a watch's screen's for
/// a card of about its size.
const chatCardRadius = 44.0;

/// The size of a chat's avatar on its card.
const _cardAvatarSize = S.s10;

/// A chat's card in the overview, laid out as a watch shows a message: the
/// chat's avatar in the middle, its name under it, and the text of its last
/// message under that. All three fly to the chat's page as it opens, and
/// back as it closes.
///
/// The message keeps room for two lines, so the avatar and the name stay
/// where they are whether it takes one or two, and a new one slides up into
/// place as it comes.
class ChatCard extends StatelessWidget {
  const ChatCard(this.chat, {super.key, required this.onTap});

  final Chat chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = messageStyle(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(chatCardPadding),
        child: ListenableBuilder(
          listenable: chat,
          builder: (context, _) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TabHero(
                tag: ChatPart.avatar,
                child: Avatar(chat.name, size: _cardAvatarSize),
              ),
              const SizedBox(height: S.s2),
              TabHero(tag: ChatPart.name, child: ChatName(chat)),
              // Further from the name than the name is from the avatar, so
              // the message reads apart from whom the chat is with.
              const SizedBox(height: S.s3),
              _TwoLines(
                style: style,
                child: TabHero(
                  tag: ChatPart.lastMessage,
                  child: _LastMessage(chat.last, style: style),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Room for two lines of [style]'s text, whatever [child] takes of it, with
/// [child] at its top, clipped to it.
class _TwoLines extends StatelessWidget {
  const _TwoLines({required this.style, required this.child});

  final TextStyle? style;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: Stack(
      alignment: Alignment.topCenter,
      children: [
        // Two empty lines, unseen, whose height the room takes.
        ExcludeSemantics(
          child: Opacity(opacity: 0, child: Text('\n', style: style)),
        ),
        child,
      ],
    ),
  );
}

/// The text of a chat's last message, in two lines at most. A new one slides
/// up into place, fading in, as the one before it slides up and away.
class _LastMessage extends StatelessWidget {
  const _LastMessage(this.message, {required this.style});

  final Message message;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 300),
    switchInCurve: Curves.easeOut,
    switchOutCurve: Curves.easeIn,
    layoutBuilder: (current, previous) => Stack(
      alignment: Alignment.topCenter,
      children: [...previous, ?current],
    ),
    // Built anew for every message, so the one going out goes up too.
    transitionBuilder: (child, animation) {
      final coming = child.key == ValueKey(message);
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: Offset(0, coming ? .5 : -.5),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      );
    },
    child: Text(
      message.text,
      key: ValueKey(message),
      style: style,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
  );
}
