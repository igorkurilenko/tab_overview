# example

The tab_overview example: a tab switcher whose tabs show as live thumbnails in a grid, zoom into their pages and back, and are reordered, closed and added. pub.dev shows it, with its recording and code, on the package's [Example tab](https://pub.dev/packages/tab_overview/example), from `example.md`.

The chats example, in `lib/chat_tabs/`, shows chats as cards that open into their pages. Run it with `flutter run -t lib/chat_tabs/main.dart`.

## Signing

The example's Xcode projects carry no development team, so a checkout builds as it is, and macOS signs the app to run locally. To run it on an iPhone, put your team ID in a file that git ignores:
```
echo 'DEVELOPMENT_TEAM = <your team ID>' > ios/Flutter/Signing.xcconfig
```
`macos/Runner/Configs/Signing.xcconfig` does the same for macOS. Set the team there rather than in Xcode's Signing & Capabilities tab, which writes it into the project for everyone.
