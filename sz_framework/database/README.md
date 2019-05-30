* **sz** 框架提供了对关系型数据库的访问支持 (**JDBC方式**)
* 推荐使用 **MySql 5.7** 版本, 这也是因为绝大部分云服务商基本上都会提供对应的云MySql服务, 并且sz框架内置了MySql数据库schema的维护工具命令
* ORM 框架使用的是 [**EBean**](https://ebean.io/)
* 连接池使用的是 [**HikariCP**](https://brettwooldridge.github.io/HikariCP/)