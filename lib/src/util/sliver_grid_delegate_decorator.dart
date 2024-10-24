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

import 'package:flutter/rendering.dart';

typedef LayoutCallback = void Function(SliverGridLayout layout);

abstract class SliverGridDelegateDecorator implements SliverGridDelegate {
  final SliverGridDelegate gridDelegate;

  SliverGridDelegateDecorator({required this.gridDelegate});

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) =>
      gridDelegate.getLayout(constraints);

  @override
  bool shouldRelayout(covariant SliverGridDelegate oldDelegate) {
    if (oldDelegate is SliverGridLayoutNotifier) {
      return gridDelegate.shouldRelayout(oldDelegate.gridDelegate);
    }
    return gridDelegate.shouldRelayout(oldDelegate);
  }
}

class SliverGridLayoutNotifier extends SliverGridDelegateDecorator {
  SliverGridLayoutNotifier({
    required super.gridDelegate,
    this.onLayout,
  });

  final LayoutCallback? onLayout;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final layout = super.getLayout(constraints);
    onLayout?.call(layout);
    return layout;
  }
}
