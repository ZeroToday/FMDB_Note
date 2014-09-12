//
//  AppDelegate.m
//  FMDB_Note
//
//  Created by yutao on 14-9-9.
//  Copyright (c) 2014年 sina. All rights reserved.
//

#import "AppDelegate.h"
#import "FMDB.h"

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    
    
    //数据库路径
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    //bundlePath
    NSArray * newsDBName = [@"NewsDataBase.sqlite" componentsSeparatedByString:@"."];
    NSString * bundlePath = [[NSBundle mainBundle] pathForResource:[newsDBName objectAtIndex:0] ofType:[newsDBName objectAtIndex:1]];
    //userDocPath
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    //  /NewsDataBase/  目录
    NSString *dbDirPath = [docsPath stringByAppendingPathComponent:@"NewsDataBase"];
    
    //创建目录
    [fileManager createDirectoryAtPath:dbDirPath withIntermediateDirectories:NO attributes:nil error:nil];
    NSString *dbFullPath   = [dbDirPath stringByAppendingPathComponent:@"NewsDataBase.sqlite"];
    
    if (![fileManager fileExistsAtPath:dbFullPath])
    {
        NSError *error;
        //将数据库文件 从bundle 拷贝到 userDocPath 中
        if (![fileManager copyItemAtPath:bundlePath toPath:dbFullPath error:&error])
        {
            NSLog(@"copy 失败");
        }
    }
    
    
    //创建数据库
    FMDatabase *db     = [FMDatabase databaseWithPath:dbFullPath];
    
    [db open];//The FMDatabase <FMDatabase: 0x7ff483e47570> is not open. 需要手动open
    /**
    //创建表
    if (![db tableExists:@"User"]) {
        [db executeStatements:@"create table `User` (`name` text,`age` integer)"];
    }
    
    
    //插入数据 方式1 直接执行SQL 语句 可以执行任何SQL 语句
    [db executeStatements:@"insert into User (name, age) values ('张三2', 34)"];
    
    //插入数据 方式2
    [db executeUpdate:@"insert into User (name, age) values (?, ?)",@"李四",@44];
    [db executeQuery:@"select * from User"];
    
    
    [db executeUpdate:@"insert into User (name, age) values (?, ?)" withArgumentsInArray:@[@"王五",@45]];
    FMResultSet *rsss =  [db executeQuery:@"select * from User where age > ?" withArgumentsInArray:@[@40]];
    
    
    [db executeUpdateWithFormat:@"insert into User (name, age) values (%s, %d)","李四222",55];
    [db executeQueryWithFormat:@"select * from User where age > %d",40];
    
    
    [db executeUpdate:@"insert into User (name, age) values (:a, :b)" withParameterDictionary:@{@"a":@"哈哈",@"b":@56}];
    FMResultSet *rsss22 = [db executeQuery:@"select * from User where age > :age" withParameterDictionary:@{@"age":@444}];
    
    //查询数据
    FMResultSet *rs = [db executeQuery:@"select * from User"];
    while (rs.next) {
        NSDictionary *d = [rs resultDictionary];
        NSLog(@"=====%@",[rs stringForColumn:@"name"]);
    }
    [rs close];
    [db close];
   
    **/
    
    //以上都是同步操作  在实际项目中考虑到项目的体验 这些后台操作一般都是在子线程操作的 那么就涉及到咯多线程读写的问题 先看一个例子
    
    //多线程读写  举例
    /**
    NSMutableArray * array = [NSMutableArray arrayWithCapacity:0];
    //线程读
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSString *name in array) {
            NSLog(@"====11111=Name =%@ ",name);
        }
    });
    
    //线程写
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0; i < 1000; i++) {
            [array addObject:[NSString stringWithFormat:@"张三 %d",i]];
        }
    });
    
    //线程读
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSString *name in array) {
            NSLog(@"====22222=Name =%@ ",name);
        }
    });
    
    **/
    //上述操作明显会crash  *** Terminating app due to uncaught exception 'NSGenericException', reason: '*** Collection <__NSArrayM: 0x7ff7b9c9f830> was mutated while being enumerated.'
    
    
    //下面我们看下多线程操作数据库 会出现啥问题
    //清理数据
    /**
    BOOL res = [db executeUpdate:@"delete from User"];
    if (!res) {
        NSLog(@"error to delete db data");
    } else {
        NSLog(@"succ to deleta db data");
    }
    //线程写
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [db beginTransaction];
        for (int i = 0; i < 1000; i++) {
            NSLog(@"write =====");
            [db executeUpdate:@"insert into User (name, age) values (:a, :b)" withParameterDictionary:@{@"a":@"1111哈哈111",@"b":@36}];
        }
        [db commit];
    });
    
    //线程读
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMResultSet *rs  = [db executeQuery:@"select * from User"];
         NSLog(@"read =====");
        while (rs.next) {
            
            NSLog(@"====rsDic =%@",[rs resultDictionary][@"name"]);
        }
    });
    
    //线程写
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [db beginTransaction];
        for (int i = 0; i < 1000; i++) {
            NSLog(@"write =====");
            [db executeUpdate:@"insert into User (name, age) values (:a, :b)" withParameterDictionary:@{@"a":@"222哈哈222",@"b":@36}];
        }
        [db commit];
    });
    
    //线程读
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMResultSet *rs  = [db executeQuery:@"select * from User"];
        NSLog(@"read =====");
        while (rs.next) {
            NSLog(@"====rsDic =%@",[rs resultDictionary][@"name"]);
        }
    });
    **/
    
    //啊？？？？ Crash了。 打开控制台 提示 The FMDatabase <FMDatabase: 0x7fab88e0bea0> is currently in use. 明显是使用多线程操作同一个数据库出现的crash
    
    
    //怎么办 怎么办  对了好像有个叫串行队列的东西可以解决这个问题吧 突然想到刚刚开始的时候好像看到FMDB 提供了一个啥东西 也可以很好的解决  噢 FMDatabaseQueue  对了就是他 太幸福咯 哈哈哈  赶紧试试    // ****************************FMDatabaseQueue使用****************************** //
    //清理数据
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbFullPath];
     //db 不需要手动 open
    [queue inDatabase:^(FMDatabase *db) {
        BOOL res = [db executeUpdate:@"delete from User"];
        if (!res) {
            NSLog(@"error to delete db data");
        } else {
            NSLog(@"succ to deleta db data");
        }
    }];
    
    //线程写
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [queue inDatabase:^(FMDatabase *db) {
            [db beginTransaction];
            for (int i = 0; i < 1000; i++) {
                NSLog(@"insert =====");
                [db executeUpdate:@"insert into User (name, age) values (:a, :b)" withParameterDictionary:@{@"a":@"哈哈222",@"b":@36}];
            }
            [db commit];
            
        }];
    });
    
    //线程读
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [queue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs  = [db executeQuery:@"select * from User"];
            while (rs.next) {
                NSLog(@"====rsDic =%@",[rs resultDictionary][@"name"]);
            }
            
        }];
    });
    //线程写
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [queue inDatabase:^(FMDatabase *db) {
            [db beginTransaction];
            for (int i = 0; i < 1000; i++) {
                NSLog(@"insert =====");
                [db executeUpdate:@"insert into User (name, age) values (:a, :b)" withParameterDictionary:@{@"a":@"哈哈222",@"b":@36}];
            }
            [db commit];
        }];
    });
    
    //事物
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"insert into User (name, age) values (:a, :b)" withParameterDictionary:@{@"a":@"***哈哈222",@"b":@36}];
        
        BOOL res = [db executeUpdate:@"insert ino User (name, age) values (:a, :b)" withParameterDictionary:@{@"a":@"**####哈哈222",@"b":@36}];
        if (!res) {
            *rollback = YES;
            return ;
        }
    }];
    
    //线程读取
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [queue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs  = [db executeQuery:@"select * from User"];
            while (rs.next) {
                NSLog(@"====rsDic =%@",[rs resultDictionary][@"name"]);
            }
            
        }];
    });

    //哈哈 解决咯  为什么？  反思：FMDatabaseQueue 是一个串行队列 需有提交到queue 中的任务都会按照提交顺序来执行 觉得不会存在多个线程同时操作同一个db 的情况
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
