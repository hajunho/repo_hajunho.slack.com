// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/open_in/open_in_tab_helper.h"

#include "base/memory/ptr_util.h"
#include "base/strings/sys_string_conversions.h"
#import "ios/chrome/browser/open_in/features.h"
#include "ios/chrome/browser/ui/ui_feature_flags.h"
#include "ios/chrome/grit/ios_strings.h"
#import "ios/web/public/navigation/navigation_context.h"
#import "ios/web/public/navigation/navigation_item.h"
#import "ios/web/public/navigation/navigation_manager.h"
#import "ios/web/public/web_state.h"
#include "net/base/filename_util.h"
#include "net/http/http_response_headers.h"
#include "ui/base/l10n/l10n_util.h"
#include "url/gurl.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

namespace {

// .pptx extension.
const char kMimeTypeMicrosoftPowerPointOpenXML[] =
    "application/vnd.openxmlformats-officedocument.presentationml.presentation";

// .docx extension.
const char kMimeTypeMicrosoftWordOpenXML[] =
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document";

// .xlsx extension.
const char kMimeTypeMicrosoftExcelOpenXML[] =
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

// .pdf extension.
const char kMimeTypePDF[] = "application/pdf";

// .doc extension.
const char kMimeTypeMicrosoftWord[] = "application/msword";

// .jpeg or .jpg extension.
const char kMimeTypeJPEG[] = "image/jpeg";

// .png extension.
const char kMimeTypePNG[] = "image/png";

// .ppt extension.
const char kMimeTypeMicrosoftPowerPoint[] = "application/vnd.ms-powerpoint";

// .rtf extension.
const char kMimeTypeRTF[] = "application/rtf";

// .svg extension.
const char kMimeTypeSVG[] = "image/svg+xml";

// .xls extension.
const char kMimeTypeMicrosoftExcel[] = "application/vnd.ms-excel";

// .usdz extension.
const char kMimeTypeUSDZ[] = "model/vnd.usdz+zip";

}  // namespace

// static
void OpenInTabHelper::CreateForWebState(web::WebState* web_state) {
  DCHECK(web_state);
  if (!FromWebState(web_state)) {
    web_state->SetUserData(UserDataKey(),
                           base::WrapUnique(new OpenInTabHelper(web_state)));
  }
}

void OpenInTabHelper::SetDelegate(id<OpenInTabHelperDelegate> delegate) {
  delegate_ = delegate;
}

OpenInTabHelper::~OpenInTabHelper() {
  // In case that the destructor is called before WebStateDestroyed. stop
  // observing the WebState.
  if (web_state_) {
    web_state_->RemoveObserver(this);
    web_state_ = nullptr;
  }
}

bool OpenInTabHelper::isExportableFile() const {
  if (web_state_->GetContentsMimeType() == kMimeTypePDF)
    return true;
  if (web_state_->GetContentsMimeType() == kMimeTypeMicrosoftWord)
    return true;
  if (web_state_->GetContentsMimeType() == kMimeTypeMicrosoftWordOpenXML)
    return true;
  if (web_state_->GetContentsMimeType() == kMimeTypeJPEG)
    return true;
  if (web_state_->GetContentsMimeType() == kMimeTypePNG)
    return true;
  if (web_state_->GetContentsMimeType() == kMimeTypeMicrosoftPowerPoint)
    return true;
  if (web_state_->GetContentsMimeType() == kMimeTypeMicrosoftPowerPointOpenXML)
    return true;
  if (web_state_->GetContentsMimeType() == kMimeTypeRTF)
    return true;
  if (web_state_->GetContentsMimeType() == kMimeTypeSVG)
    return true;
  if (web_state_->GetContentsMimeType() == kMimeTypeMicrosoftExcel)
    return true;
  if (web_state_->GetContentsMimeType() == kMimeTypeMicrosoftExcelOpenXML)
    return true;
  if (web_state_->GetContentsMimeType() == kMimeTypeUSDZ)
    return true;

  return false;
}

void OpenInTabHelper::HandleExportableFile() {
  if (base::FeatureList::IsEnabled(kExtendOpenInFilesSupport)) {
    if (!isExportableFile())
      return;
  } else if (web_state_->GetContentsMimeType() != "application/pdf") {
    return;
  }

  // Try to generate a filename by first looking at |content_disposition_|, then
  // at the last component of WebState's last committed URL and if both of these
  // fail use the default filename "document".
  std::string content_disposition;
  if (response_headers_)
    response_headers_->GetNormalizedHeader("content-disposition",
                                           &content_disposition);
  std::string default_file_name =
      l10n_util::GetStringUTF8(IDS_IOS_OPEN_IN_FILE_DEFAULT_TITLE);
  web::NavigationItem* item =
      web_state_->GetNavigationManager()->GetLastCommittedItem();
  const GURL& last_committed_url = item ? item->GetURL() : GURL::EmptyGURL();
  base::string16 file_name =
      net::GetSuggestedFilename(last_committed_url, content_disposition,
                                "",  // referrer-charset
                                "",  // suggested-name
                                web_state_->GetContentsMimeType(),  // mime-type
                                default_file_name);
  [delegate_ enableOpenInForWebState:web_state_
                     withDocumentURL:last_committed_url
                   suggestedFileName:base::SysUTF16ToNSString(file_name)];
}

void OpenInTabHelper::DidStartNavigation(
    web::WebState* web_state,
    web::NavigationContext* navigation_context) {
  [delegate_ disableOpenInForWebState:web_state];
}

void OpenInTabHelper::DidFinishNavigation(
    web::WebState* web_state,
    web::NavigationContext* navigation_context) {
  // Retrieve the response headers to be used in case the Page loaded
  // successfully (PageLoaded WebStateObserver method will always be called
  // immediatly after DidFinishNavigation).
  response_headers_ = scoped_refptr<net::HttpResponseHeaders>(
      navigation_context->GetResponseHeaders());
}

OpenInTabHelper::OpenInTabHelper(web::WebState* web_state)
    : web_state_(web_state) {
  web_state_->AddObserver(this);
}

void OpenInTabHelper::PageLoaded(
    web::WebState* web_state,
    web::PageLoadCompletionStatus load_completion_status) {
  if (load_completion_status == web::PageLoadCompletionStatus::SUCCESS)
    HandleExportableFile();
}

void OpenInTabHelper::WebStateDestroyed(web::WebState* web_state) {
  DCHECK_EQ(web_state_, web_state);
  [delegate_ destroyOpenInForWebState:web_state];
  delegate_ = nil;
  // The call to RemoveUserData cause the destruction of the current instance,
  // so nothing should be done after that point (this is like "delete this;").
  // Unregistration as an observer happens in the destructor.
  web_state_->RemoveUserData(UserDataKey());
}

WEB_STATE_USER_DATA_KEY_IMPL(OpenInTabHelper)
