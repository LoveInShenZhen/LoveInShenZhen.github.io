## 数据库应用开发指南 
下面, 我们会以 **待办事项** 这个案例的开发过程, 来演示采用sz框架开发数据库应用的基本方法和流程.

---

### 项目依赖
* 首先需要安装配置一个 **MySql Server** 实例
* 假设 **MySql Server** 是安装在 **localhost** 上, root 用户, 密码: justdoit
* 创建一个名称为 **todolist** 的数据库, 并指定其字符编码为 **utf8mb4**

```sql
create database todolist default character set utf8mb4 collate utf8mb4_unicode_ci;
```

### 创建工程
* 根据模板创建工程, 工程名称为 **todolist**

```bash
svn export https://github.com/LoveInShenZhen/ProjectTemplates.git/trunk/vertx-web-simple todolist
```

* 删除工程模板里自带的样板实体类文件: **src/main/kotlin/models/User.kt**

### 配置数据库
* 参考 [数据库访问配置](/sz_framework/database/db_config.md)
* 修改数据库配置如下:

```json5
ebean {
  // The name of the default ebean datasource
  defaultDatasource = "default"
  dataSources {
    default {
      ebeanModels = ["models.*"]
      jdbcUrl = "jdbc:mysql://localhost/todolist?useSSL=false&useUnicode=true&characterEncoding=UTF-8"
      username = "root"
      password = "justdoit"
      connectionInitSql = "set names utf8mb4"
    }
  }
}
```

### 创建数据库实体
* 在 **models** 下新建一个package **todolist**
* 创建实体类 **ToDoTask** (文件: src/main/kotlin/models/todolist/ToDoTask.kt)

```kotlin
package models.todolist

import io.ebean.Finder
import io.ebean.Query
import io.ebean.annotation.WhenCreated
import io.ebean.annotation.WhenModified
import jodd.datetime.JDateTime
import models.todolist.query.QToDoTask
import sz.DB
import sz.EntityBean.BaseModel
import java.sql.Timestamp
import javax.persistence.Column
import javax.persistence.Entity
import javax.persistence.Id
import javax.persistence.Version

@Entity
class ToDoTask : BaseModel() {

    @Id
    var id: Long = 0

    @Version
    var version: Long? = null

    @WhenCreated
    var whenCreated: Timestamp? = null

    @WhenModified
    var whenModified: Timestamp? = null

    @Column(columnDefinition = "TEXT COMMENT '任务描述'")
    var task = ""

    @Column(columnDefinition = "INT COMMENT '任务优先级, 1-低, 2-普通, 3-高'")
    var priority = 0        // 对应 enumeration: ToDoPriority

    @Column(columnDefinition = "TINYINT(1) COMMENT '是否已完成'")
    var finished: Boolean = false

    @Column(columnDefinition = "DATETIME COMMENT '任务完成时间'")
    var finish_time: JDateTime? = null

    @Column(columnDefinition = "TINYINT(1) COMMENT '标记删除'")
    var deleted: Boolean = false

    fun markFinished(newStatus:Boolean) {
        if (finished != newStatus) {
            if (newStatus) {
                // 未完成 ==> 完成
                finished = true
                finish_time = JDateTime()
            } else {
                // 完成 ==> 未完成
                finished = false
                finish_time = null
            }
        }
    }

    companion object {

        fun finder(dsName: String = DB.currentDataSource()): Finder<Long, ToDoTask> {
            return finder<Long, ToDoTask>(dsName)
        }

        fun query(dsName: String = DB.currentDataSource()): Query<ToDoTask> {
            return finder(dsName).query()
        }

        fun queryBean(dsName: String = DB.currentDataSource()): QToDoTask {
            return QToDoTask(DB.byDataSource(dsName))
        }
    }
}

```

* 注意 **priority** 字段,(类似一个状态码) 需要定义一个 _描述任务优先级的_ **枚举类**
* 创建 **ToDoPriority** 枚举类, 文件: src/main/kotlin/models/todolist/ToDoTask.kt

```kotlin
package models.todolist

/*
    定义ToDo任务的优先级
 */
enum class ToDoPriority(val code: Int, val desc: String) {
    Low(1, "低优先级"),
    Normal(2, "普通优先级"),
    High(3, "高优先级");

    companion object {

        /**
         * 检查指定的 code 是否是一个有效的 ToDo任务的优先级
         */
        fun verify(code: Int): Boolean {
            return values().map { it.code }.toSet().contains(code)
        }
    }
}
```

#### 数据库实体类要点
* 继承自类: **sz.EntityBean.BaseModel**
* 类名称上面添加标注: **@Entity**, 表示该类为一个数据库的实体类, 他与数据库中的一张表对应
* 类名称的命名风格为: **UpperCamelCase** (即每个单词首字母为大写, 单词之间以大小写分隔, 第一个字母为大写) 按照该风格定义的实体类, 将会自动与数据库中的一张表对应, 表名称风格为 **lowercase_with_underscores** (即全部为小写字母, 单词之间以下划线分隔). 例如: ToDoTask 实体类对应的数据库表为 to_do_task
* 可以在实体类名称上面, 添加标注 **@Table** 来自定义表名称, 例如: 将表名称指定为 **todo_list**

```kotlin
@Entity
@Table(name = "todo_list")
class ToDoTask : BaseModel() {

    @Id
    var id: Long = 0

    ...
}
```

* 注意, 实体类起名的时候, 不要与mysql的关键字冲突, 避免以后在写sql查询的时候, 对这些有关键字冲突的名称进行转义
* 每个实体类我们都会增加如下的字段,(建议, 非强制), 其中 **id** 为表的**主键**. 后面的 **version**, **whenCreated**, **whenModified**, EBean 框架会用来进行乐观锁的逻辑处理

```kotlin
    @Id
    var id: Long = 0

    @Version
    var version: Long? = null

    @WhenCreated
    var whenCreated: Timestamp? = null

    @WhenModified
    var whenModified: Timestamp? = null

```

* 实体类的属性名称命名风格为 **lowercase_with_underscores** (即全部为小写字母, 单词之间以下划线分隔). 按照此风格定义, 则**属性名**与**表字段名**称将会保持一致
* 注意: 实体类的属性名称, 不要与mysql的关键字冲突, 避免以后在写sql查询的时候, 对这些有关键字冲突的名称进行转义
* **boolean** 类型的属性名称不要使用 **is** 开头, 原因请参考[关于阿里为什么boolean类型变量命名为什么禁用is开头名](https://blog.csdn.net/qq_40058629/article/details/86568856)
* 定义实体类属性的时候, 在属性上面添加标注 **@Column**, 采用设置 **columnDefinition** 的方式, 定义属性对应的**表字段**在数据库中的定义, 采用这样方式的目的是, 利用 **COMMENT** 语法, 把字段的注释描述添加到字段定义去. 这样, 在数据库管理工具里, 查看表结构的时候, 就可以直接看到字段的含义, 省掉了数据库表结构的相关文档工作.
* 在每个实体类的[伴生对象](https://www.kotlincn.net/docs/reference/object-declarations.html#%E4%BC%B4%E7%94%9F%E5%AF%B9%E8%B1%A1)里实现3个基础的工具方法, 如下所示,(注: 留意代码里的泛型类型)

```kotlin
    companion object {

        fun finder(dsName: String = DB.currentDataSource()): Finder<Long, ToDoTask> {
            return finder<Long, ToDoTask>(dsName)
        }

        fun query(dsName: String = DB.currentDataSource()): Query<ToDoTask> {
            return finder(dsName).query()
        }

        fun queryBean(dsName: String = DB.currentDataSource()): QToDoTask {
            return QToDoTask(DB.byDataSource(dsName))
        }
    }

```

* 为了便于编码, 下面提供了用于 IntelliJ 的 [Live Templates](https://www.jetbrains.com/help/idea/using-live-templates.html) 代码片段(code snippets)

```
companion object {

    fun finder(dsName: String = DB.currentDataSource()) : Finder<Long, $EntityClass$> {
        return finder<Long, $EntityClass$>(dsName)
    }

    fun query(dsName: String = DB.currentDataSource()): Query<$EntityClass$> {
        return finder(dsName).query()
    }

    fun queryBean(dsName: String = DB.currentDataSource()): Q$EntityClass$ {
        return Q$EntityClass$(DB.byDataSource(dsName))
    }
}
$END$
```

* 关于 Finder 和 QueryBean 的用法, 请参考 EBean 的文档[EBean/Query](https://ebean.io/docs/query/),  建议查看一下 Finder 的源代码了解一下细节
* QueryBean 是gradle里的kapt插件, 根据定义的实体类自动生成的.  
> * 在执行了 gradle build 命令后生成
> * 生成代码路径: build/generated/source/kaptKotlin/main/
> * 对应在 build.gradle.kts 里的配置如下

```groovy
buildscript {
    dependencies {
        classpath("gradle.plugin.io.ebean:ebean-gradle-plugin:11.36.1")
    }
}

plugins {
    // Apply the Kotlin JVM plugin to add support for Kotlin on the JVM.
    id("org.jetbrains.kotlin.jvm").version("1.3.31")

    id("io.ebean").version("11.36.1")
    kotlin("kapt") version "1.3.31"
}

ebean {
    debugLevel = 2
    queryBeans = true
    kotlin = true
    generatorVersion = "11.4"
}
```

### 生成数据库表
* 编译构建, 运行
```bash
gradle run
```
* 浏览器打开 [http://localhost:9000/api/builtin/ebean/CreateTablesSql](http://localhost:9000/api/builtin/ebean/CreateTablesSql) 生成创建数据库表的Sql脚本

```sql
create table to_do_task (
  id                            bigint auto_increment not null,
  task                          TEXT COMMENT '任务描述' not null,
  priority                      INT COMMENT '任务优先级, 1-低, 2-普通, 3-高' not null,
  finished                      tinyint(1) COMMENT '是否已完成' not null,
  finish_time                   DATETIME COMMENT '任务完成时间',
  deleted                       tinyint(1) COMMENT '标记删除' not null,
  version                       bigint not null,
  when_created                  datetime(6) not null,
  when_modified                 datetime(6) not null,
  constraint pk_to_do_task primary key (id)
);



# 修改表的默认字符集和所有列的字符集为 utf8mb4
alter table `to_do_task` convert to character set utf8mb4;
```

* 在 **MySql** 上执行上面的脚本, 创建数据库表

### 实现ToDoList的增删查改的API接口

#### API: 新增一个待办事项
* 在 **com.api.server.controller** 下新增一个名称为 **post** 的package, 我们在这个包里面, 存放用于 **Post Form** 和 **Post Json** 时, 用来转换提交的数据    的 DTO 类
* 在 **com.api.server.controller.post** 包下, 新增DTO类: **PostToDo**
* 注意: 在属性字段的上面, 添加 **@Comment** 标注, 记录字段的注释

```kotlin
package com.api.server.controller.post

import models.todolist.ToDoPriority
import sz.scaffold.annotations.Comment


class PostToDo {

    @Comment("待办事项内容")
    var task = ""

    @Comment("待办事项优先级, 1-低, 2-普通, 3-高")
    var priority = 0

    @Comment("待办事项是否已完成, 新增待办事项的时候, 请设置为false")
    var finished: Boolean = false

    fun SampleData() {
        task = "实现 fun SampleData() { TODO(\"填充样例数据\") } 方法"
        priority = ToDoPriority.High.code
        finished = false
    }
}
```

* 在 **com.api.server.controller** 包下面新增一个控制器类: **ToDoController**
* 在 **ToDoController** 新增一个 **fun newToDo() : ReplyBase** 的控制器方法, 该方法实现新增一个代码事项的业务逻辑.

```kotlin
package com.api.server.controller

import com.api.server.controller.post.PostToDo
import models.todolist.ToDoPriority
import models.todolist.ToDoTask
import sz.interceptors.EbeanTransaction
import sz.scaffold.annotations.Comment
import sz.scaffold.annotations.PostForm
import sz.scaffold.controller.ApiController
import sz.scaffold.controller.reply.ReplyBase
import sz.scaffold.tools.BizLogicException


class ToDoController : ApiController() {

    @Comment("新增一个待办事项")
    @PostForm(PostToDo::class)
    @EbeanTransaction
    fun newToDo(): ReplyBase {
        val reply = ReplyBase()
        val postData = postFormToBean<PostToDo>()

        checkPriority(postData.priority)
        checkTask(postData.task)

        val newToDo = ToDoTask()
        newToDo.task = postData.task
        newToDo.priority = postData.priority
        newToDo.finished = false

        newToDo.save()

        return reply
    }

    private fun checkPriority(priorityCode: Int) {
        if (ToDoPriority.verify(priorityCode).not()) {
            throw BizLogicException("Invalid ToDoPriority code: $priorityCode")
        }
    }

    private fun checkTask(task: String) {
        if (task.isEmpty()) {
            throw BizLogicException("待办事项内容不能为空")
        }
    }
}
```

* 注意: 在方法前面上面, 添加 **@Comment** 标注, 记录该方法的注释说明
* **@PostForm(PostToDo::class)** 标注, 表示该控制器方法, 会处理 **Post Form** 形式的请求, 提交的数据转换的Bean的类型为 **PostToDo**, 这个标注是提供信息用来生成Api接口文档和Api接口测试页面的.
* **@EbeanTransaction** 标注, 表示该控制器方法包装在在一个数据库事务里面. 方法抛出异常的时候, 事务会自动 Rollback
* 为控制器方法添加路由, 在 **cont/route** 文件下, 添加如下一条控制器方法路由. 路由参考: [http 路由配置](/sz_framework/http_route.md)

```
# 待办事项
POST    /api/v1/todolist/newToDo        com.api.server.controller.ToDoController.newToDo
```

* gradle run, 打开测试页面:[http://localhost:9000/api/builtin/doc/apiIndex](http://localhost:9000/api/builtin/doc/apiIndex) 进行测试, 查看数据库里是否新增对应的记录.