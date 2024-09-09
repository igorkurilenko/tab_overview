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
import 'package:flutter/widgets.dart';

class SizeChangeListener extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onSizeChanged;
  const SizeChangeListener({
    super.key,
    super.child,
    required this.onSizeChanged,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSizeChangeListener(onSizeChanged: onSizeChanged);
  }
}

class _RenderSizeChangeListener extends RenderProxyBox {
  final ValueChanged<Size> onSizeChanged;

  _RenderSizeChangeListener({
    RenderBox? child,
    required this.onSizeChanged,
  }) : super(child);

  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();

    if (size != _oldSize) {
      onSizeChanged(size);
    }

    _oldSize = size;
  }
}
