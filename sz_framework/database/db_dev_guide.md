## 数据库应用开发指南 
下面, 我们会以 **待办事项** 这个案例的开发过程, 来演示采用sz框架开发数据库应用的基本方法和流程.

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

* 删除工程模板里自带的样板实体类文件: **src/main/kotlin/models/sample/User.kt**

### 配置数据库
* 参考 [数据库访问配置](sz_framework/database/db_config.md)
* 根据你本地的MySql环境,修改数据库配置:

```json5
ebean {
  //The name of the default ebean datasource
  defaultDatasource = "default"
  ebeanModels = ["models.*"]

  dataSources {
    default {
      jdbcUrl = "jdbc:mysql://localhost/todolist?useSSL=false&useUnicode=true&characterEncoding=UTF-8"
      username = "root"
      password = "justdoit"
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
import io.ebean.Model
import io.ebean.Query
import io.ebean.annotation.WhenCreated
import io.ebean.annotation.WhenModified
import jodd.datetime.JDateTime
import models.todolist.query.QToDoTask
import sz.ebean.DB
import java.sql.Timestamp
import javax.persistence.Column
import javax.persistence.Entity
import javax.persistence.Id
import javax.persistence.Version

@Suppress("MemberVisibilityCanBePrivate", "PropertyName")
@Entity
class ToDoTask(dataSource: String = "") : Model(dataSource) {

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

    fun markFinished(newStatus: Boolean) {
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
            return DB.finder(dsName)
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
* 创建 **ToDoPriority** 枚举类, 文件: src/main/kotlin/models/todolist/ToDoPriority.kt

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
* 数据库实体类, 默认约定放在 **models** 或其子package下. 因为 EBean 框架需要进行注册实体类的操作, sz 框架在根据配置文件进行EBean初始化的时候, 默认是扫描 __models.\*__ 包(及其子包) 下的数据库实体类. 对应在 application.conf 里的配置如下, 如果实体类需要放在其他自定义的包下, 请相应修配置, 添加需要扫描的包路径, __(注: package_name.* 表示递归扫描包 package_name 及其子包下的实体类)__ 例如:

```json5
ebean {
  ebeanModels = ["models.*", "your.db.entity.*"]
}
```

* 继承自类: **io.ebean.Model**
* 构造函数, 指定实体对应的 **dataSource** 数据源, 参见: [数据库访问配置](/sz_framework/database/db_config.md), 并将此参数传递给基类 **Model** 的构造函数
* 类名称上面添加标注: **@Entity**, 表示该类为一个数据库的实体类, 他与数据库中的一张表对应
* 类名称的命名风格为: **UpperCamelCase** (即每个单词首字母为大写, 单词之间以大小写分隔, 第一个字母为大写) 按照该风格定义的实体类, 将会自动与数据库中的一张表对应, 表名称风格为 **lowercase_with_underscores** (即全部为小写字母, 单词之间以下划线分隔). 例如: ToDoTask 实体类对应的数据库表为 to_do_task
* 可以在实体类名称上面, 添加标注 **@Table** 来自定义表名称, 例如: 将表名称指定为 **todo_task**

```kotlin
@Entity
@Table(name = "todo_task")
class ToDoTask(dataSource: String = "") : Model(dataSource) {

    @Id
    var id: Long = 0

    ...
}
```

* 注意, 实体类和属性字段起名的时候, 不要与mysql的关键字冲突, 避免以后在写sql查询的时候, 对这些有关键字冲突的名称进行转义
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
            return DB.finder(dsName)
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

```kotlin
import io.ebean.Finder
import io.ebean.Model
import io.ebean.Query
import io.ebean.annotation.WhenCreated
import io.ebean.annotation.WhenModified
import jodd.datetime.JDateTime
import sz.ebean.DB
import java.sql.Timestamp
import javax.persistence.Column
import javax.persistence.Entity
import javax.persistence.Id
import javax.persistence.Version

@Suppress("MemberVisibilityCanBePrivate")
@Entity
class $EntityClass$ : Model() {

    @Id
    var id: Long? = null

    @Version
    var version: Long? = null

    @WhenCreated
    var whenCreated: Timestamp? = null

    @WhenModified
    var whenModified: Timestamp? = null

    // todo: 1. add db field here
    // todo: 2. gradle kaptKotlin  #run this command to generate query bean source code
    // todo: 3. fix import issue of query bean
    $END$

    companion object {
    
        fun finder(dsName: String = DB.currentDataSource()) : Finder<Long, $EntityClass$> {
            return DB.finder(dsName)
        }
    
        fun query(dsName: String = DB.currentDataSource()): Query<$EntityClass$> {
            return finder(dsName).query()
        }
    
        fun queryBean(dsName: String = DB.currentDataSource()): Q$EntityClass$ {
            return Q$EntityClass$(DB.byDataSource(dsName))
        }
    }
}
```

* 关于 Finder 和 QueryBean 的用法, 请参考 EBean 的文档[EBean/Query](https://ebean.io/docs/query/),  建议查看一下 Finder 的源代码了解一下细节
* QueryBean 是gradle里的kapt插件, 根据定义的实体类自动生成的.  
    * 在执行了 gradle kaptKotlin 命令后生成
    * 生成代码路径: build/generated/source/kaptKotlin/main/
    * 定义完数据库实体类后, 首次编译, 需要手工执行 gradle kaptKotlin 生成 QueryBean 代码, 然后就可以在实体类补全对应 QueryBean 的 import. 以后每次构建的时候, gradle build 任务会自动调用 gradle kaptKotlin
    * 对应在 build.gradle.kts 里的配置如下
* 我们也可以完全不使用 QueryBean 这一个功能. 只需要在 build.gradle.kts 去掉如下的 2 句指令:
    * kotlin("kapt").version("1.3.50")
    * kapt("io.ebean:kotlin-querybean-generator:12.1.1")

```groovy
plugins {
    // Apply the Kotlin JVM plugin to add support for Kotlin on the JVM.
    id("org.jetbrains.kotlin.jvm").version("1.3.50")

    // Apply the application plugin to add support for building a CLI application.
    application

    id("io.ebean").version("12.1.1")
    kotlin("kapt").version("1.3.50")
}

dependencies {
    // Use the Kotlin JDK 8 standard library.
    implementation(kotlin("stdlib-jdk8"))
    implementation(kotlin("reflect"))
    
    implementation(files("conf"))
    implementation("com.github.kklongming:sz-scaffold:3.0.0-latest")
    implementation("com.github.kklongming:sz-ebean:3.0.0-latest")
    implementation("com.github.kklongming:sz-api-doc:3.0.0-latest")

    // 注释了下面这句, 则不会产生 gradle kaptKotlin 任务, 不会生成实体类对应的QueryBean
    kapt("io.ebean:kotlin-querybean-generator:12.1.1")

    // Use the Kotlin test library.
    testImplementation("org.jetbrains.kotlin:kotlin-test")

    // Use the Kotlin JUnit integration.
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit")

    configurations.all {
        this.exclude(group = "org.slf4j", module = "slf4j-log4j12")
    }
}

ebean {
    debugLevel = 2
    queryBeans = true
    kotlin = true
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

```

* 在 **MySql** 上执行上面的脚本, 创建数据库表

### 实现ToDoList的增删查改的API接口

#### API: 新增一个待办事项
* 在 **com.api.server.controllers.todolist** 下新增一个名称为 **post** 的package, 我们在这个包里面, 存放用于 **Post Form** 和 **Post Json** 时, 用来转换提交的数据的 DTO 类
* 在 **com.api.server.controllers.todolist.post** 包下, 新增DTO类: **PostToDo**
* 注意: 在属性字段的上面, 添加 **@Comment** 标注, 记录字段的注释

```kotlin
package com.api.server.controllers.todolist.post

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

* 在 **com.api.server.controllers.todolist** 包下面新增一个控制器类: **ToDoController**
* 在 **ToDoController** 新增一个 **fun newToDo() : ReplyBase** 的控制器方法, 该方法实现新增一个代码事项的业务逻辑.

```kotlin
package com.api.server.controllers.todolist

import com.api.server.controllers.todolist.post.PostToDo
import models.todolist.ToDoPriority
import models.todolist.ToDoTask
import sz.interceptors.EbeanTransaction
import sz.scaffold.annotations.Comment
import sz.scaffold.annotations.PostForm
import sz.scaffold.controller.ApiController
import sz.scaffold.controller.reply.ReplyBase
import sz.scaffold.tools.BizLogicException


@Comment("待办事项管理")
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
POST    /api/v1/todolist/newToDo        com.api.server.controllers.ToDoController.newToDo
```

* gradle run, 打开测试页面:[http://localhost:9000/api/builtin/doc/apiIndex](http://localhost:9000/api/builtin/doc/apiIndex) 进行测试, 查看数据库里是否新增对应的记录.

#### API: 根据待办事项ID查询指定的代码事项
* 定义接口需要用到的 Reply 类 **ToDoItemReply** 和其中包含的Bean class: **ToDoItem**, 代码如下
* **src/main/kotlin/com/api/server/controllers/todolist/reply/ToDoItem.kt**

```kotlin
package com.api.server.controllers.todolist.reply

import jodd.datetime.JDateTime
import models.todolist.ToDoTask
import sz.scaffold.annotations.Comment


class ToDoItem {

    @Comment("待办事项ID")
    var id: Long = 0

    @Comment("待办事项内容")
    var task = ""

    @Comment("待办事项优先级, 1-低, 2-普通, 3-高")
    var priority = 0

    @Comment("待办事项是否已完成")
    var finished: Boolean = false

    @Comment("待办事项完成时间")
    var finish_time: JDateTime? = null

    companion object {

        fun buildFrom(todoTask: ToDoTask?): ToDoItem? {
            if (todoTask != null) {
                val item = ToDoItem()
                item.id = todoTask.id
                item.task = todoTask.task
                item.priority = todoTask.priority
                item.finished = todoTask.finished
                item.finish_time = todoTask.finish_time

                return item
            } else {
                return null
            }
        }
    }
}
```

* **src/main/kotlin/com/api/server/controllers/todolist/reply/ToDoItemReply.kt**

```kotlin
package com.api.server.controllers.todolist.reply

import jodd.datetime.JDateTime
import models.todolist.ToDoPriority
import sz.scaffold.annotations.Comment
import sz.scaffold.controller.reply.ReplyBase

//
// Created by kk on 2019-06-05.
//
class ToDoItemReply : ReplyBase() {

    @Comment("待办事项")
    var item: ToDoItem? = null

    override fun SampleData() {
        item = ToDoItem()
        item!!.id = 99
        item!!.task = "改 bug: 9527"
        item!!.priority = ToDoPriority.High.code
        item!!.finished= true
        item!!.finish_time = JDateTime("2019-01-01 23:52:26")
    }
}
```

* 在 **ToDoController** 里添加控制器方法: **fun byId(@Comment("待办事项ID") id: Long): ToDoItemReply**

```kotlin
    @Comment("根据待办事项ID查询指定的代码事项")
    fun byId(@Comment("待办事项ID") id: Long): ToDoItemReply {
        val reply = ToDoItemReply()

        // 采用QueryBean的方式进行查询
        val todoTask = ToDoTask.queryBean()
            .id.eq(id)
            .deleted.eq(false)
            .findOne() ?: throw BizLogicException("待办事项(id: $id)不存在或者已经被标记删除")

        // 采用Finder的方式进行查询
//        val todoTask = ToDoTask.query().where()
//            .eq("id", id)
//            .eq("deleted", false)
//            .findOne() ?: throw BizLogicException("待办事项(id: $id)不存在或者已经被标记删除")

        reply.item = ToDoItem.buildFrom(todoTask)

        return reply
    }
```

* 添加一条API的方法路由

```
GET     /api/v1/todolist/byId                                           com.api.server.controllers.todolist.ToDoController.byId
```

#### 其他Api接口
* 其他几个api接口, 开发过程与上述2个接口的开发过程类似, 这里不细述了, 请参考完整示例代码
* [待办事项完整Sample代码](https://github.com/LoveInShenZhen/ProjectTemplates/tree/master/samples/todolist)

```bash
svn export https://github.com/LoveInShenZhen/ProjectTemplates.git/trunk/samples/todolist todolist
```