## 数访问配置 

### 配置文件
* conf/application.conf

### 配置选项

```json5
ebean {
  //The name of the default ebean datasource
  defaultDatasource = "default"
  ebeanModels = ["models.*"]

  // 数据库密码是否要求加密, 默认为 false, 密码为明文
  encryptPasswd = false
  // 当 encryptPasswd = true 的时候, 数据库的密码将使用 Rsa 加密
  // 所以需要指定用于解密的私钥文件
  privateKeyFile = "conf/privateKey.pem"

  dataSources {
    default {
      jdbcUrl = "jdbc:mysql://localhost/api_test?useSSL=false&useUnicode=true&characterEncoding=UTF-8"
      username = "root"
      password = "change_your_password"
      // Set the SQL string that will be executed on all new connections when they are
      // created, before they are added to the pool.  If this query fails, it will be
      // treated as a failed connection attempt.
      connectionInitSql = "set names utf8mb4"
      // Set the default auto-commit behavior of connections in the pool.
      // autoCommit = true    

      // Set the SQL query to be executed to test the validity of connections. Using
      // the JDBC4 Connection.isValid() method to test connection validity can
      // be more efficient on some databases and is recommended.
      connectionTestQuery = null

      // Set the maximum number of milliseconds that a client will wait for a connection from the pool. If this
      // time is exceeded without a connection becoming available, a SQLException will be thrown from
      // javax.sql.DataSource#getConnection().
      connectionTimeout = 30000

      // This property controls the maximum amount of time (in milliseconds) that a connection is allowed to sit
      // idle in the pool. Whether a connection is retired as idle or not is subject to a maximum variation of +30
      // seconds, and average variation of +15 seconds. A connection will never be retired as idle before this timeout.
      // A value of 0 means that idle connections are never removed from the pool.
      idleTimeout = 600000

      // Configure whether internal pool queries, principally aliveness checks, will be isolated in their own transaction
      // via Connection#rollback().  Defaults to false.
      isolateInternalQueries = false

      // This property controls the amount of time that a connection can be out of the pool before a message is
      // logged indicating a possible connection leak. A value of 0 means leak detection is disabled.
      leakDetectionThreshold = 0

      // This property controls the maximum lifetime (in milliseconds) of a connection in the pool. When a connection reaches this
      // timeout, even if recently used, it will be retired from the pool. An in-use connection will never be
      // retired, only when it is idle will it be removed.
      maxLifetime = 1800000

      // The property controls the maximum size that the pool is allowed to reach, including both idle and in-use
      // connections. Basically this value will determine the maximum number of actual connections to the database
      // backend.
      maximumPoolSize = 10

      // The property controls the minimum number of idle connections that HikariCP tries to maintain in the pool,
      // including both idle and in-use connections. If the idle connections dip below this value, HikariCP will
      // make a best effort to restore them quickly and efficiently.
      minimumIdle = 10

      // Sets the maximum number of milliseconds that the pool will wait for a connection to be validated as
      // alive.
      validationTimeout = 5000
    }
  }
}
```

### 常用基本配置
* 修改 **jdbcUrl** 中的MySql数据库服务器名称(**_MySqlServerName_**)或IP地址, 数据库名称(**_DatabaseName_**)
* 修改访问数据的用户名 **username**
* 修改访问数据的密码 **password**

```json5
ebean {
  // The name of the default ebean datasource
  defaultDatasource = "default"
  ebeanModels = ["models.*"]

  dataSources {
    default {
      jdbcUrl = "jdbc:mysql://MySqlIpOrName/DatabaseName?useSSL=false&useUnicode=true&characterEncoding=UTF-8"
      username = "root"
      password = "change_your_password"
    }
  }
}
```