## Redis缓存

### 完整配置示例
```json5
app {
  httpServer {
    port = 9000
    host = "0.0.0.0"
  }

  cache {
    // 默认配置一个名称为 local_redis 的redis 缓存, 默认连接本机上的 redis server
    configs {
      // 配置项的 key 为缓存名称, 缓存名称不能重复
      local_redis_cache {
        // 缓存实现对应的工厂类,
        factory = "sz.scaffold.redis.cache.RedisCacheFactory"
        // 缓存参数, 根据实现类的不同, 参数也不同
        // redis 缓存参数配置请参考:
        // 参考1: https://vertx.io/docs/vertx-redis-client/kotlin/#_connecting_to_redis
        // 参考2: https://vertx.io/docs/apidocs/io/vertx/redis/client/RedisOptions.html
        // 参考3: package io.vertx.redis.client 下的 RedisOptionsConverter.java
        options {
          // endpoint 格式说明: redis://[:password@]host[:port][/db-number]
          endpoints = ["redis://localhost:6379/0"]
        }
      }
    }
  }
}
```

### 代码示例
```kotlin
package com.api.server.controllers.sample

import com.api.server.controllers.sample.reply.MessageReply
import sz.scaffold.annotations.Comment
import sz.scaffold.cache.CacheManager
import sz.scaffold.controller.ApiController
import sz.scaffold.controller.reply.ReplyBase

//
// Created by kk on 2019/11/20.
//

@Comment("Redis 缓存测试")
class RedisSample : ApiController() {

    // application.conf 中, app.cache.configs 下应该有对应名称为 "local_redis_cache" 的缓存配置
    private val cache by lazy { CacheManager.asyncCache(cacheName = "local_redis_cache") }

    @Comment("Redis缓存 set 测试")
    suspend fun setCache(@Comment("缓存键") key: String,
                         @Comment("缓存值") value: String,
                         @Comment("缓存超时时间") timeOut: Long): ReplyBase {
        val reply = ReplyBase()
        cache.setAwait(key, value, timeOut)
        return reply
    }

    @Comment("Redis缓存 get 测试")
    suspend fun getCache(@Comment("缓存键") key: String): MessageReply {
        val reply = MessageReply()
        reply.msg = cache.getOrElseAwait(key) {
            "缓存不存在"
        }
        return reply
    }

    @Comment("Redis缓存 del 测试")
    suspend fun delCache(@Comment("缓存键") key: String): ReplyBase {
        val reply = ReplyBase()
        cache.delAwait(key)
        return reply
    }

    @Comment("Redis缓存, 测试指定key的缓存项是否存在")
    suspend fun existsCache(@Comment("缓存键") key: String): MessageReply {
        val reply = MessageReply()
        reply.msg = if (cache.existsAwait(key)) "存在" else "不存在"
        return reply
    }
}
```

### 示例完整代码
* [Redis Sample 代码](https://github.com/LoveInShenZhen/ProjectTemplates/tree/master/samples/redis_test)

```bash
svn export https://github.com/LoveInShenZhen/ProjectTemplates.git/trunk/samples/redis_test redis_test
```
