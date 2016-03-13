//
//  DHTOTLManager.h
//  TurnOffTheLights
//
//  Created by DreamHack on 16-3-9.
//  Copyright (c) 2015年 DreamHack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@protocol DHLightGameAI <NSObject>

@property (nonatomic, strong, readonly) NSArray * resolveSteps;

- (void)startResolve;

@end

@interface DHLightGameManager : NSObject<NSCopying>

@property (nonatomic, assign, readonly) NSUInteger row;
@property (nonatomic, assign, readonly) NSUInteger column;

/**
 *  主要负责显示的视图，需手动设置frame
 */
@property (nonatomic, strong, readonly) UIView * mainView;

@property (nonatomic, strong) id <DHLightGameAI> gameAI;


+ (DHLightGameManager *)defaultManager;
- (id)copyWithZone:(NSZone *)zone;
+ (instancetype)allocWithZone:(struct _NSZone *)zone;

/**
 *  强制移除视图所占的内存
 */
- (void)forceDealloc;

/**
 *  重新开始游戏
 */
- (void)reset;

/**
 *  对所有的灯泡进行布局
 *
 *  @param row    灯泡的行数
 *  @param column 灯泡的列数
 */
- (void)layoutLightsWithRow:(NSUInteger)row column:(NSUInteger)column;

@end



