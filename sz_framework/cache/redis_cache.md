## Redis缓存

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
    // 默认连接本地的 redis server
    host = "localhost"
    port = 6379
    // this is connection timeout in ms
    timeout = 2000
    database = 0
    netClientOptions {
      reusePort = true,
      tcpNoDelay = true,
      tcpKeepAlive = true,
      tcpFastOpen = true,
      tcpQuickAck = true,
      connectTimeout = 2000
    }
    ssl = false
    password = ""

    // 如果其他的 Redis 数据连接配置,没有指定pool配置, 则默认使用与 redis.default.pool 相同的配置
    pool {
      // 基本参数

      // 数量控制参数
      // 链接池中最大连接数,默认为8
      maxTotal = 8
      // 链接池中最大空闲的连接数,默认也为8
      maxIdle = 8
      // 连接池中最少空闲的连接数,默认为2
      minIdle = 2

      // 驱逐检测的间隔时间, 默认10分钟
      timeBetweenEvictionRunsSeconds = 600

      // 超时参数
      // 从对象池里借对象时的超时时间, 拍脑袋决定默认值 5000 ms
      // 设置为 0 或者负数的时候, 表示不进行超时控制
      borrowTimeoutMs = 5000

      // 额外参数
      operationTimeout = -1
    }

  }
}
```

### 精简配置
* Redis配置的默认参数, 可以应付绝大多数的情况, 所以我们一般可以使用如下的精简配置
* 可以有多组Redis配置, sz框架里, 默认的一组Redis配置的 _名称_ 为: **default**

#### 精简配置示例
* 连接 Redis 单机, 假设主机名为: localhost, 默认端口: 6379, 默认连接 0 号数据库, Redis 没有设置密码

```json5
redis {
  default {
    workingMode = "STANDALONE"
    host = "localhost"
    port = 6379
    database = 0
    password = ""
  }
}
```

### 代码示例
```kotlin
package com.api.server.controllers

import com.api.server.controllers.reply.HelloReply
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

### 示例完整代码
* [Redis Sample 代码](https://github.com/LoveInShenZhen/ProjectTemplates/tree/master/samples/redis_test)

```bash
svn export https://github.com/LoveInShenZhen/ProjectTemplates.git/trunk/samples/redis_test redis_test
```
