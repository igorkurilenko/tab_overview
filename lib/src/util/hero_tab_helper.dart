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

// Tags and keys hold the tab itself, so they're equal exactly when the tabs
// are, as the controller's tabs are, and never because hash codes collide.
mixin HeroTabHelper<T> {
  Object tabHeroTag(T tab) => (tab, 'tab');

  Key tabThumbHeroKey(T tab) => ValueKey((tab, 'thumb'));

  Key expandedTabHeroKey(T tab) => ValueKey((tab, 'expanded'));

  Object removeButtonHeroTag(T tab) => (tab, 'remove button');

  Key tabThumbRemoveButtonHeroKey(T tab) =>
      ValueKey((tab, 'remove button thumb'));

  Key expandedTabRemoveButtonHeroKey(T tab) =>
      ValueKey((tab, 'remove button expanded'));
}
