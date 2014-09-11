1.FMDB 是什么?
    Objective-C语言对SQLite 底层API的包装. 使的Objective-C可以非常方便的操作SQLite数据库。
2.FMDB 特点
    对基本C库的封装，方便使用。同时还提供了多线程操作数据库带来的读脏数据等问题的方法。
3.为什么使用FMDB?
    iOS中原生的SQLite API在使用上相当不友好，在使用时，非常不便。
    其他：FMDB、PlausibleDatabase、sqlitepersistentobjects
4.如何使用
    4.1 搭建环境
        a.导入以下文件
            - `FMDatabase.h`
            - `FMDatabase.m`
            - `FMDatabaseAdditions.h`
            - `FMDatabaseAdditions.m`
            - `FMDatabasePool.h`
            - `FMDatabasePool.m`
            - `FMDatabaseQueue.h`
            - `FMDatabaseQueue.m`
            - `FMResultSet.m`
        b.导入静态库
            - `libsqlite3.0.dylib`
            OK 编译成功
    4.2 初步印象 [打开 FMDBDatabase.h ]
            ### 使用
            FMDB使用的主要的类

                - `FMDatabase`          -  一个单例的SQLite 数据库.  用来执行SQL语句.
                - `<FMResultSet>`       - `FMDatabase`执行查询SQL语句返回的结果集.
                - `<FMDatabaseQueue>`   - 在多线程中执行多个查询或更新，你应该使用该类。这是线程安全的.

            ### 另外可以看看

            - `<FMDatabasePool>` - `FMDatabase` 的对象池.
            - `<FMStatement>`    - `sqlite_stmt` Objective-C 的包装.
    4.3 开始使用
        4.3.1 目录文件路径处理
            ```NSFileManager * fileManager = [NSFileManager defaultManager];
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
                ```
         4.3.2 使用实例
            //创建数据库
            FMDatabase *db     = [FMDatabase databaseWithPath:dbFullPath];
            //打开数据库
            [db open];
            //创建表
            if (![db tableExists:@"User"]) {
                [db executeStatements:@"create table `User` (`name` text,`age` integer)"];
            }

            //插入数据
            [db executeStatements:@"insert into User (name, age) values ('张三2', 34)"];

            //查询数据
            FMResultSet *rs = [db executeQuery:@"select * from User"];
            while (rs.next) {
                NSLog(@"=====%@",[rs stringForColumn:@"name"]);
            }
            //关闭数据库
            [db close];

            // ********************************************************** //

            //清理数据
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbFullPath];
            [queue inDatabase:^(FMDatabase *db) {
                BOOL res = [db executeUpdate:@"delete from User"];
                if (!res) {
                    NSLog(@"error to delete db data");
                } else {
                    NSLog(@"succ to deleta db data");
                }
            }];
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
                    for (int i = 0; i < 10; i++) {
                        NSLog(@"insert =====");
                        [db executeUpdate:@"insert into User (name, age) values (:a, :b)" withParameterDictionary:@{@"a":@"哈哈222",@"b":@36}];
                    }
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




使用参考
    http://blog.csdn.net/xn4545945/article/details/38055077
    http://blog.csdn.net/kesalin/article/details/8734846
    http://mobile.51cto.com/iphone-321184.htm
    http://www.cnblogs.com/xiaobaizhu/archive/2012/12/10/2812178.html
    http://www.cnblogs.com/xiaobaizhu/archive/2012/12/07/2808170.html