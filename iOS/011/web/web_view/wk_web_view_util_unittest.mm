// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/web/web_view/wk_web_view_util.h"

#include "base/bind.h"
#import "base/test/ios/wait_util.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/platform_test.h"
#import "third_party/ocmock/OCMock/OCMock.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

@interface WKPreferences (Private)

@property(nonatomic,
          getter=_isSafeBrowsingEnabled,
          setter=_setSafeBrowsingEnabled:) BOOL _safeBrowsingEnabled;

@end

@interface WKWebView (Private)

- (void)_showSafeBrowsingWarningWithURL:(NSURL*)url
                                  title:(NSString*)title
                                warning:(NSString*)warning
                                details:(NSAttributedString*)details
                      completionHandler:(void (^)(BOOL))completionHandler;
@end

class WKWebViewUtilTest : public PlatformTest {};

namespace web {

// Tests that IsSafeBrowsingWarningDisplayedInWebView returns true when safe
// browsing warning is displayed in WKWebView.
TEST_F(WKWebViewUtilTest, TestIsSafeBrowsingWarningDisplayedInWebView) {
  if (@available(iOS 12.2, *)) {
    UIViewController* controller = [[UIViewController alloc] init];
    UIApplication.sharedApplication.keyWindow.rootViewController = controller;
    WKWebViewConfiguration* config = [[WKWebViewConfiguration alloc] init];
    WKWebView* web_view = [[WKWebView alloc] initWithFrame:CGRectZero
                                             configuration:config];
    [controller.view addSubview:web_view];

    // Use private API of WKPreferences to enable safe browsing warning.
    [config.preferences _setSafeBrowsingEnabled:YES];

    // Use private API of WKWebView to show safe browsing warning.
    [web_view _showSafeBrowsingWarningWithURL:nil
                                        title:nil
                                      warning:nil
                                      details:nil
                            completionHandler:^(BOOL){
                            }];

    EXPECT_TRUE(web::IsSafeBrowsingWarningDisplayedInWebView(web_view));
  }
}

#if defined(__IPHONE_14_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_14_0
// Tests that CreateFullPagePDF calls createPDFWithConfiguration and it invokes
// the callback with NSData.
TEST_F(WKWebViewUtilTest, IOS14EnsureCallbackIsCalledWithData) {
  // Expected: callback is called with valid NSData.
  if (@available(iOS 14, *)) {
    // Mock the web_view and make sure createPDFWithConfiguration's
    // completionHandler is invoked with NSData and no errors.
    id web_view_mock = OCMClassMock([WKWebView class]);
    OCMStub([web_view_mock createPDFWithConfiguration:[OCMArg any]
                                    completionHandler:[OCMArg any]])
        .andDo(^(NSInvocation* invocation) {
          void (^completion_block)(NSData* pdf_document_data, NSError* error);
          [invocation getArgument:&completion_block atIndex:3];
          completion_block([[NSData alloc] init], nil);
        });

    __block bool callback_called = false;
    __block NSData* callback_data = nil;

    CreateFullPagePdf(web_view_mock, base::Bind(^(NSData* data) {
                        callback_called = true;
                        callback_data = [data copy];
                      }));

    ASSERT_TRUE(base::test::ios::WaitUntilConditionOrTimeout(
        base::test::ios::kWaitForPageLoadTimeout, ^bool {
          return callback_called;
        }));
    EXPECT_TRUE(callback_data);
  }
}
#endif

#if defined(__IPHONE_14_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_14_0
// Tests that CreateFullPagePDF calls createPDFWithConfiguration and it
// generates an NSError.
TEST_F(WKWebViewUtilTest, IOS14EnsureCallbackIsCalledWithNil) {
  // Expected: callback is called with nil.
  if (@available(iOS 14, *)) {
    // Mock the web_view and make sure createPDFWithConfiguration's
    // completionHandler is invoked with NSData and an error.
    id web_view_mock = OCMClassMock([WKWebView class]);
    NSError* error =
        [NSError errorWithDomain:NSURLErrorDomain
                            code:NSURLErrorServerCertificateHasUnknownRoot
                        userInfo:nil];
    OCMStub([web_view_mock createPDFWithConfiguration:[OCMArg any]
                                    completionHandler:[OCMArg any]])
        .andDo(^(NSInvocation* invocation) {
          void (^completion_block)(NSData* pdf_document_data, NSError* error);
          [invocation getArgument:&completion_block atIndex:3];
          completion_block(nil, error);
        });

    __block bool callback_called = false;
    __block NSData* callback_data = nil;

    CreateFullPagePdf(web_view_mock, base::Bind(^(NSData* data) {
                        callback_called = true;
                        callback_data = [data copy];
                      }));

    ASSERT_TRUE(base::test::ios::WaitUntilConditionOrTimeout(
        base::test::ios::kWaitForPageLoadTimeout, ^bool {
          return callback_called;
        }));
    EXPECT_FALSE(callback_data);
  }
}
#endif

// Tests that CreateFullPagePDF invokes the callback with NSData.
TEST_F(WKWebViewUtilTest, IOS13EnsureCallbackIsCalled) {
  // Expeted: The callback is called with valid NSData.
  if (@available(iOS 14, *))
    return;

  WKWebViewConfiguration* config = [[WKWebViewConfiguration alloc] init];
  WKWebView* web_view = [[WKWebView alloc] initWithFrame:CGRectZero
                                           configuration:config];

  __block bool callback_called = false;
  __block NSData* callback_data = nil;

  CreateFullPagePdf(web_view, base::Bind(^(NSData* data) {
                      callback_called = true;
                      callback_data = [data copy];
                    }));

  ASSERT_TRUE(base::test::ios::WaitUntilConditionOrTimeout(
      base::test::ios::kWaitForPageLoadTimeout, ^bool {
        return callback_called;
      }));
  EXPECT_TRUE(callback_data);
}

// Tests that CreateFullPagePDF invokes the callback with NULL if
// its given a NULL WKWebView.
TEST_F(WKWebViewUtilTest, NULLWebView) {
  // Expected: callback is called with nil.
  __block bool callback_called = false;
  __block NSData* callback_data = nil;

  CreateFullPagePdf(nil, base::Bind(^(NSData* data) {
                      callback_called = true;
                      callback_data = [data copy];
                    }));

  ASSERT_TRUE(base::test::ios::WaitUntilConditionOrTimeout(
      base::test::ios::kWaitForPageLoadTimeout, ^bool {
        return callback_called;
      }));
  EXPECT_FALSE(callback_data);
}
}
