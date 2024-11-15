# Changelog

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
