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

/// A tab switcher for Flutter: the tabs your app keeps open show as live
/// thumbnails in a grid, and a tap zooms one into a full page.
///
/// Flutter's `TabBar` shows a row of tab labels, and its `TabBarView` swipes
/// between their pages. A [TabOverview] shows multiple tabs at once, each as
/// a thumbnail of its page, for tabs that people add, close and reorder as
/// they go, such as documents, chats or forms:
///
/// - Zoom a thumbnail into its page and back, with a hero animation within
///   the same page, from hero_here, along a curve or, with
///   [TabTransition.spring], on a spring. With [TabOverview.pullToCollapse],
///   a pull down zooms a page back out too.
/// - Swipe between the pages of the open tabs.
/// - Drag and drop a thumbnail to reorder the tabs, from
///   animated_reorderable.
/// - Close a tab with its close button, a [RemoveTabButton] by default, or
///   by swiping its thumbnail away, and add tabs with
///   [TabOverviewController.add].
/// - Build thumbnails of your own with [TabOverview.tabThumbnailBuilder],
///   around a [FittedTab], which scales a tab's page down to its cell, or as
///   cards whose parts, such as a title, fly to their places on the page in
///   [TabHero]s.
///
/// Give a [TabOverviewController] your tabs, and build their pages in
/// [TabOverview.builder]:
///
/// ```dart
/// final controller = TabOverviewController<int>(initialTabs: [1, 2, 3]);
///
/// TabOverview<int>.builder(
///   controller: controller,
///   tabBuilder: (context, tab) => GestureDetector(
///     onTap: () => controller.isTabExpanded(tab)
///         ? controller.collapse()
///         : controller.expand(tab),
///     child: Center(child: Text('Tab $tab')),
///   ),
/// )
/// ```
library;

export 'src/tab_overview.dart'
    show
        ActiveTabChangedListener,
        ModeChangedListener,
        TabAddedListener,
        TabOverview,
        TabOverviewController,
        TabHero,
        TabOverviewMode,
        TabRemovedListener,
        TabTransition,
        TabsReorderedListener;
export 'src/util/model_widget_builder.dart' show ModelWidgetBuilder;
export 'src/widget/fitted_tab.dart' show FittedTab;
export 'src/widget/remove_tab_button.dart' show RemoveTabButton;
