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

import 'package:flutter/widgets.dart';

// Tags and keys hold the tab's entry, which is equal only to itself. So a
// tab's heroes pair with each other only, whatever the tab's equality and
// hash code do, and a tab removed and added again pairs with neither of its
// old heroes.
mixin HeroTabHelper {
  Object tabHeroTag(Object entry) => (entry, 'tab');

  Key tabThumbHeroKey(Object entry) => ValueKey((entry, 'thumb'));

  Key expandedTabHeroKey(Object entry) => ValueKey((entry, 'expanded'));

  Object removeButtonHeroTag(Object entry) => (entry, 'remove button');

  Key tabThumbRemoveButtonHeroKey(Object entry) =>
      ValueKey((entry, 'remove button thumb'));

  Key expandedTabRemoveButtonHeroKey(Object entry) =>
      ValueKey((entry, 'remove button expanded'));
}
