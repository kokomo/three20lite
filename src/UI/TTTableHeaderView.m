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

#import "TTTableHeaderView.h"

// UI
#import "UIViewAdditions.h"

// Style
#import "TTGlobalStyle.h"
#import "TTDefaultStyleSheet.h"

// Core
#import "TTCorePreprocessorMacros.h"
#import "TTGlobalCoreLocale.h"

#import <QuartzCore/QuartzCore.h>

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTTableHeaderView


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithTitle:(NSString*)title {
	self = [super init];
  if (self) {
    self.backgroundColor = [UIColor clearColor];
    self.style = TTSTYLE(tableHeader);

    _label = [[UILabel alloc] init];
    _label.text = title;
    NSLocale* locale = TTCurrentLocale();
    
    if ([locale.localeIdentifier isEqualToString:@"he"]) {
      _label.textAlignment = UITextAlignmentRight;
    }
    _label.backgroundColor = [UIColor clearColor];
    _label.textColor = [UIColor whiteColor];
    _label.shadowColor = RGBCOLOR(100, 100, 100);
    _label.shadowOffset = CGSizeMake(0, 1);
    _label.font = TTSTYLEVAR(tableHeaderPlainFont);
    [self addSubview:_label];
  }

  return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)drawRect:(CGRect)rect {
  [super drawRect:rect];
  NSLocale* locale = TTCurrentLocale();

  if ([locale.localeIdentifier isEqualToString:@"he"]) {
  UIColor* lineColor = RGBCOLOR(94, 94, 94);
  UIColor* topColor = RGBCOLOR(144, 159, 170);
  UIColor* bottomColor = RGBCOLOR(199, 199, 199);

  //add a gradient:
  CAGradientLayer *gradientLayer = [[[CAGradientLayer alloc] init] autorelease];
  [gradientLayer setBounds:[self bounds]];
  CGRect newRect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height -1);
  [gradientLayer setFrame:newRect];
  [gradientLayer setColors:[NSArray arrayWithObjects:(id)[topColor CGColor], (id)[bottomColor CGColor], nil]];
  [[self layer] insertSublayer:gradientLayer atIndex:0];

  //draw line
  CGContextRef ctx = UIGraphicsGetCurrentContext(); 
  CGContextBeginPath(ctx);
  // This gets the RGB Float values from the color initialized for lineColor
  const float* colors = CGColorGetComponents( lineColor.CGColor );
    CGContextSetRGBStrokeColor(ctx, colors[0], colors[1], colors[2], 1);
    
  CGContextMoveToPoint(ctx, 0, rect.size.height);
  CGContextAddLineToPoint( ctx, rect.size.width, rect.size.height);
  CGContextStrokePath(ctx);
  }
}
///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
  TT_RELEASE_SAFELY(_label);

  [super dealloc];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIView


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
  _label.size = [_label sizeThatFits:CGSizeMake(self.bounds.size.width - 12,
                                                self.bounds.size.height)];
  _label.origin = CGPointMake(self.frame.size.width-_label.frame.size.width-12, floorf((self.bounds.size.height - _label.size.height)/2.f));
}


@end
