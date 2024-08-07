// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/components/security_interstitials/lookalikes/lookalike_url_blocking_page.h"

#include <utility>

#include "base/strings/string_number_conversions.h"
#include "base/values.h"
#include "components/lookalikes/core/lookalike_url_ui_util.h"
#include "components/lookalikes/core/lookalike_url_util.h"
#include "components/security_interstitials/core/common_string_util.h"
#include "components/security_interstitials/core/metrics_helper.h"
#include "ios/components/security_interstitials/ios_blocking_page_controller_client.h"
#include "ios/components/security_interstitials/ios_blocking_page_metrics_helper.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

LookalikeUrlBlockingPage::LookalikeUrlBlockingPage(
    web::WebState* web_state,
    const GURL& safe_url,
    const GURL& request_url,
    ukm::SourceId source_id,
    LookalikeUrlMatchType match_type,
    std::unique_ptr<LookalikeUrlControllerClient> client)
    : security_interstitials::IOSSecurityInterstitialPage(web_state,
                                                          request_url,
                                                          client.get()),
      web_state_(web_state),
      controller_(std::move(client)),
      safe_url_(safe_url),
      source_id_(source_id),
      match_type_(match_type) {
  DCHECK(web_state_);
  controller_->metrics_helper()->RecordUserDecision(
      security_interstitials::MetricsHelper::SHOW);
  controller_->metrics_helper()->RecordUserInteraction(
      security_interstitials::MetricsHelper::TOTAL_VISITS);

  // Creating an interstitial without showing it (e.g. from
  // chrome://interstitials) leaks memory, so don't create it here.
}

LookalikeUrlBlockingPage::~LookalikeUrlBlockingPage() {
  // Update metrics when the interstitial is closed or user navigates away.
  ReportUkmForLookalikeUrlBlockingPageIfNeeded(
      source_id_, match_type_,
      LookalikeUrlBlockingPageUserAction::kCloseOrBack);
}

bool LookalikeUrlBlockingPage::ShouldCreateNewNavigation() const {
  return true;
}

void LookalikeUrlBlockingPage::PopulateInterstitialStrings(
    base::DictionaryValue* load_time_data) const {
  CHECK(load_time_data);

  // Set a value if backwards navigation is not available, used
  // to change the button text to 'Close page' when there is no
  // suggested URL.
  if (!controller_->CanGoBack()) {
    load_time_data->SetBoolean("cant_go_back", true);
  }

  PopulateLookalikeUrlBlockingPageStrings(load_time_data, safe_url_,
                                          request_url());
}

void LookalikeUrlBlockingPage::HandleScriptCommand(
    const base::DictionaryValue& message,
    const GURL& origin_url,
    bool user_is_interacting,
    web::WebFrame* sender_frame) {
  std::string command_string;
  if (!message.GetString("command", &command_string)) {
    LOG(ERROR) << "JS message parameter not found: command";
    return;
  }

  // Remove the command prefix so that the string value can be converted to a
  // SecurityInterstitialCommand enum value.
  std::size_t delimiter = command_string.find(".");
  if (delimiter == std::string::npos) {
    return;
  }

  // Parse the command int value from the text after the delimiter.
  int command = 0;
  if (!base::StringToInt(command_string.substr(delimiter + 1), &command)) {
    NOTREACHED() << "Command cannot be parsed to an int : " << command_string;
    return;
  }

  if (command == security_interstitials::CMD_DONT_PROCEED) {
    controller_->metrics_helper()->RecordUserDecision(
        security_interstitials::MetricsHelper::DONT_PROCEED);
    ReportUkmForLookalikeUrlBlockingPageIfNeeded(
        source_id_, match_type_,
        LookalikeUrlBlockingPageUserAction::kAcceptSuggestion);
      controller_->GoBack();
  } else if (command == security_interstitials::CMD_PROCEED) {
    controller_->metrics_helper()->RecordUserDecision(
        security_interstitials::MetricsHelper::PROCEED);
    ReportUkmForLookalikeUrlBlockingPageIfNeeded(
        source_id_, match_type_,
        LookalikeUrlBlockingPageUserAction::kClickThrough);
    controller_->Proceed();
  }
}

void LookalikeUrlBlockingPage::AfterShow() {}
