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
    


//    [self co_Launch];
//    [self co_Launch1];
//    [self co_Launch2];
    
//    [self testForChannelWithNoCache];
    
//    [self testForAwaitPromise];
    
//    [self testForAwaitChan];
    
//      [self testForRandomGenerator];
    
      [self testForActor];
  
    
}


-(void)co_Launch
{
    
    
    co_launch(^{
       
        NSLog(@"----launch1");
        
    });
    
    co_launch_now(^{
        NSLog(@"----launch2");
    });
    
    co_launch(^{
        
        sleep(5);
        NSLog(@"----launch3");
        
        
    });
    
    NSLog(@"third step");
    
}


-(void)co_Launch1
{
    /* 新建一个 coroutine */
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


-(void)co_Launch2
{
    co_launch(^{
        
        NSNumber * number = await([self fetchIn2]);
        NSLog(@"%@",number);
        
    });
    
}




-(void)testForChannelWithNoCache
{
      COChan * chan = [COChan chan];
    
      /* 创建 coroutine1 */
      co_launch(^{
          NSLog(@"deal things before coroutine1");
          NSString *  value = [chan receive]; ///< 挂起当前协程直到接受到value
          NSLog(@"get value from chanel:  %@",value);
          NSLog(@"deal things after coroutine1");
      });
    
     /* 创建 coroutine2 */
    co_launch(^{
        NSLog(@"deal things before coroutine2");
        [chan send:@"传递一个value"];
        NSLog(@"deal things after coroutine2");
    });
    
    NSLog(@" ---testForChannelWithNoCache---");
    
}


#pragma mark Await

/// COPromise
- (COPromise<id> *)co_fetchSomethingAsynchronous {
    
    return [COPromise promise:^(COPromiseFullfill  _Nonnull fullfill, COPromiseReject  _Nonnull reject) {
        NSError *error = nil;
        int number = arc4random() % 2;
        if (number) {
            NSLog(@"result is %d,spend some time to deal it..",number);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                fullfill(@(number));
            });
        } else {
            NSLog(@"result is %d,throw out an error.",number);
            error = [NSError errorWithDomain:@"error" code:10000 userInfo:nil];
            reject(error);
        }
    } onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

- (void)testForAwaitPromise {
    co_launch(^{
        id ret = await([self co_fetchSomethingAsynchronous]);
        NSError *error = co_getError();
        
        if (error) {
            NSLog(@"get an error in testForAwait, error: %@",error);
        } else {
            NSLog(@"get the result in testForAwait,value:%d",[ret intValue]);
        }
    });
}


/// COChan
- (COChan<id> *)co_fetchSomething {
    COChan *chan = [COChan chan];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        int number = arc4random() % 2;
        if (number) {
            NSLog(@"result is %d",number);
            //??? 如果使用send？
            [chan send_nonblock:@(number)];
        } else {
            NSLog(@"result is %d,throw out an error.",number);
            error = [NSError errorWithDomain:@"error" code:10000 userInfo:nil];
            [chan send_nonblock:error];
        }
    });
    return chan;
}

- (COChan<id> *)co_fetchSomething1 {
    COChan *chan = [COChan chan];
    co_launch(^{
        NSError *error = nil;
        int number = arc4random() % 2;
        if (number) {
            NSLog(@"result is %d",number);
            //??? 如果使用send？
            [chan send:@(number)];
        } else {
            NSLog(@"result is %d,throw out an error.",number);
            error = [NSError errorWithDomain:@"error" code:10000 userInfo:nil];
            [chan send:error];
        }
    });
    return chan;
}

- (void)testForAwaitChan {
    co_launch(^{
        id ret = await([self co_fetchSomething1]);
        if ([ret isKindOfClass:[NSError class]]) {
            NSLog(@"get an error in testForAwaitChan, error: %@",ret);
        } else {
            NSLog(@"get the result in testForAwaitChan,value:%d",[ret intValue]);
        }
    });
}


#pragma mark Generator

- (void)testForRandomGenerator {
    COCoroutine *generator = co_sequence(^{
        NSArray *array = @[@"🍎",@"🐶",@"🤖️",@"✈️"];
        while(co_isActive()){
            int index = arc4random() % array.count;
            NSString *result = [array objectAtIndex:index];
            NSLog(@"index %d is a %@",index,result);
            yield_val(result);
        }
    });
    
    [generator setFinishedBlock:^{
        NSLog(@"generator is killed!");
    }];
    
    co_launch(^{
//        for(int i = 0; i < 10; i++){
            NSString *whatIsThis = [generator next];
            NSLog(@"look, what I get in the box! %@",whatIsThis);
//        }
        [generator cancel];
    });
}


#pragma mark Actor

- (void)testForActor {
    COActor *countActor = co_actor(^(COActorChan * _Nonnull channel) {
        //定义actor的状态变量
        int count = 0;
        for (COActorMessage *message in channel) {
            //处理消息
            if ([[message stringType] isEqualToString:@"inc"]) {
                count++;
                NSLog(@"the count is %d now.", count);
            }
            else if ([[message stringType] isEqualToString:@"get"]) {
                message.complete(@(count));
                NSLog(@"get the count %d", count);
            }
        }
    });
    
    //     给 actor 发送消息
   
    [countActor sendMessage:@"inc"];
    [countActor sendMessage:@"inc"];
   
    
    id value = [countActor sendMessage:@"get"].value;
    NSLog(@"the Actor count now is %d",[value intValue]);
   
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


-(COPromise *)fetchIn2
{
    COPromise * promise = [COPromise promise];
    int count = 100000;
    
    for (int i = 0; i < count; i++)
    {
        if (i == count -1 )
        {
            [promise fulfill:@(i)];
        }
    }
    
    return promise;
    
}

@end
