//
//  ViewController.m
//  coobjecDemo
//
//  Created by mac on 2019/7/13.
//  Copyright © 2019 mac. All rights reserved.
//

#import "ViewController.h"
#import "coobjc.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    /*
    NSLog(@"1: %@",[NSThread currentThread]);
    
    ///< async + main : 不会创建新线程，串行执行。
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"2: %@",[NSThread currentThread]);
        
    });
    
    
    ///< 异步 + 并发队列 : 开辟新线程
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
    
        NSLog(@"3: %@",[NSThread currentThread]);
        ///< 返回主线程
        dispatch_async(dispatch_get_main_queue(), ^{

            NSLog(@"4: %@",[NSThread currentThread]);

        });
    });
    **/
    
    [self co_lunch];
    NSLog(@"next step");
    
    
    
}



-(void)co_lunch
{
    
    co_launch(^{
        NSLog(@"start");
        
        NSString * title1  =  await([self fetchIn]);
        NSLog(@"title1: %@",title1);
        
        NSString * title2  =  await([self fetchIn1]);
        NSLog(@"title2: %@",title2);
        
        NSLog(@"thread: %@",[NSThread currentThread]);
        
        NSLog(@"end");
        
    });
}

-(COPromise *)fetchIn
{
    COPromise *promise = [COPromise promise];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(2);
        [promise fulfill:@"12345"];
    });
    return promise;
}

-(COPromise *)fetchIn1
{
    COPromise *promise = [COPromise promise];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(5);
        [promise fulfill:@"123456"];
    });
    return promise;
}

@end
