//
//  ViewController.m
//  GCD
//
//  Created by Sun on 2020/1/15.
//  Copyright © 2020 sun. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
/**
 死锁条件总结：
 1.相同队列
 2.队列串行
 3.包含的任务使用sync
 */

// 造成死锁      
// 原因：任务2在等任务3执行完毕，任务3又在等任务2执行完毕
// 1.包含：任务0中包含了任务2(任务1，2，3 算任务0）
// 2.串行：任务0，任务2 都在主队列, 同一队列
// 3.线程：任务0，任务2 都在主线程
// 4.阻塞：任务2用了sync，产生阻塞
- (void)interview1 {
    // 主队列
    // 主线程
    NSLog(@"执行任务1");
    
    // 获取主队列
    dispatch_queue_t queue = dispatch_get_main_queue();
    // 同步执行任务（不开启新线程）- 主线程执行任务
    // 主队列
    // 主线程
    // sync 当前代码执行完毕之后，才可以继续执行之后的代码
    dispatch_sync(queue, ^{
       NSLog(@"执行任务2");
    });
    // 主队列
    // 主线程
    NSLog(@"执行任务3");
}

// 不会造成死锁
// 1.包含：任务0中包含了任务2(任务1，2，3 算任务0）
// 2.串行：任务0，任务2 都在主队列, 同一队列
// 3.线程：任务0，任务2 都在主线程
// 4.阻塞：任务2用了async,不会产生阻塞
- (void)interview2 {
    // 主队列
    // 主线程
    NSLog(@"执行任务1");
    
    // 获取主队列
    dispatch_queue_t queue = dispatch_get_main_queue();
 
    // 主队列
    // 主线程
    // async 可以先继续执行之后的代码
    // async 任务2在主队列中，所以不会开启新线程
    dispatch_async(queue, ^{
       NSLog(@"执行任务2");
    });
    // 主队列
    // 主线程
    NSLog(@"执行任务3");
}

// 会造成死锁
// 原因：任务3在等任务0执行完毕，任务0又在等任务3执行完毕
// 1.包含：任务0中包含了任务3（任务2，3，4 算任务0）
// 2.串行：任务0，任务3 都在串行队列, 同一队列
// 3.线程：任务0，任务3 都在子线程
// 4.阻塞：任务3用了sync,产生阻塞
- (void)interview3 {
    // 主队列
    // 主线程
    NSLog(@"执行任务1");
    
    // 创建串行队列
    dispatch_queue_t queue = dispatch_queue_create("myQueue", DISPATCH_QUEUE_SERIAL);
 
    // 串行队列(自己创建)
    // 子线程A
    // async 可以先继续执行之后的代码
    // async 任务2只要不在主队列中，就会开启新线程
    // 任务0
    dispatch_async(queue, ^{
        NSLog(@"执行任务2");
        // 串行队列(自己创建)
        // 子线程A
        // sync 产生阻塞
        dispatch_sync(queue, ^{
            NSLog(@"执行任务3");
        });
        NSLog(@"执行任务4");
    });
    // 主队列
    // 主线程
    NSLog(@"执行任务5");
}

// 不会造成死锁
// 原因：任务0 任务3 在不同的队列中
// 1.包含：任务0中包含了任务3（任务2，3，4 算任务0）
// 2.队列：任务0在串行队列，任务3在并发队列, 不同一队列
// 3.线程：任务0，任务3 都在子线程A
// 4.阻塞：任务3用了sync,产生阻塞
- (void)interview4 {
    // 主队列
    // 主线程
    NSLog(@"执行任务1");
    
    // 创建串行队列
    dispatch_queue_t queue1 = dispatch_queue_create("myQueue1", DISPATCH_QUEUE_SERIAL);
    // 创建并发队列
    dispatch_queue_t queue2 = dispatch_queue_create("myQueue2", DISPATCH_QUEUE_CONCURRENT);
 
    // 串行队列(自己创建)
    // 子线程A
    dispatch_async(queue1, ^{
        NSLog(@"执行任务2");
        // 并发队列(自己创建)
        // 子线程A
        // sync 产生阻塞
        dispatch_sync(queue2, ^{
            NSLog(@"执行任务3");
        });
        NSLog(@"执行任务4");
    });
    // 主队列
    // 主线程
    NSLog(@"执行任务5");
}

// 不会造成死锁
// 原因：任务0 任务3 在不同的队列中
// 1.包含：任务0中包含了任务3（任务2，3，4 算任务0）
// 2.队列：任务0任务3都在串行队列，但是在不同的队列
// 3.线程：任务0，任务3 都在子线程A
// 4.阻塞：任务3用了sync,产生阻塞
- (void)interview5 {
    // 主队列
    // 主线程
    NSLog(@"执行任务1");
    
    // 创建串行队列
    dispatch_queue_t queue1 = dispatch_queue_create("myQueue1", DISPATCH_QUEUE_SERIAL);
    // 创建串行队列
    dispatch_queue_t queue2 = dispatch_queue_create("myQueue2", DISPATCH_QUEUE_SERIAL);
 
    // 串行队列(自己创建)
    // 子线程A
    dispatch_async(queue1, ^{
        NSLog(@"执行任务2");
        // 并发队列(自己创建)
        // 子线程A
        // sync 产生阻塞
        dispatch_sync(queue2, ^{
            NSLog(@"执行任务3");
        });
        NSLog(@"执行任务4");
    });
    // 主队列
    // 主线程
    NSLog(@"执行任务5");
}

// 不会造成死锁
// 原因：任务0 任务3 在同一队列，但是队列并发
// 1.包含：任务0中包含了任务3（任务2，3，4 算任务0）
// 2.队列：任务0任务3都在同一队列但并发队列
// 3.线程：任务0，任务3 都在子线程A
// 4.阻塞：任务3用了sync,产生阻塞
- (void)interview6 {
    // 主队列
    // 主线程
    NSLog(@"执行任务1");
    
    // 创建并发队列
    dispatch_queue_t queue = dispatch_queue_create("myQueue1", DISPATCH_QUEUE_CONCURRENT);
     
    // 并发队列(自己创建)
    // 子线程A
    dispatch_async(queue, ^{
        NSLog(@"执行任务2");
        // 并发队列(自己创建)
        // 子线程A
        // sync 产生阻塞
        dispatch_sync(queue, ^{
            NSLog(@"执行任务3");
        });
        NSLog(@"执行任务4");
    });
    // 主队列
    // 主线程
    NSLog(@"执行任务5");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


@end
