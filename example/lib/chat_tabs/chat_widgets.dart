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

// What the chats example looks like: a chat's card in the overview, its
// page and their parts, apart from the tab switcher, which main.dart builds.

import 'package:flutter/material.dart';
import 'package:tab_overview/tab_overview.dart';

import '../style/style.dart';
import 'chat.dart';

/// The parts of a chat that fly between its card and its page, as
/// [TabHero]s: its avatar, its name, and the text of its last message.
enum ChatPart { avatar, name, lastMessage }

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

/// The space at the sides of a chat's page.
const chatPagePadding = S.s4;

/// The size of a chat's avatar on its card, and in its bar.
const _cardAvatarSize = S.s10;
const _barAvatarSize = S.s8;

/// How much bigger a chat's name is in its bar than on its card.
const _barNameScale = 1.5;

/// How far the shade behind the bar and the composer reaches past them.
const _scrimBeyond = S.s5;

/// The heights of a chat's bar, below the status bar, and of its composer,
/// above the home indicator.
const _barHeight = S.s2 + _barAvatarSize + S.s2;
const _composerHeight = S.s2 + S.s9 + S.s4;

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
    final style = Theme.of(context).textTheme.bodyMedium;
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
              TabHero(tag: ChatPart.name, child: _ChatName(chat)),
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

/// A chat's name, on its card, and [scale] times as big in its bar, so it
/// only grows as it flies.
class _ChatName extends StatelessWidget {
  const _ChatName(this.chat, {this.scale = 1});

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

/// A chat's page: its messages, the newest at the bottom, under a bar with
/// whom the chat is with and a box to type a message in, both floating over
/// the messages on a shade of the page.
///
/// It has no way back: a pull down on its bar closes the chat into its card.
class ChatPage extends StatefulWidget {
  const ChatPage(this.chat, {super.key});

  final Chat chat;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // The page is built anew each time it zooms in or out, so it starts from
  // what the chat keeps: the draft.
  late final _draft = TextEditingController(text: widget.chat.draft);

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _send() {
    final text = _draft.text.trim();
    if (text.isEmpty) return;
    widget.chat.send(text);
    _draft.clear();
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerLowest;
    final padding = MediaQuery.paddingOf(context);
    return Stack(
      children: [
        Positioned.fill(
          child: ListenableBuilder(
            listenable: widget.chat,
            builder: (context, _) {
              final messages = widget.chat.messages;
              return ListView.separated(
                reverse: true,
                padding: EdgeInsets.fromLTRB(
                  chatPagePadding,
                  padding.top + _barHeight + _scrimBeyond,
                  chatPagePadding,
                  padding.bottom + _composerHeight + _scrimBeyond,
                ),
                itemCount: messages.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: S.s5),
                itemBuilder: (context, index) => MessageRow(
                  messages[messages.length - 1 - index],
                  last: index == 0,
                ),
              );
            },
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          child: EdgeScrim.top(
            color: surface,
            beyond: _scrimBeyond,
            child: _ChatBar(widget.chat, top: padding.top),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: EdgeScrim.bottom(
            color: surface,
            beyond: _scrimBeyond,
            child: _Composer(
              controller: _draft,
              onChanged: (text) => widget.chat.draft = text,
              onSend: _send,
              bottom: padding.bottom,
            ),
          ),
        ),
      ],
    );
  }
}

/// The top of a chat's page: whom the chat is with, as in Signal, but with
/// no buttons.
class _ChatBar extends StatelessWidget {
  const _ChatBar(this.chat, {required this.top});

  final Chat chat;
  final double top;

  // The bar takes the pointer, not the messages under it: a drag on it pulls
  // the chat down to close it, rather than scrolling the messages.
  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        chatPagePadding,
        top + S.s2,
        chatPagePadding,
        S.s2,
      ),
      child: Row(
        children: [
          TabHero(
            tag: ChatPart.avatar,
            child: Avatar(chat.name, size: _barAvatarSize),
          ),
          const SizedBox(width: S.s3),
          Flexible(
            child: TabHero(
              tag: ChatPart.name,
              child: _ChatName(chat, scale: _barNameScale),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The box to type a message in, and the button that sends it.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onChanged,
    required this.onSend,
    required this.bottom,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(S.s5, S.s2, S.s5, bottom + S.s4),
      child: SizedBox(
        height: S.s9,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Message',
                  filled: true,
                  fillColor: colors.surfaceContainer,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: S.s4,
                    vertical: S.s3,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(S.s9 / 2),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: S.s2),
            IconButton.filled(
              tooltip: 'Send',
              onPressed: onSend,
              style: IconButton.styleFrom(
                foregroundColor: colors.onPrimary,
                minimumSize: const Size.square(S.s9),
              ),
              // Unicons' send arrow points right; here it points up.
              icon: const RotatedBox(
                quarterTurns: 3,
                child: Unicon(UniconData.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A message, with no bubble: who sent it, by avatar and name, when, and
/// what it says.
class MessageRow extends StatelessWidget {
  const MessageRow(this.message, {super.key, this.last = false});

  final Message message;

  /// Whether it's the chat's last message, whose text flies to and from the
  /// chat's card.
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final author = message.author ?? 'You';
    final body = Text(message.text, style: text.bodyMedium);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Avatar(author, size: S.s7),
        const SizedBox(width: S.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      author,
                      style: text.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: S.s2),
                  Text(
                    _timeOf(message.time),
                    style: text.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              last ? TabHero(tag: ChatPart.lastMessage, child: body) : body,
            ],
          ),
        ),
      ],
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

String _timeOf(DateTime time) =>
    '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
