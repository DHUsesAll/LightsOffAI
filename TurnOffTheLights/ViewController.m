//
//  ViewController.m
//  TurnOffTheLights
//
//  Created by DreamHack on 16-3-9.
//  Copyright (c) 2015年 DreamHack. All rights reserved.
//

#import "ViewController.h"
#import "DHLightGameManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    DHLightGameManager * manager = [DHLightGameManager defaultManager];

    [manager layoutLightsWithRow:6 column:7];
    
    [self.view addSubview:manager.mainView];
    
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[DHLightGameManager defaultManager].gameAI startResolve];
}


@end
