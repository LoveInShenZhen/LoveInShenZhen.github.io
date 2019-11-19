# 新建项目 
---
    
## 安装构建依赖
* 安装好 **subversion**, 获取项目工程模板时会用到
* 安装好 **JDK 8**
* 安装好 **Gradle 5.x**
* IDE推荐使用 **IntelliJ IDEA**, [下载页面](https://www.jetbrains.com/idea/download/)  
> Community社区版功能足以, 有钱的同学可以买 **Ultimate** 版

## 创建项目
现在假定我们创建一个叫 **Hello** 的应用.

* 从 [LoveInShenZhen/ProjectTemplates](https://github.com/LoveInShenZhen/ProjectTemplates) 获取工程模板.

```bash
svn export https://github.com/LoveInShenZhen/ProjectTemplates.git/trunk/vertx-web-simple Hello
```

## 项目目录结构
项目工程的目录结构如下, 具体的目录和配置文件的说明, 请阅读 _**ToDo**_ 文档.
```
Hello
├── build.gradle.kts
├── conf
│   ├── application.conf
│   ├── logback.xml
│   ├── route
│   ├── route.websocket
│   ├── vertx-default-jul-logging.properties
│   ├── vertxOptions.json
│   └── zookeeper.json
├── gradle
│   └── wrapper
│       ├── gradle-wrapper.jar
│       └── gradle-wrapper.properties
├── gradlew
├── gradlew.bat
├── settings.gradle.kts
└── src
    └── main
        ├── kotlin
        │   ├── com
        │   │   └── api
        │   │       └── server
        │   │           ├── ApiServer.kt
        │   │           └── controllers
        │   │               └── sample
        │   │                   ├── SampleController.kt
        │   │                   └── reply
        │   │                       ├── HelloReply.kt
        │   │                       └── UserListReply.kt
        │   └── models
        │       └── sample
        │           └── User.kt
        └── resources
            └── ebean.mf

15 directories, 19 files
```

## 运行项目

```bash
# 进入到工程目录
cd Hello
# 构建项目, gradle自动下载依赖项
gradle build
# 运行项目
gradle run
```
![输出显示](../../img/vertx_web_simple_gradle_run.png)

## 在浏览器中查看启动页面
* 默认使用 9000 端口, 可以在 conf/application.conf 里进行配置
* 点击 [http://localhost:9000](http://localhost:9000) 在浏览器中查看启动页面

![启动页面](../../img/index_page.png)

## 查看自动生成的API接口测试页面
* 点击 **[api 列表](http://localhost:9000/api/builtin/doc/apiIndex)** 查看自动生成的APi测试页面

* API接口文档列表页面

![API接口文档列表页面](../../img/apiIndex_page.png)

* API接口测试页面, 填入参数, 点击 **测试** 按钮

![API接口测试页面](../../img/api_sample_hello.png)

## 查看自动生成的API接口文档
* 点击 **[api 文档的html格式](http://localhost:9000/api/builtin/doc/apiDocHtml)** 查看自动生成的API接口文档
* API接口文档页面

![API接口文档页面](../../img/api_doc_page.png)
