// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_COMPONENTS_SECURITY_INTERSTITIALS_LOOKALIKES_LOOKALIKE_URL_BLOCKING_PAGE_H_
#define IOS_COMPONENTS_SECURITY_INTERSTITIALS_LOOKALIKES_LOOKALIKE_URL_BLOCKING_PAGE_H_

#include "components/lookalikes/core/lookalike_url_util.h"
#include "ios/components/security_interstitials/ios_security_interstitial_page.h"
#include "ios/components/security_interstitials/lookalikes/lookalike_url_controller_client.h"
#include "services/metrics/public/cpp/ukm_source_id.h"

class GURL;

// This class is responsible for showing/hiding the interstitial page that is
// shown on a lookalike URL.
class LookalikeUrlBlockingPage
    : public security_interstitials::IOSSecurityInterstitialPage {
 public:
  ~LookalikeUrlBlockingPage() override;

  // Creates a lookalike URL blocking page.
  LookalikeUrlBlockingPage(
      web::WebState* web_state,
      const GURL& safe_url,
      const GURL& request_url,
      ukm::SourceId source_id,
      LookalikeUrlMatchType match_type,
      std::unique_ptr<LookalikeUrlControllerClient> client);

 protected:
  // SecurityInterstitialPage implementation:
  bool ShouldCreateNewNavigation() const override;
  void PopulateInterstitialStrings(
      base::DictionaryValue* load_time_data) const override;

 private:
  void HandleScriptCommand(const base::DictionaryValue& message,
                           const GURL& origin_url,
                           bool user_is_interacting,
                           web::WebFrame* sender_frame) override;

  void AfterShow() override;

  web::WebState* web_state_ = nullptr;
  std::unique_ptr<LookalikeUrlControllerClient> controller_;
  // The URL suggested to the user as the safe URL. Can be empty, in which case
  // the default action on the interstitial is to go back or close the tab.
  const GURL safe_url_;
  ukm::SourceId source_id_;
  LookalikeUrlMatchType match_type_;

  DISALLOW_COPY_AND_ASSIGN(LookalikeUrlBlockingPage);
};

#endif  // IOS_COMPONENTS_SECURITY_INTERSTITIALS_LOOKALIKES_LOOKALIKE_URL_BLOCKING_PAGE_H_
