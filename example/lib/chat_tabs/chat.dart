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

// The chats example's data: its chats, and the messages that come in while
// it runs, made up and the same on every run.

import 'dart:math';

import 'package:flutter/foundation.dart';

/// A message: what it says, who sent it, and when.
class Message {
  const Message(this.text, {required this.author, required this.time});

  final String text;

  /// Who sent the message, or null if you did.
  final String? author;

  final DateTime time;

  bool get mine => author == null;
}

/// A chat, which is a tab: its messages, and what you've typed but not sent.
///
/// A chat's page is built anew each time it zooms in or out, so it keeps
/// what should carry over here, rather than in its State.
class Chat extends ChangeNotifier {
  Chat(this.name, List<Message> messages) : _messages = messages;

  final String name;
  final List<Message> _messages;

  /// What you've typed but not sent.
  String draft = '';

  List<Message> get messages => _messages;

  Message get last => _messages.last;

  /// Who else writes in the chat: the people in a group, or the one person
  /// in a chat with one.
  List<String> get members =>
      {for (final message in _messages) ?message.author}.toList();

  /// Adds a message [author] sent you.
  void receive(String text, DateTime time, {required String author}) {
    _messages.add(Message(text, author: author, time: time));
    notifyListeners();
  }

  /// Adds a message you sent, a minute after the last one, and clears the
  /// draft.
  void send(String text) {
    final time = last.time.add(const Duration(minutes: 1));
    _messages.add(Message(text, author: null, time: time));
    draft = '';
    notifyListeners();
  }
}

/// The time the example starts at, which its clock counts on from.
final startTime = DateTime(2026, 10, 23, 9, 41);

/// The chats the example opens with, the most recent first.
List<Chat> sampleChats() {
  Message from(String author, String text, int minutesAgo) => Message(
    text,
    author: author,
    time: startTime.subtract(Duration(minutes: minutesAgo)),
  );
  Message mine(String text, int minutesAgo) => Message(
    text,
    author: null,
    time: startTime.subtract(Duration(minutes: minutesAgo)),
  );

  return [
    Chat('Alex Morgan', [
      from('Alex Morgan', 'Are we still on for lunch?', 12),
      mine('Yes, 12:30 at the usual place', 10),
      from('Alex Morgan', 'Great, see you there', 2),
    ]),
    Chat('Mia Collins', [
      from('Mia Collins', 'New mockups are in the shared folder', 30),
      mine('Looking now', 28),
      from('Mia Collins', 'The settings screen needs another pass', 6),
    ]),
    Chat('Jordan Lee', [
      mine('Did you get the tickets?', 40),
      from('Jordan Lee', 'Two seats, row 12', 15),
    ]),
    Chat('Emma Davis', [
      from('Emma Davis', 'Dinner on Sunday?', 70),
      mine('Count me in', 65),
      from('Emma Davis', 'Bring dessert!', 25),
    ]),
    Chat('Riley Chen', [
      from('Riley Chen', 'Did you finish the book?', 90),
      mine('Two chapters left', 60),
    ]),
    Chat('Noah Patel', [
      from('Noah Patel', 'The cabin is booked', 150),
      mine('Who is driving?', 130),
      from('Noah Patel', 'I can take four people', 100),
    ]),
    Chat('Taylor Kim', [
      from('Taylor Kim', 'Thanks for the help yesterday', 160),
      mine('Any time', 150),
    ]),
    Chat('Sam Rivera', [
      mine('Running late, 10 minutes', 190),
      from('Sam Rivera', 'No problem', 185),
    ]),
    Chat('Chris Walker', [
      from('Chris Walker', 'Can you send me the notes?', 230),
      mine('Sent', 220),
    ]),
    Chat('Olivia Brooks', [
      from('Olivia Brooks', 'See you at the gym at 7?', 300),
    ]),
  ];
}

/// The messages that come in while the example runs, each from the person
/// of one of the open chats, picked at random, but the same ones in the
/// same order on every run.
class IncomingMessages {
  final _random = Random(7);
  var _time = startTime;

  static const _texts = [
    'Sounds good',
    'On my way',
    'Can you call me later?',
    'Just saw this',
    'Ha, nice',
    'What time works for you?',
    'Sent you the link',
    'Almost done',
    'Thanks!',
    'Let me check and get back to you',
  ];

  /// The chat the next message comes in, who it's from, what it says and
  /// when it comes, a minute after the one before; or null if there are no
  /// chats.
  (Chat, String, String, DateTime)? next(List<Chat> chats) {
    if (chats.isEmpty) return null;
    _time = _time.add(const Duration(minutes: 1));
    final chat = chats[_random.nextInt(chats.length)];
    final members = chat.members;
    final author = members.isEmpty
        ? chat.name
        : members[_random.nextInt(members.length)];
    return (chat, author, _texts[_random.nextInt(_texts.length)], _time);
  }
}
