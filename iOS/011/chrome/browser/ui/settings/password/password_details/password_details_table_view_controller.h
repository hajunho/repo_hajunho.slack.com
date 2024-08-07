// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_SETTINGS_PASSWORD_PASSWORD_DETAILS_PASSWORD_DETAILS_TABLE_VIEW_CONTROLLER_H_
#define IOS_CHROME_BROWSER_UI_SETTINGS_PASSWORD_PASSWORD_DETAILS_PASSWORD_DETAILS_TABLE_VIEW_CONTROLLER_H_

#import "ios/chrome/browser/ui/settings/autofill/autofill_edit_table_view_controller.h"
#import "ios/chrome/browser/ui/settings/password/password_details/password_details_consumer.h"

@protocol ApplicationCommands;
@protocol PasswordDetailsHandler;
@protocol PasswordDetailsTableViewControllerDelegate;
@protocol ReauthenticationProtocol;

// Screen which shows password details and allows to edit it.
@interface PasswordDetailsTableViewController
    : AutofillEditTableViewController <PasswordDetailsConsumer>

// Handler for PasswordDetails related actions.
@property(nonatomic, weak) id<PasswordDetailsHandler> handler;

// Delegate for PasswordDetails related actions e.g. Password editing.
@property(nonatomic, weak) id<PasswordDetailsTableViewControllerDelegate>
    delegate;

// Dispatcher for this ViewController.
@property(nonatomic, weak) id<ApplicationCommands> commandsDispatcher;

// Module containing the reauthentication mechanism for interactions
// with password.
@property(nonatomic, weak) id<ReauthenticationProtocol> reauthModule;

// Called by coordinator when the user confirmed password editing from alert.
- (void)passwordEditingConfirmed;

@end

#endif  // IOS_CHROME_BROWSER_UI_SETTINGS_PASSWORD_PASSWORD_DETAILS_PASSWORD_DETAILS_TABLE_VIEW_CONTROLLER_H_
