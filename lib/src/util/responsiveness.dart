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

mixin Responsiveness {
  static const double large = 900;
  static const double medium = 600;
  static const double small = 300;

  BoxConstraints? constraints;

  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      this.constraints = constraints;
      double width = constraints.maxWidth;
      if (width > large) return buildLarge(context);
      if (width > medium) return buildMedium(context);
      if (width > small) return buildSmall(context);
      return buildExtraSmall(context);
    });
  }

  Widget buildLarge(BuildContext context);

  Widget buildMedium(BuildContext context);

  Widget buildSmall(BuildContext context);

  Widget buildExtraSmall(BuildContext context);
}
