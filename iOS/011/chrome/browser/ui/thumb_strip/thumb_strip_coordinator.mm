// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/thumb_strip/thumb_strip_coordinator.h"

#import "ios/chrome/browser/ui/gestures/view_revealing_vertical_pan_handler.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

namespace {
// Height of the view that is revealed. The thumb strip has a height equal to a
// small grid cell + edge insets (top and bottm) from thumb strip layout.
const CGFloat kThumbStripHeight = 168.0f + 22.0f + 22.0f;
}  // namespace

@implementation ThumbStripCoordinator

#pragma mark - ChromeCoordinator

- (void)start {
  self.panHandler = [[ViewRevealingVerticalPanHandler alloc]
      initWithHeight:kThumbStripHeight];
}

- (void)stop {
  self.panHandler = nil;
}

@end
