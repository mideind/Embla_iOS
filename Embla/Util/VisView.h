//
//  VisView.h
//  Embla
//
//  Created by Sveinbjorn Thordarson on 06/11/2019.
//  Copyright © 2019 Google. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VisView : UIView

- (instancetype)initWithBars:(NSInteger)barCount frame:(CGRect)frame color:(UIColor *)aColor;
- (void)addSampleLevel:(CGFloat)level;

@end
