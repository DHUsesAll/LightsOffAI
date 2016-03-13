//
//  DHTOTLManager.m
//  TurnOffTheLights
//
//  Created by DreamHack on 16-3-9.
//  Copyright (c) 2015年 DreamHack. All rights reserved.
//

#import "DHLightGameManager.h"
#import "DHLightView.h"

static DHLightGameManager * manager_ = nil;
static const CGFloat size_ = 40;
static const CGFloat interval_ = 2;


@interface _DHLightGameAIManager : NSObject <DHLightGameAI>
/**
 *  保存解法的数组，元素是CGPoint
 */
@property (nonatomic, strong) NSMutableArray * steps;

@property (nonatomic, strong)dispatch_source_t timer;
/**
 *  找到第一排灯的正确状态以确保在用最后一排的灯关掉倒数一排的灯后最后一排的灯直接全部处于关闭状态
 */
- (BOOL)_findFirstRowState;

/**
 *  模拟关掉C语言二维数组中坐标为x，y的那个元素
 *
 *  @param x x
 *  @param y y
 */
- (void)turnLightAtX:(int)x y:(int)y forLights:(int **)lightStates;



@end


@interface DHLightGameManager ()

@property (nonatomic, strong) UIView * mainView;
@property (nonatomic, strong) NSMutableArray * lightsViewContainer;

// 每次点击首先改变灯的状态，再判断这次操作是不是把所有灯都关掉了遍
- (BOOL)_analyseLightsStateForLightAtCoordinate:(DHCoordinate)coordinate;
- (DHLightView *)_lightViewWithCoordinate:(DHCoordinate)coordinate;

@end

@implementation DHLightGameManager

#pragma mark - singleton

+ (DHLightGameManager *)defaultManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager_ = [[self alloc] init];
    });
    return manager_;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    if (!manager_) {
        manager_ = [super allocWithZone:zone];
    }
    return manager_;
}



#pragma mark - interface methods
- (void)forceDealloc
{
    [self.lightsViewContainer makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.lightsViewContainer = nil;
    [self.mainView removeFromSuperview];
    self.mainView = nil;
    self.gameAI = nil;
}

- (void)reset
{
    [self.lightsViewContainer enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DHLightView * lightView = obj;
        lightView.isOn = arc4random()%2;
    }];
}

- (void)layoutLightsWithRow:(NSUInteger)row column:(NSUInteger)column
{
    self.mainView.frame = CGRectMake(0, 0, column * size_ + (column - 1) * interval_, row * size_ + (row - 1) * interval_);
    
    
    [self.lightsViewContainer makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.lightsViewContainer removeAllObjects];
    _row = row;
    _column = column;
    for (int i = 0; i < row; i++) {
        for (int j = 0; j < column; j++) {
            
            
            DHLightView * lightView = [[DHLightView alloc] initWithFrame:CGRectMake(0, 0, size_, size_) coordinate:DHCoordinateMake(j, i)];
            lightView.center = CGPointMake(j * (size_ + interval_)+ size_/2, i * (size_ + interval_) + size_/2);
            [lightView addTarget:self action:@selector(onLight:) forControlEvents:UIControlEventTouchUpInside];
            [self.lightsViewContainer addObject:lightView];
            [self.mainView addSubview:lightView];
        }
    }
    BOOL state = [(_DHLightGameAIManager *)self.gameAI _findFirstRowState];
    if (!state) {
        // 递归直到此次布局有解为止
        [self layoutLightsWithRow:row column:column];
    }
}

#pragma mark - private methods
- (BOOL)_analyseLightsStateForLightAtCoordinate:(DHCoordinate)coordinate
{
    
    __block BOOL result = YES;

    // 遍历所有的灯，每次遍历出来的灯只要满足它处于coordinate所代表的灯的上下左右相邻的位置，这个灯就应该改变状态。
    [self.lightsViewContainer enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        DHLightView * aLightView = obj;
        
        BOOL selfState = aLightView.coordinate.x == coordinate.x && aLightView.coordinate.y == coordinate.y;
        
        BOOL leftState = aLightView.coordinate.x == coordinate.x - 1 && aLightView.coordinate.y == coordinate.y;
        BOOL rightState = aLightView.coordinate.x == coordinate.x + 1 && aLightView.coordinate.y == coordinate.y;
        BOOL topState = aLightView.coordinate.x == coordinate.x && aLightView.coordinate.y == coordinate.y + 1;
        BOOL bottomState = aLightView.coordinate.x == coordinate.x && aLightView.coordinate.y == coordinate.y - 1;
        
        if (leftState || rightState || topState || bottomState || selfState) {
            aLightView.isOn = !aLightView.isOn;
        }
        
        result = result && !aLightView.isOn;
    }];
    
    // 如果所有灯都关掉了，就返回yes
    return result;
}

- (DHLightView *)_lightViewWithCoordinate:(DHCoordinate)coordinate
{
    // 根据总行数和当前坐标算出数组下标
    // 因为放进数组的顺序是一行一行的放的
    // 每行有_row个灯
    NSInteger index = coordinate.y * _row + coordinate.x;
    
    return self.lightsViewContainer[index];
}

#pragma mark - action
- (void)onLight:(DHLightView *)sender
{
    BOOL result = [self _analyseLightsStateForLightAtCoordinate:sender.coordinate];
    if (result) {
        // To Do: 要回调的block或者协议
    }
}

#pragma mark - getter
- (UIView *)mainView
{
    if (!_mainView) {
        _mainView = [[UIView alloc] init];
        _mainView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }
    return _mainView;
}

- (NSMutableArray *)lightsViewContainer
{
    if (!_lightsViewContainer) {
        _lightsViewContainer = ({
        
            NSMutableArray * array = [NSMutableArray arrayWithCapacity:0];
            array;
        
        });
    }
    return _lightsViewContainer;
}

- (id<DHLightGameAI>)gameAI
{
    if (!_gameAI) {
        _gameAI = [[_DHLightGameAIManager alloc] init];
    }
    return _gameAI;
}


@end

@implementation _DHLightGameAIManager

#pragma mark - protocol
- (void)startResolve
{
    DHLightGameManager * manager =[DHLightGameManager defaultManager];
    
    __block int step = 0;
    // 开启GCD计时器
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        
        CGPoint coordinatePoint = [self.resolveSteps[step] CGPointValue];
        
        DHCoordinate coordinate = DHCoordinateMakeWithCGPoint(coordinatePoint);
        
        [manager  _analyseLightsStateForLightAtCoordinate:coordinate];
        
        step++;
        if (step == self.resolveSteps.count) {
            dispatch_source_cancel(timer);
        }
        
    });
    dispatch_resume(timer);
    
    self.timer = timer;
}

- (NSArray *)resolveSteps
{
    return [self.steps copy];
}

#pragma mark - private methods
- (BOOL)_findFirstRowState
{
    // no表示无解
    BOOL state = NO;
    DHLightGameManager * manager = [DHLightGameManager defaultManager];
    
    // 用一个C语言二维数组来代表每个灯的状态，0表示关，1表示开
    int ** stateArray = malloc(sizeof(int *) * manager.row);
    
    for (int i = 0; i < manager.row; i++) {
        stateArray[i] = malloc(sizeof(int) * manager.column);
    }
    
    [manager.lightsViewContainer enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        DHLightView * lightView = obj;
        NSUInteger x = lightView.coordinate.x;
        NSUInteger y = lightView.coordinate.y;
        stateArray[y][x] = lightView.isOn;
    }];
    
    // 用一个column位的二进制数表示第一排灯按不按的状态，1表示按，0表示不按
    // firstLineState二进制表示的后column位是第一排灯按不按
    int firstLineState = 0;
    unsigned int column = (int)manager.column;
    for (int i = 0; i < pow(2, column); i++) {
        
        
        // n = 1000...00, 1后面column-1个0
        int n = pow(2, column-1);
        
        // 比如resultArray里面的内容是 00101，则表示第一排第三个和第五个灯泡按一下
        int * resultArray = malloc(sizeof(int) * column);
        memset(resultArray, 0, sizeof(int) * column);
        
        for (int j = 0; j < column; j++) {
            
            int result = firstLineState & n;
            n = n >> 1;
            if (result) {
                resultArray[j] = 1;
            }
            
        }
        
        
        // 拷贝一份stateArray
        
        int ** temp = malloc(sizeof(int *) * manager.row);
        
        for (int i = 0; i < manager.row; i++) {
            temp[i] = malloc(sizeof(int) * manager.column);
            memcpy(temp[i], stateArray[i], sizeof(int) * manager.column);
        }
        
        // 根据resultArray关掉第一排
        for (int i = 0; i < manager.column; i++) {
            if (resultArray[i]) {
                [self turnLightAtX:i y:0 forLights:temp];
                [self.steps addObject:[NSValue valueWithCGPoint:CGPointMake(i, 0)]];
            }
            
        }
        
        // 依次关掉后面的灯
        for (int i = 1; i < manager.row; i++) {
            
            for (int j = 0; j < manager.column; j++) {
                
                if (temp[i-1][j] == 1) {
                    [self turnLightAtX:j y:i forLights:temp];
                    [self.steps addObject:[NSValue valueWithCGPoint:CGPointMake(j, i)]];
                }
            }
        }
        // 看最后一行里面是不是全为0，如果全为0，则break
        int lastResult = 0;
        for (int i = 0; i < manager.column; i++) {
            lastResult += temp[manager.row - 1][i];
        }
        
        if (lastResult == 0) {
            free(resultArray);
            for (int i = 0; i < manager.row; i++) {
                free(temp[i]);
            }
            free(temp);
            state = YES;
            NSLog(@"解法：%@",self.resolveSteps);
            break;
        } else {
            [self.steps removeAllObjects];
        }
        firstLineState++;
        free(resultArray);
        for (int i = 0; i < manager.row; i++) {
            free(temp[i]);
        }
        free(temp);
    }
    
    for (int i = 0; i < manager.row; i++) {
        free(stateArray[i]);
    }
    
    free(stateArray);
    return state;
}

- (void)turnLightAtX:(int)x y:(int)y forLights:(int **)lightStates
{
    DHLightGameManager * manager = [DHLightGameManager defaultManager];
    lightStates[y][x] = !lightStates[y][x];
    if (y-1 >= 0) {
        lightStates[y-1][x] = !lightStates[y-1][x];
    }
    if (x-1 >= 0) {
        lightStates[y][x-1] = !lightStates[y][x-1];
    }
    if (y+1 <  manager.row) {
        lightStates[y+1][x] = !lightStates[y+1][x];
    }
    if (x+1 <  manager.column) {
        lightStates[y][x+1] = !lightStates[y][x+1];
    }
}

#pragma mark - getter
- (NSMutableArray *)steps
{
    if (!_steps) {
        _steps = [NSMutableArray arrayWithCapacity:0];
    }
    return _steps;
}




@end




//@implementation DHLightGameAI
//
//- (void)startResolve
//{
//    DHLightGameManager * manager =[DHLightGameManager defaultManager];
//    
//    __block int step = 0;
//    // 开启GCD计时器
//    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
//    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
//    dispatch_source_set_event_handler(timer, ^{
//        
//        CGPoint coordinatePoint = [self.resolveSteps[step] CGPointValue];
//        
//        DHCoordinate coordinate = DHCoordinateMakeWithCGPoint(coordinatePoint);
//        
//        [manager  _analyseLightsStateForLightAtCoordinate:coordinate];
//        
//        step++;
//        if (step == self.resolveSteps.count) {
//            dispatch_source_cancel(timer);
//        }
//        
//    });
//    dispatch_resume(timer);
//    
//    self.timer = timer;
//}
//
//#pragma mark - private methods
//- (BOOL)findFirstRowState
//{
//    // no表示无解
//    BOOL state = NO;
//    DHLightGameManager * manager = [DHLightGameManager defaultManager];
//    
//    // 用一个C语言二维数组来代表每个灯的状态，0表示关，1表示开
//    int ** stateArray = malloc(sizeof(int *) * manager.row);
//    
//    for (int i = 0; i < manager.row; i++) {
//        stateArray[i] = malloc(sizeof(int) * manager.column);
//    }
//    
//    [manager.lightsViewContainer enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//        
//        DHLightView * lightView = obj;
//        NSUInteger x = lightView.coordinate.x;
//        NSUInteger y = lightView.coordinate.y;
//        stateArray[y][x] = lightView.isOn;
//    }];
//    
//    // 用一个column位的二进制数表示第一排灯按不按的状态，1表示按，0表示不按
//    // firstLineState二进制表示的后column位是第一排灯按不按
//    int firstLineState = 0;
//    unsigned int column = (int)manager.column;
//    for (int i = 0; i < pow(2, column); i++) {
//        
//        
//        // n = 1000...00, 1后面column-1个0
//        int n = pow(2, column-1);
//        
//        // 比如resultArray里面的内容是 00101，则表示第一排第三个和第五个灯泡按一下
//        int * resultArray = malloc(sizeof(int) * column);
//        memset(resultArray, 0, sizeof(int) * column);
//        
//        for (int j = 0; j < column; j++) {
//            
//            int result = firstLineState & n;
//            n = n >> 1;
//            if (result) {
//                resultArray[j] = 1;
//            }
//            
//        }
//        
//        
//        // 拷贝一份stateArray
//        
//        int ** temp = malloc(sizeof(int *) * manager.row);
//        
//        for (int i = 0; i < manager.row; i++) {
//            temp[i] = malloc(sizeof(int) * manager.column);
//            memcpy(temp[i], stateArray[i], sizeof(int) * manager.column);
//        }
//        
//        // 根据resultArray关掉第一排
//        for (int i = 0; i < manager.column; i++) {
//            if (resultArray[i]) {
//                [self turnLightAtX:i y:0 forLights:temp];
//                [self.resolveSteps addObject:[NSValue valueWithCGPoint:CGPointMake(i, 0)]];
//            }
//            
//        }
//        
//        // 依次关掉后面的灯
//        for (int i = 1; i < manager.row; i++) {
//            
//            for (int j = 0; j < manager.column; j++) {
//                
//                if (temp[i-1][j] == 1) {
//                    [self turnLightAtX:j y:i forLights:temp];
//                    [self.resolveSteps addObject:[NSValue valueWithCGPoint:CGPointMake(j, i)]];
//                }
//            }
//        }
//        // 看最后一行里面是不是全为0，如果全为0，则break
//        int lastResult = 0;
//        for (int i = 0; i < manager.column; i++) {
//            lastResult += temp[manager.row - 1][i];
//        }
//        
//        if (lastResult == 0) {
//            free(resultArray);
//            for (int i = 0; i < manager.row; i++) {
//                free(temp[i]);
//            }
//            free(temp);
//            state = YES;
//            NSLog(@"解法：%@",self.resolveSteps);
//            break;
//        } else {
//            [self.resolveSteps removeAllObjects];
//        }
//        firstLineState++;
//        free(resultArray);
//        for (int i = 0; i < manager.row; i++) {
//            free(temp[i]);
//        }
//        free(temp);
//    }
//    
//    for (int i = 0; i < manager.row; i++) {
//        free(stateArray[i]);
//    }
//    
//    free(stateArray);
//    return state;
//}
//
//- (void)turnLightAtX:(int)x y:(int)y forLights:(int **)lightStates
//{
//    DHLightGameManager * manager = [DHLightGameManager defaultManager];
//    lightStates[y][x] = !lightStates[y][x];
//    if (y-1 >= 0) {
//        lightStates[y-1][x] = !lightStates[y-1][x];
//    }
//    if (x-1 >= 0) {
//        lightStates[y][x-1] = !lightStates[y][x-1];
//    }
//    if (y+1 <  manager.row) {
//        lightStates[y+1][x] = !lightStates[y+1][x];
//    }
//    if (x+1 <  manager.column) {
//        lightStates[y][x+1] = !lightStates[y][x+1];
//    }
//}
//
//#pragma mark - getter
//- (NSMutableArray *)resolveSteps
//{
//    if (!_resolveSteps) {
//        _resolveSteps = [NSMutableArray arrayWithCapacity:0];
//    }
//    return _resolveSteps;
//}
//
//@end





