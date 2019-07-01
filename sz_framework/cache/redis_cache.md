## Redis缓存
---

### 完整配置示例
```json5
redis {
  default {
    // 工作模式: STANDALONE, SENTINEL, CLUSTER, 默认为: STANDALONE 模式
    workingMode = "STANDALONE"
    // 当工作模式为 SENTINEL 和 CLUSTER, 会根据 servers 配置来创建 redisClient
    // eg:
    // SENTINEL 时: servers = ["SENTINEL_1:port", "SENTINEL_2:port", "SENTINEL_3:port"]
    // CLUSTER 时: servers = ["Redis_1:port", "Redis_2:port", "Redis_3:port"]
    servers = []
    // 当工作模式为: SENTINEL 时, 还需要设置 masterName, 这个需要和 sentinel.conf 配置的一致
    masterName = "redis_master"
    host = "127.0.0.1"
    port = 6379
    // this is connection timeout in ms
    timeout = 2000
    database = 0
    //  password = ""

    // 如果其他的 Redis 数据连接配置,没有指定pool配置, 则默认使用与 redis.default.pool 相同的配置
    pool {
      // 基本参数
      // GenericObjectPool 提供了后进先出(LIFO)与先进先出(FIFO)两种行为模式的池。
      // 默认为true，即当池中有空闲可用的对象时，调用borrowObject方法会返回最近（后进）的实例
      lifo = true
      // 当从池中获取资源或者将资源还回池中时 是否使用java.util.concurrent.locks.ReentrantLock.ReentrantLock 的公平锁机制,默认为false
      fairness = false

      // 数量控制参数
      // 链接池中最大连接数,默认为8
      maxTotal = 8
      // 链接池中最大空闲的连接数,默认也为8
      maxIdle = 8
      // 连接池中最少空闲的连接数,默认为0
      minIdle = 0

      // 超时参数
      // 当连接池资源耗尽时，等待时间，超出则抛异常，默认为-1即永不超时
      maxWaitMillis = 5000
      // 当这个值为true的时候，maxWaitMillis参数才能生效。为false的时候，当连接池没资源，则立马抛异常。默认为true
      blockWhenExhausted = true

      // test参数
      // 默认false，create的时候检测是有有效，如果无效则从连接池中移除，并尝试获取继续获取
      testOnCreate = false
      // 默认false，borrow的时候检测是有有效，如果无效则从连接池中移除，并尝试获取继续获取
      testOnBorrow = true
      // 默认false，return的时候检测是有有效，如果无效则从连接池中移除，并尝试获取继续获取
      testOnReturn = true
      // 默认false，在evictor线程里头，当evictionPolicy.evict方法返回false时，而且testWhileIdle为true的时候则检测是否有效，如果无效则移除
      testWhileIdle = true

      // 驱逐检测参数
      // 空闲链接检测线程检测的周期，毫秒数。如果为负值，表示不运行检测线程。默认为-1
      timeBetweenEvictionRunsMillis = 30000
      // 在每次空闲连接回收器线程(如果有)运行时检查的连接数量，默认为3, 取-1时, 表示检查当前所有的idleObjects
      numTestsPerEvictionRun = -1
      // 连接空闲的最小时间，达到此值后空闲连接将可能会被移除
      minEvictableIdleTimeMillis = 30000
      // 连接空闲的最小时间，达到此值后空闲链接将会被移除，且保留minIdle个空闲连接数。默认为-1
      softMinEvictableIdleTimeMillis = 1800000
      // evict策略的类名，默认为org.apache.commons.pool2.impl.DefaultEvictionPolicy
      evictionPolicyClassName = "org.apache.commons.pool2.impl.DefaultEvictionPolicy"

      // 额外参数
      operationTimeout = 2000
    }

  }
}
```

### 精简配置
* Redis配置的默认参数, 可以应付绝大多数的情况, 所以我们一般可以使用如下的精简配置
* 可以有多组Redis配置, sz框架里, 默认的一组Redis配置的名称为: **default**

#### 精简配置示例
* 连接 Redis 单机, 假设主机名为: redis_server, 默认端口: 6379, 默认连接 0 号数据库, Redis 没有设置密码

```json5
redis {
  default {
    workingMode = "STANDALONE"
    host = "127.0.0.1"
  }
}
```

### 代码示例
```kotlin
package com.api.server.controller

import com.api.server.controller.reply.HelloReply
import sz.scaffold.annotations.Comment
import sz.scaffold.cache.redis.RedisCacheApi
import sz.scaffold.controller.ApiController
import sz.scaffold.controller.reply.ReplyBase


class RedisSample : ApiController() {

    @Comment("测试缓存,协程方式接口 [set]")
    suspend fun setKeyAwait(@Comment("缓存键") key: String,
                            @Comment("缓存值") value: String,
                            @Comment("缓存超时时间") timeOut: Long): ReplyBase {
        val reply = ReplyBase()

        RedisCacheApi.default.setAwait(key, value, timeOut)

        return reply
    }

    @Comment("测试缓存,协程方式接口 [get]")
    suspend fun getValueAwait(@Comment("缓存键") key: String): HelloReply {
        val reply = HelloReply()
        reply.msg = RedisCacheApi.default.getOrNullAwait(key) ?: "不存在"
        return reply
    }

    @Comment("测试缓存,协程方式接口 [exists]")
    suspend fun existsAwait(@Comment("缓存键") key: String): HelloReply {
        val reply = HelloReply()
        reply.msg = if (RedisCacheApi.default.existsAwait(key)) "存在" else "不存在"
        return reply
    }

    @Comment("测试缓存,协程方式接口 [del]")
    suspend fun delAwait(@Comment("缓存键") key: String): ReplyBase {
        val reply = ReplyBase()
        RedisCacheApi.default.delAwait(key)
        return reply
    }
}

```
