# example

The tab_overview example: a Safari-style tab overview whose tabs expand, collapse, reorder and are removed.

## Signing

The example's Xcode projects carry no development team, so a checkout builds as it is, and macOS signs the app to run locally. To run it on an iPhone, put your team ID in a file that git ignores:
```
echo 'DEVELOPMENT_TEAM = <your team ID>' > ios/Flutter/Signing.xcconfig
```
`macos/Runner/Configs/Signing.xcconfig` does the same for macOS. Set the team there rather than in Xcode's Signing & Capabilities tab, which writes it into the project for everyone.
