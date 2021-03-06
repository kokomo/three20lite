//
// Copyright 2009-2011 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "TTWebController.h"

// UI
#import "UIViewAdditions.h"
#import "UIToolbarAdditions.h"

// UINavigator
#import "TTGlobalNavigatorMetrics.h"

// UICommon
#import "TTGlobalUICommon.h"

// Style
#import "TTGlobalStyle.h"
#import "TTDefaultStyleSheet.h"
#import "TTStyleSheet.h"

// Network
#import "TTGlobalNetwork.h"
#import "TTURLCache.h"

// Core
#import "TTCorePreprocessorMacros.h"
#import "TTGlobalCoreLocale.h"


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTWebController

@synthesize delegate    = _delegate;
@synthesize headerView  = _headerView;


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.hidesBottomBarWhenPushed = YES;
  }

  return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithNavigatorURL:(NSURL*)URL query:(NSDictionary*)query {
	self = [self initWithNibName:nil bundle:nil];
  if (self) {
    NSURLRequest* request = [query objectForKey:@"request"];
    if (nil != request) {
      [self openRequest:request];

    } else {
      [self openURL:URL];
    }
  }
  return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init {
	self = [self initWithNibName:nil bundle:nil];
  if (self) {
  }

  return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
  TT_RELEASE_SAFELY(_loadingURL);
  TT_RELEASE_SAFELY(_headerView);
  TT_RELEASE_SAFELY(_actionSheet);

  [super dealloc];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)backAction {
  [_webView goBack];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)forwardAction {
  [_webView goForward];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)refreshAction {
  [_webView reload];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)stopAction {
  [_webView stopLoading];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)shareAction {
  if (nil != _actionSheet && [_actionSheet isVisible]) {
    //should only happen on the iPad
    assert(TTIsPad());
    [_actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
    return;
  }

  if (nil == _actionSheet) {
    _actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                               delegate:self
                                      cancelButtonTitle:TTLocalizedString(@"Cancel", @"")
                                 destructiveButtonTitle:nil
                                      otherButtonTitles:TTLocalizedString(@"Open in Safari", @""),
                                                        nil];
    if (TTIsPad()) {
      [_actionSheet showFromBarButtonItem:_actionButton animated:YES];

    }  else {
      [_actionSheet showInView: self.view];
    }
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)updateToolbarWithOrientation:(UIInterfaceOrientation)interfaceOrientation {
  _toolbar.height = TTToolbarHeight();
  _webView.height = self.view.height - _toolbar.height;
  _toolbar.top = self.view.height - _toolbar.height;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIViewController


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)loadView {
  [super loadView];

  _webView = [[UIWebView alloc] initWithFrame:TTToolbarNavigationFrame()];
  _webView.delegate = self;
  _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth
  | UIViewAutoresizingFlexibleHeight;
  _webView.scalesPageToFit = YES;
  [self.view addSubview:_webView];

  UIActivityIndicatorView* spinner =
    [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
      UIActivityIndicatorViewStyleWhite] autorelease];
  [spinner startAnimating];
  _activityItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];

  _backButton =
    [[UIBarButtonItem alloc] initWithImage:TTIMAGE(@"bundle://Three20.bundle/images/backIcon.png")
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(backAction)];
  _backButton.tag = 2;
  _backButton.enabled = NO;
  _forwardButton =
    [[UIBarButtonItem alloc] initWithImage:
     TTIMAGE(@"bundle://Three20.bundle/images/forwardIcon.png")
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(forwardAction)];
  _forwardButton.tag = 1;
  _forwardButton.enabled = NO;
  _refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
                    UIBarButtonSystemItemRefresh target:self action:@selector(refreshAction)];
  _refreshButton.tag = 3;
  _stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
                 UIBarButtonSystemItemStop target:self action:@selector(stopAction)];
  _stopButton.tag = 3;
  _actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
                   UIBarButtonSystemItemAction target:self action:@selector(shareAction)];

  UIBarItem* space = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:
                       UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];

  _toolbar = [[UIToolbar alloc] initWithFrame:
              CGRectMake(0, self.view.height - TTToolbarHeight(),
                         self.view.width, TTToolbarHeight())];
  _toolbar.autoresizingMask =
  UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
  _toolbar.tintColor = TTSTYLEVAR(toolbarTintColor);
  _toolbar.items = [NSArray arrayWithObjects:
                    _backButton,
                    space,
                    _forwardButton,
                    space,
                    _refreshButton,
                    space,
                    _actionButton,
                    nil];
  [self.view addSubview:_toolbar];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidUnload {
  [super viewDidUnload];

  _delegate = nil;
  _webView.delegate = nil;

  TT_RELEASE_SAFELY(_webView);
  TT_RELEASE_SAFELY(_toolbar);
  TT_RELEASE_SAFELY(_backButton);
  TT_RELEASE_SAFELY(_forwardButton);
  TT_RELEASE_SAFELY(_refreshButton);
  TT_RELEASE_SAFELY(_stopButton);
  TT_RELEASE_SAFELY(_actionButton);
  TT_RELEASE_SAFELY(_activityItem);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self updateToolbarWithOrientation:self.interfaceOrientation];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewWillDisappear:(BOOL)animated {
  // If the browser launched the media player, it steals the key window and never gives it
  // back, so this is a way to try and fix that
  [self.view.window makeKeyWindow];

  [super viewWillDisappear:animated];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return TTIsSupportedOrientation(interfaceOrientation);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration {
  [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self updateToolbarWithOrientation:toInterfaceOrientation];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView*)rotatingFooterView {
  return _toolbar;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UTViewController (TTCategory)


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)persistView:(NSMutableDictionary*)state {
  NSString* URL = self.URL.absoluteString;
  if (URL.length && ![URL isEqualToString:@"about:blank"]) {
    [state setObject:URL forKey:@"URL"];
    return YES;

  } else {
    return NO;
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)restoreView:(NSDictionary*)state {
  NSString* URL = [state objectForKey:@"URL"];
  if (URL.length && ![URL isEqualToString:@"about:blank"]) {
    [self openURL:[NSURL URLWithString:URL]];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIWebViewDelegate


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request
 navigationType:(UIWebViewNavigationType)navigationType {
  if ([_delegate respondsToSelector:
       @selector(webController:webView:shouldStartLoadWithRequest:navigationType:)] &&
      ![_delegate webController:self webView:webView
     shouldStartLoadWithRequest:request navigationType:navigationType]) {
    return NO;
  }


  [_loadingURL release];
  _loadingURL = [request.URL retain];
  _backButton.enabled = [_webView canGoBack];
  _forwardButton.enabled = [_webView canGoForward];
  return YES;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)webViewDidStartLoad:(UIWebView*)webView {
  if ([_delegate respondsToSelector:@selector(webController:webViewDidStartLoad:)]) {
    [_delegate webController:self webViewDidStartLoad:webView];
  }

  self.title = TTLocalizedString(@"Loading...", @"");
  if (!self.navigationItem.rightBarButtonItem) {
    [self.navigationItem setRightBarButtonItem:_activityItem animated:YES];
  }
  [_toolbar replaceItemWithTag:3 withItem:_stopButton];
  _backButton.enabled = [_webView canGoBack];
  _forwardButton.enabled = [_webView canGoForward];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)webViewDidFinishLoad:(UIWebView*)webView {
  if ([_delegate respondsToSelector:@selector(webController:webViewDidFinishLoad:)]) {
    [_delegate webController:self webViewDidFinishLoad:webView];
  }

  TT_RELEASE_SAFELY(_loadingURL);
  self.title = [_webView stringByEvaluatingJavaScriptFromString:@"document.title"];
  if (self.navigationItem.rightBarButtonItem == _activityItem) {
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
  }
  [_toolbar replaceItemWithTag:3 withItem:_refreshButton];

  _backButton.enabled = [_webView canGoBack];
  _forwardButton.enabled = [_webView canGoForward];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
  if ([_delegate respondsToSelector:@selector(webController:webView:didFailLoadWithError:)]) {
    [_delegate webController:self webView:webView didFailLoadWithError:error];
  }

  TT_RELEASE_SAFELY(_loadingURL);
  [self webViewDidFinishLoad:webView];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIActionSheetDelegate


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 0) {
    [[UIApplication sharedApplication] openURL:self.URL];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
  TT_RELEASE_SAFELY(_actionSheet);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSURL*)URL {
  return _loadingURL ? _loadingURL : _webView.request.URL;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setHeaderView:(UIView*)headerView {
  if (headerView != _headerView) {
    BOOL addingHeader = !_headerView && headerView;
    BOOL removingHeader = _headerView && !headerView;

    [_headerView removeFromSuperview];
    [_headerView release];
    _headerView = [headerView retain];
    _headerView.frame = CGRectMake(0, 0, _webView.width, _headerView.height);

    [self view];
    UIView* scroller = [_webView descendantOrSelfWithClass:NSClassFromString(@"UIScroller")];
    UIView* docView = [scroller descendantOrSelfWithClass:NSClassFromString(@"UIWebDocumentView")];
    [scroller addSubview:_headerView];

    if (addingHeader) {
      docView.top += headerView.height;
      docView.height -= headerView.height;

    } else if (removingHeader) {
      docView.top -= headerView.height;
      docView.height += headerView.height;
    }
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)openURL:(NSURL*)URL {
  NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
  [self openRequest:request];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)openRequest:(NSURLRequest*)request {
  [self view];
  [_webView loadRequest:request];
}


@end
