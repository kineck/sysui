// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'story_manager.dart';

/// Adds a button to randomize story times.
class StoryTimeRandomizer extends StatelessWidget {
  final StoryManager storyManager;
  final Widget child;

  StoryTimeRandomizer({this.storyManager, this.child});

  @override
  Widget build(BuildContext context) => new Stack(
        children: [
          child,
          new Positioned(
            left: 0.0,
            top: 0.0,
            width: 50.0,
            height: 50.0,
            child: new GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: storyManager.randomizeStoryTimes,
            ),
          ),
        ],
      );
}
