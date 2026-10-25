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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tab_overview/tab_overview.dart';

import '../style/style.dart';
import 'chat.dart';
import 'chat_card.dart';
import 'chat_page.dart';
import 'chats_scroll.dart';

void main() => runApp(
  MaterialApp(
    title: 'TabOverview Chats Example',
    debugShowCheckedModeBanner: false,
    theme: exampleTheme,
    home: const ChatTabsExample(),
  ),
);

/// Chats as tabs: a grid of chats' cards, each of which opens into its chat,
/// its avatar, name and last message flying to their places on the page, and
/// the chat closes back into it:
///
/// 1. A [TabOverviewController] holds the chats, and opens and closes them
///    on a spring.
/// 2. [TabOverview.builder] builds each chat's page, and its card, out of
///    which the page opens. A [TabHero] on each flies the chat's avatar,
///    another its name, and another its last message, between them.
/// 3. Messages come in, and the cards and pages show them as they come.
class ChatTabsExample extends StatefulWidget {
  const ChatTabsExample({super.key});

  @override
  State<ChatTabsExample> createState() => ChatTabsExampleState();
}

class ChatTabsExampleState extends State<ChatTabsExample> {
  // 1. The controller, with the chats as its tabs. A chat opens and closes
  //    on a spring, with a little bounce, which carries the page a little
  //    past its card's size and back as it closes.
  final controller = TabOverviewController<Chat>(
    initialTabs: sampleChats(),
    transition: TabTransition.spring(
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 350),
        bounce: .15,
      ),
    ),
  );

  // 3. The messages that come in, one every few seconds.
  final _incoming = IncomingMessages();
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _receive());
  }

  @override
  void dispose() {
    _timer.cancel();
    controller.dispose();
    super.dispose();
  }

  void _receive() {
    final next = _incoming.next(controller.tabs);
    if (next == null) return;
    final (chat, author, text, time) = next;
    chat.receive(text, time, author: author);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);
    final surface = Theme.of(context).colorScheme.surfaceContainerLowest;
    // 2. On a watch, a card fills the screen, with no space around it.
    final screen = MediaQuery.sizeOf(context);
    final watch = screen.width <= chatCardMaxWidth;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      // 2. The tab switcher: the chats' cards, or the chats' pages.
      body: TabOverview<Chat>.builder(
        controller: controller,
        // 2. A chat's page, which opens out of its card.
        tabBuilder: (context, chat) => ChatPage(chat),
        // 2. A chat's card. A tap opens the chat.
        tabThumbnailBuilder: (context, chat) =>
            ChatCard(chat, onTap: () => controller.expand(chat)),
        // 2. Cards of an Apple Watch Ultra's screen's shape: two columns of
        //    them on a phone, and more on a wider screen. On a watch, a card
        //    is the screen, a gap between each and the next.
        thumbnailsGridDelegate: watch
            ? SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                mainAxisExtent: screen.height,
                mainAxisSpacing: S.s2,
              )
            : const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: chatCardMaxWidth,
                childAspectRatio: chatCardAspectRatio,
                mainAxisSpacing: S.s2,
                crossAxisSpacing: S.s2,
              ),
        thumbnailsGridPadding: watch
            ? EdgeInsets.zero
            : EdgeInsets.fromLTRB(
                S.s3,
                padding.top + S.s3,
                S.s3,
                padding.bottom + S.s3,
              ),
        // 2. White cards with a watch's round corners, which square off as
        //    a chat opens.
        thumbnailDecoration: ShapeDecoration(
          color: surface,
          shape: squircle(chatCardRadius),
        ),
        expandedTabDecoration: ShapeDecoration(
          color: surface,
          shape: squircle(0),
        ),
        // 2. A swipe closes a chat, so its card shows no close button.
        removeTabButtonBuilder: (context, chat) => const SizedBox.shrink(),
        // 2. A pull down on a chat's bar closes it into its card, while its
        //    messages only scroll.
        pullToCollapse: true,
        // Drag with the mouse too, to pull a chat down. On a watch, a scroll
        // of the cards snaps to a card, as a swipe between chats does.
        scrollBehavior: ChatsScrollBehavior(
          cardExtent: watch ? screen.height + S.s2 : null,
        ),
      ),
    );
  }
}
