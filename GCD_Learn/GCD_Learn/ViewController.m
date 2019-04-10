//
//  ViewController.m
//  GCD_Learn
//
//  Created by 聂宽 on 2019/1/18.
//  Copyright © 2019年 聂宽. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
// 串行队列
@property (nonatomic, strong) dispatch_queue_t serialQueue;
// 并行队列
@property (nonatomic, strong) dispatch_queue_t concurrentQueue;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 创建队列
    [self GCD_queue];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
//    [self GCD_barrier_async];
    [self GCD_semaphore];
}

// dispatch_queue_create 创建队列
- (void)GCD_queue
{
    // 串行队列
    dispatch_queue_t serialQueue = dispatch_queue_create("serial_queue_Identifier", DISPATCH_QUEUE_SERIAL);
    _serialQueue = serialQueue;
    // 并行队列
    dispatch_queue_t concurrentQueue = dispatch_queue_create("concurrent_queue_identifier", DISPATCH_QUEUE_CONCURRENT);
    _concurrentQueue = concurrentQueue;
    
    NSLog(@"%s -------------- dispatch_queue_create", __func__);
}

// sync + 串行队列 = 不会开线程、任务顺序执行
- (void)CGD_sync_serialQueue
{
    for (int i = 0; i < 5; i++) {
        dispatch_sync(_serialQueue, ^{
            NSLog(@"%s ---Thread：%@--- %d", __func__, [NSThread currentThread], i);
        });
    }
}

// sync + 并行队列 = 不会开线程、任务顺序执行
- (void)GCD_sync_concurrentQueue
{
    for (int i = 0; i < 5; i++) {
        dispatch_sync(_concurrentQueue, ^{
            NSLog(@"%s ---Thread：%@--- %d", __func__, [NSThread currentThread], i);
        });
    }
}

// async + 串行队列 = 只开一个线程、在此线程中顺序执行
- (void)GCD_async_serialQueue
{
    for (int i = 0; i < 5; i++) {
        dispatch_async(_serialQueue, ^{
            NSLog(@"%s ---Thread：%@--- %d", __func__, [NSThread currentThread], i);
        });
    }
}

// async + 并行队列 = 开多个线程、任务并行执行
- (void)GCD_async_concurrentQueue
{
    for (int i = 0; i < 5; i++) {
        dispatch_async(_concurrentQueue, ^{
            NSLog(@"%s ---Thread：%@--- %d", __func__, [NSThread currentThread], i);
        });
    }
}

//
- (void)GCD_sync_mainQueue_in_subThread
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"%s ---Thread：%@---", __func__, [NSThread currentThread]);
        for (int i = 0; i < 5; i++) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSLog(@"%s ---Thread：%@--- %d", __func__, [NSThread currentThread], i);
            });
        }
    });
    
}

- (void)GCD_async_mainQueue
{
    for (int i = 0; i < 5; i++) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"%s ---Thread：%@--- %d", __func__, [NSThread currentThread], i);
        });
    }
}

//- GCD 栅栏方法：dispatch_barrier_async
- (void)GCD_barrier_async
{
    // A任务
    for (int i = 0; i < 3; i++) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"Thread：%@--- A任务 --- %d", [NSThread currentThread], i);
        });
    }
    // Barrier任务
    dispatch_barrier_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"Thread：%@--- Barrier任务", [NSThread currentThread]);
    });

    // B任务
    for (int i = 0; i < 3; i++) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"Thread：%@--- B任务 --- %d", [NSThread currentThread], i);
        });
    }
}

//
- (void)GCD_async_gounp_notify
{
    dispatch_group_t group = dispatch_group_create();
    
    for (int i = 0; i < 3; i++) {
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"Thread：%@--- A任务 --- %d", [NSThread currentThread], i);
        });
    }
    
    for (int i = 0; i < 3; i++) {
        dispatch_group_async(group, _concurrentQueue, ^{
            NSLog(@"Thread：%@--- B任务 --- %d", [NSThread currentThread], i);
        });
    }
    
    // 任务A 任务B都完成之后，执行notify的任务
    // 任务A、B加到了同一group中
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
       NSLog(@"Thread：%@--- 任务A 任务B 执行之后的操作", [NSThread currentThread]);
    });
}

// 信号量控制同时执行最大并发数（线程最大数量）
- (void)GCD_semaphore
{
    // 创建信号量,设置最大并发数为2 dispatch_semaphore_create(2)
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(2);
    
    for (int i = 0; i < 10; i++) {
        // 异步函数+串行队列，开一个线程顺序执行任务
        dispatch_async(_serialQueue, ^{
            // 等待降低信号量，信号量-1 dispatch_semaphore_wait（信号量，等待时间）
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            // 异步函数+并行队列，开多个线程并发执行任务
            dispatch_async(_concurrentQueue, ^{
                NSLog(@"%@--------开始——任务%d", [NSThread currentThread], i);
                sleep(1);
                NSLog(@"%@--------结束——任务%d", [NSThread currentThread], i);
                // 提高信号量，信号量+1  dispatch_semaphore_signal(信号量)
                dispatch_semaphore_signal(semaphore);
            });
        });
    }
    // 下边的循环虽然能利用信号量控制最大并发数，但由于是在主线程中执行，会阻塞主线程
    /*
    for (int i = 0; i < 10; i++) {
        // 等待降低信号量，信号量-1 dispatch_semaphore_wait（信号量，等待时间）
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(_concurrentQueue, ^{
            NSLog(@"%@--------开始——任务%d", [NSThread currentThread], i);
            sleep(1);
            NSLog(@"%@--------结束——任务%d", [NSThread currentThread], i);
            // 任务执行完提高信号量，信号量+1  dispatch_semaphore_signal(信号量)
            dispatch_semaphore_signal(semaphore);
        });
    }
     */
    
}

// dispatch_once_t 保证代码块中只执行一次
- (void)GCD_once
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"%s -------------- dispatch_once", __func__);
    });
}

// dispatch_after 保证代码延迟执行，设定一个时间
- (void)GCD_after
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"%s -------------- dispatch_after", __func__);
    });
}


@end
