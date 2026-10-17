# Changelog

## [0.1.12]
### Fixed
- While tabs are reordered, a tab moved again just as its slide ends slides there, rather than jumping a slot without animating. Fixed in animated_reorderable 1.6.1.

### Changed
- Require animated_reorderable 1.6.1.

## [0.1.11]
### Added
- `pullToCollapse`, off by default: pull the expanded tab down to collapse it, as in hero_here's show details example. The tab is pulled from the top of its vertical scroll view, or from anywhere on a tab without one. As it's pulled, it shrinks and its corners round toward the thumbnail's. Let go once it's pulled 50 pixels, or while it moves down fast, and it collapses from where it is, at the speed it had. Otherwise it goes back. The example turns it on, and lets the mouse drag, as hero_here's examples do.

## [0.1.10]
### Fixed
- Removing a tab in the same event as expanding it from off screen no longer leaves the overview ignoring taps. The overview expanded the tab that took the removed one's place instead of staying put, and its grid ignored taps from then on, after a collapse too.
- Removing a tab right after expanding it, before the overview builds its page, leaves the overview where it was. It scrolled to its top, and the removed tab stayed built, hidden, for as long as the overview lived.
- Removing the active tab of a controller created expanded, before the overview is first built, no longer leaves the overview ignoring taps.

All three go back to 0.0.5 at least.

## [0.1.9]
### Fixed
- Removing a tab other than the last and adding one in the same event, such as closing a tab and opening another in one handler, no longer throws `RangeError`s. Fixed in animated_reorderable 1.6.0.

### Changed
- Require animated_reorderable 1.6.0.

## [0.1.8]
### Fixed
- Removing the expanded tab collapses to the tab that takes its place. Since 0.0.6, the overview scrolled to its top instead, leaving that tab off screen.
- Removing a tab while it expands from off screen leaves the overview where it was. It scrolled to the top.

## [0.1.7]
### Changed
- Rebuild only the thumbnail of the tab that expands or collapses, not every thumbnail. Expanding a tab rebuilt every other thumbnail once, and collapsing it rebuilt every thumbnail twice.

## [0.1.6]
### Fixed
- A tab whose hash code changes while it flies, such as one whose equality follows a title that changes as its page loads, no longer leaves the overview ignoring taps.
- `scrollToTab` scrolls all the way to a tab just added on a new row. It stopped a row short.

## [0.1.5]
### Fixed
- Show a tab that's added again while its removal still animates, as when a closed tab is brought back right away. It was in `tabs`, but its thumbnail never showed.
- Listen to a tab's add or remove animation once, rather than once more on every rebuild while it animated.
- In the example, the minus button closes the active tab. It removed the second tab, and threw once only one was left. New tabs are numbered from a counter, so numbers don't repeat after a removal.

## [0.1.4]
### Fixed
- Expanding a tab while it collapses, or collapsing it while it expands, no longer leaves the overview ignoring taps, or the expanded tab with the thumbnail's decoration. 0.1.0 had this when the turn came early in the flight; with hero_here 1.5.0 it came at any point. The same goes for expanding and collapsing in one go.

### Changed
- A tab turned around mid-flight now swings toward where it's sent, from where it is and at the speed it had, rather than going back along its path. Its decoration turns from what it shows, and the flight keeps its duration and curve.
- Require hero_here 1.5.1, whose diverted flights slide along the overview's edge rather than out of it.

## [0.1.3]
### Added
- Export `FittedTab`, so a custom `tabThumbnailBuilder` can show a tab as the default thumbnail does: laid out at the overview's size and scaled to fit.

## [0.1.2]
### Fixed
- Keep an added tab's state, such as its text, focus and scroll position, when its add animation ends. The first rebuild after the animation re-created the content of its thumbnail, or of its page if it was expanded right away.

### Changed
- Stop repainting a flying tab's content on each frame of the flight. During an expand or a collapse, it painted on 20 of the flight's 21 frames; now it paints twice, once as the flight starts and once where it lands.
- Rebuild only the thumbnails that a swipe between expanded tabs changes, not all of them.

## [0.1.1]
### Changed
- Require hero_here 1.5.0. Expanding or collapsing a tab no longer shows a screenshot of the overview for a frame, and the tab starts to fly a frame sooner.

## [0.1.0]
### Fixed
- Follow a new `controller` given to the overview. The overview showed the new tabs, but `expand` and `toggleMode` failed with a null check, and the old controller still drove it.
- Collapse a tab whose hash code is the same as another tab's. It failed with a null check, and the other tab's thumbnail stayed hidden.
- Move thumbnails along `thumbnailsMotionAnimationCurve`. It was ignored.
- Keep one `PageController` while a tab is expanded, rather than a new one on each build, and dispose it, and the grid's `ScrollController`, when they're no longer needed. Neither was disposed.

### Changed
- **Breaking:** `TabOverview.builder` requires a `controller`. Without one, the overview created its own on each rebuild, which nothing could add tabs to, so it was always empty.

## [0.0.6]
### Fixed
- Keep an expanded tab's state, such as its text, focus and scroll position, the first time something rebuilds it after it expands, such as the keyboard opening or a `setState` above the overview. It was re-created.
- Collapse to the tab's thumbnail after a window resize while expanded. The tab flew off the screen, and the overview showed other tabs.
- Size tabs by the overview, not the screen. Under an app bar, an expanded tab was cropped; beside a sidebar, it was letterboxed; and off-screen tabs flew in from outside the overview.

### Changed
- Require hero_here 1.4.1.
- Lay tab content out at the overview's size. Under a `Scaffold`, it now shrinks when the keyboard opens, like any other body, so content with a fixed height can overflow.
- Show the tabs on every frame while the window resizes, while the keyboard opens and when the overview's parent rebuilds. Only a change between overview and expanded runs a hero switch, which shows a snapshot for a frame.

## [0.0.5]
### Fixed
- Show the overview on screens narrower than 300 pixels; it showed a placeholder.

### Changed
- Require Dart 3.13 and Flutter 3.47.
- Require animated_reorderable 1.5.0 and hero_here 1.1.0, so thumbnails keep their state while they move and tab transitions stay in place when the overview isn't at the screen's top-left corner.
- Update the example to the current Flutter templates.

## [0.0.4]
### Fixed
- Fix tab activation.

## [0.0.3]
### Fixed
- Flight animation creation for expanded initial mode.

## [0.0.2]
### Fixed
- Resolved a bug where the `TabOverview` widget would cause an error when in expanded mode with no tabs present.

## [0.0.1]
### Added
- Initial release of `tab_overview`, a customizable widget for managing tabs with smooth transitions and a thumbnail grid view.
- **TabOverview widget**: Displays tabs in both overview (grid of thumbnails) and expanded modes.
- **Responsive grid layout**: Automatically adjusts the number of columns based on screen size (large, medium, small, and extra small).
- **TabOverviewController**: Manages tab state, allowing users to add, remove, reorder, and toggle between tabs.
- **Customizable animations**: Adjustable animation duration and curve for smooth transitions.
- **Reorderable and removable tabs**: Supports tab reordering and optional removal through the `ReorderableTab` and `RemovableTab` interfaces.
- **Optional Decorations**: Customizable styling for thumbnails and expanded tab views.
- **Dependencies**:
  - `animated_reorderable` for drag-and-drop functionality in the grid view.
  - `hero_here` for smooth transitions between thumbnail and expanded views.
