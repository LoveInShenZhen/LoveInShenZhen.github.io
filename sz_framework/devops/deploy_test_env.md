## 开发阶段的部署需求
* 因为是前后端分离的开发模式, 所以至少需要部署一套专门给前端工程师进行联调开发测试使用
* 开发的项目系统虽然是分布式的, 但是需要在开发工程师的单机上完成部署, 所以不使用docker集群.
* 要能够快速更新, 避免每次重新构建 docker image 的流程, 节省开发测试时间
* 要有脚本自动化, 打包/更新部署, 一个脚本命令搞定
* 不同的应用服务可以各自独立更新
* 运行在容器中的 MySql, Redis, RabbitMQ可以被容器外直接访问
* 运行应用服务器的容器, 提供 ssh 端口, 便于开发人员登录进去查看log, 进行调试
* 采用 Docker Compose 的方式进行部署
* 包含一个 Docker 的数据卷
* 容器内提供 Nginx 服务, 并且可以通过ssh (sftp/rsync) 的方式, 部署和更新静态页面和nginx配置文件
* 包含一个 Zookeeper 的容器, 提供集群功能
* 通过 Docker Compose file 裁剪不需要的容器
* 容器所使用的镜像和自行构建的镜像所使用的基础镜像, 都必须是docker hub 上标记为 **Official Images** 或 **VERIFIED PUBLISHER**

## 本文所描述的部署方式的限制
* 本文描述的部署方式仅限在单机上, 多机器部署, 需要先创建 docker 集群.
* 集群模式下的部署, 需要本地先搭建一个docker集群, 例如: swarm 或者 Kubernetes. 搭建docker 集群, 以及在docker集群下部署SZ的应用,不在本文的描述范围内. 会提供另外的文档描述.

---

## 准备 Docker 的宿主机
* 一台专门用于开发测试的物理机或者虚拟机(例如:云主机), 4核/8GB(以上), SSD硬盘, 100 GB以上 _(总之就是在预算范围内, 配置越高越好)_
* 操作系统: Ubuntu 18.04 LTS

### 安装 Docker Engine - Community 版
* Docker 引擎的社区版是免费的, 功能满足我们开发测试部署的需求
* 按照 [官方文档](https://docs.docker.com/install/linux/docker-ce/ubuntu/) 的说明安装 Docker 引擎
* 修改 docker daemon 的默认配置
    * 修改docker的默认存储位置及镜像存储位置, 下面的脚本, 我假设配置到 **/mnt/docker_data** 目录. 
        > 1. docker 引擎默认镜像以及容器的数据, 都保存在 **/var/run/docker** 目录下
        > 1. 但是, **/var/run/docker** 是使用的 系统根目录 / 挂载点的空间. 而系统根目录的空间通常都不是很大, 所以我们需要将docker的默认存储位置及镜像存储位置改到一个挂载到大容量磁盘空间的目录下
    * 配置镜像加速器, 这里我们配置成使用 [阿里云docker镜像加速器](https://cr.console.aliyun.com/cn-hangzhou/instances/mirrors) 服务
    * [docker daemon 配置的官方参考文档](https://docs.docker.com/engine/reference/commandline/dockerd/#daemon-configuration-file)

```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
    "data-root" : "/mnt/docker_data",
    "registry-mirrors" : ["https://zgvtbml8.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 安装 Docker Compose
* 我们采用 Docker Compose file 来编排我们的单机开发测试环境
* 参考 [官方文档-Install Docker Compose](https://docs.docker.com/compose/install/)

### ubuntu 下 docker 一键安装配置脚本
为了简化操作, 我们提供了docker的安装配置脚本
```bash
curl -fsSL https://loveinshenzhen.github.io/resources/install_docer_for_ubuntu.sh | sudo sh
```

## 部署测试环境

### 准备测试环境的 Docker Compose file
* 一套分布式的应用系统, 是由多个不同的服务组成
* sz 后端分布式应用, 按照提供的服务类型, 一般由以下几个部分组成 (_注:不一定全部都包含_)
    * MySql (*注: 测试环境, MySql 由一个mysql容器提供服务, 正式站点, 通常使用云服务商提供的云数据库服务*)
    * Redis (*注: 如果仅作为缓存来使用,可靠性没有要求的那么高, 能够快速恢复就行, 所以通常redis使用容器方式提供服务, 正式站点,也是可以选择使用云服务商提供的redis云服务, 或者自行搭建redis 的高可用+负载均衡*)
    * Zookeeper (*注: sz框架下, 我们选择使用 zookeeper 来搭建Vert.x集群*) 开发测试环境下, zookeeper 采用 standalone 方式, 生产站点上, 采用集群方式部署
    * 然后是使用sz框架开发的应用服务, 按照业务功能,提供不同服务,例如 json api server, gRpc server, async/Plan task server 等等
    * 消息队列服务: RabbitMQ/RocketMQ/(阿里云/腾讯云/华为云版的消息队列服务,等待开发实现)

* 下面, 我们按照上面的组成部分, 构建 Docker Compose file
  > Docker Compose file 语法和配置项, 请参考: https://docs.docker.com/compose/compose-file/

```yaml
version: "3.7"
services:
  # 一般的业务系统, 都会依赖于一个数据库服务, 所以就默认提供
  sz_mysql:
    image: mysql:5.7
    environment: 
      # 创建MySql实例的时候, 设置的 root 用户密码, 根据需要自己修改
      MYSQL_ROOT_PASSWORD: 1qaz2wsx
    restart: always
    volumes: 
      - type: volume
        source: sz-mysql-data
        target: /var/lib/mysql
    networks: 
      - sz-dev-test
    ports: 
      # 暴露 MySql 的端口, 便于开发调试, 用户数据库管理工具管理数据
      - "3306:3306"
  
  # 内置一个MySql的web管理工具, 通过 8666 端口访问, 便于开发调试, 可以根据实际情况, 修改端口映射, 勿与其他端口冲突
  sz_mysql_adminer:
    image: adminer
    restart: always
    networks: 
      - sz-dev-test
    ports:
      - 8666:8080

  # 缓存, token 之类的会用到, 所以也就默认提供
  sz_redis:
    image: redis:alpine
    restart: always
    networks: 
      - sz-dev-test
    ports: 
      # 暴露 redis 的端口, 便于调试开发, 便于使用 redis 管理工具
      - 6379:6379
  
  # 如果应用服务拆成多个部分, 通过 Vert.x 的 EventBus 通信, 则应用需要部署成 Vert.x 的集群模式, Vert.x集群依赖 zookeeper 服务
  # 注: 如果使用了SZ框架提供的基于MySql的PlanTask服务, 则需要部署成 Vert.x 集群模式
  sz_zookeeper:
    image: zookeeper:latest
    restart: always
    networks: 
      - sz-dev-test
    ports: 
      # 暴露给 zookeeper client 提供服务的端口, 便于开发调试 
      - 2181:2181
  
  # 应用可以使用第三方的消息队列服务, 例如使用: rabbitmq, 如果不需要, 可以将下面的 sz_rabbitmq 这节配置注释掉
  # 镜像使用参考: https://hub.docker.com/_/rabbitmq
  # 为了方便开发调试, 使用的镜像, 包含 rabbitmq 的 web 管理页面, http 访问端口: 15672, 默认用户名/密码: guest/guest
  sz_rabbitmq:
    image: rabbitmq:management-alpine
    hostname: sz_rabbitmq
    restart: always
    networks: 
      - sz-dev-test
    ports: 
      - 5672:5672
      - 15672:15672

  # 应用服务器, 所有的应用都作为容器内 supervisor 管理的服务
  # 参考: https://github.com/LoveInShenZhen/MyDockerfiles/tree/master/java/sz_all_in_one
  # ssh 用户名/密码: root/loveinshenzhen
  sz_app_server:
    image: dragonsunmoon/sz_all_in_one:latest
    restart: always
    # 应用服务, nginx 的conf和html 都是通过 sz_app_server 的ssh服务进行部署更新的, 所以把需要的数据卷都挂载上
    volumes: 
      - type: volume
        source: sz-apps-data
        target: /sz/deploy/
      - type: volume
        source: sz-nginx-html
        target: /web_html/     
      - type: volume
        source: sz-nginx-conf
        target: /etc/nginx/
    networks: 
      - sz-dev-test
    ports: 
      # 按照需要, 添加需要暴露出去的端口, 为了方便开发调试, 默认暴露 9000 和 5005 (remote debug)
      # nginx 的端口暴露为 8080 和 8443, 根据需要, 自行修改端口映射
      # 根据需要, 自行添加新的端口映射
      - "10022:22"
      - "8080:80"
      - "8443:443"
      - "9000:9000"
      - "5005:5005"
    depends_on:
      - sz_mysql
      - sz_redis
      - sz_zookeeper

# 同一个网络内的容器, 彼此之间可以通过 service name 进行访问, 因为 docker compose 会自动将 service 的名称在网络配置里, 添加一个别名
# 这样 service 之间可以通过名称直接访问 (简单说, 通过 service name 可以 ping 通)
networks:
  sz-dev-test:

# 采用数据卷的方式, 是因为, 这种方式可以同时在 mac, linux 和 windows 下都工作
volumes:
  sz-apps-data:
  sz-mysql-data:
  sz-nginx-html:
  sz-nginx-conf:

```

### 创建/删除/启动/停止 测试环境
* 创建测试环境
```bash
docker-compose -f sz-docker-compose.yml up -d
```

* 删除测试环境
```bash
docker-compose -f sz-docker-compose.yml down --volumes
```

* 启动测试环境
```bash
docker-compose -f sz-docker-compose.yml start
```

* 停止测试环境
```bash
docker-compose -f sz-docker-compose.yml stop
```

## SZ 应用打包部署脚本
SZ 应用源码是一套 gradle 工程, 我们提供了一套 python3 脚本, 用于编译打包, 上传部署/更新.

### 配置 SSH 证书登录
* 首先在打包机器上生成本地的 ssh 证书, 如果已经生成过证书, 则无须重复生成
```bash
ssh-keygen
```

* 安装 ssh 证书到目标机器上
```bash
# 请替换成测试服务器IP地址, 如果是在本机部署, 则替换成 localhost
ssh-copy-id -p 10022 root@test_server_ip
```

### 获取脚本
```bash
svn export https://github.com/LoveInShenZhen/DeploySamples.git/trunk/sz/dev_and_test/sz_deploy
```

* 查看命令帮助
```bash
cd sz_deploy
./sz_deploy.py --help
```

```
usage: sz_deploy.py [-h] {app,conf,undeploy} ...

SZ 后端 [应用]/[配置文件] 部署工具.

optional arguments:
  -h, --help           show this help message and exit

子命令:
  注: 通过以下子命令指定部署/操作类型, 详细参数用法请在子命令后加上 -h 查看

  {app,conf,undeploy}
    app                部署[应用]到目标服务器
    conf               部署[一组配置文件]到目标服务器
    undeploy           清理删除部署在目标服务器的[应用]和[配置]
```

* 查看子命令的帮助
* * 子命令: **app** _指定gradle工程目录路径,编译,打包,部署上传/更新到目标服务器上, 并启动应用_

```bash
./sz_deploy.py app --help
```

```
usage: sz_deploy.py app [-h] --prj-dir ~/work/vertx-web-mutli/api_server
                        [--host 127.0.0.1] [--port 10022]
                        [--ssh-key ~/.ssh/id_rsa]

optional arguments:
  -h, --help            show this help message and exit
  --prj-dir ~/work/vertx-web-mutli/api_server
                        [应用]对应的gradle工程目录路径,必填参数
  --host 127.0.0.1      目标主机IP,默认:127.0.0.1
  --port 10022          目标主机ssh服务端口,默认:10022
  --ssh-key ~/.ssh/id_rsa
                        用于ssh登录的证书路径,默认:~/.ssh/id_rsa
```

* * 子命令: **conf** _指定gradle工程目录路径 和 测试环境配置文件目录, 部署上传/更新到目标服务器上, 并重启应用_

```bash
./sz_deploy.py conf --help
```

```
usage: sz_deploy.py conf [-h] --conf-dir ~/work/test_env/api_server/conf
                         --prj-dir ~/work/vertx-web-mutli/api_server
                         [--host 127.0.0.1] [--port 10022]
                         [--ssh-key ~/.ssh/id_rsa]

optional arguments:
  -h, --help            show this help message and exit
  --conf-dir ~/work/test_env/api_server/conf
                        配置文件目录的路径,必填参数
  --prj-dir ~/work/vertx-web-mutli/api_server
                        [应用]对应的gradle工程目录路径,必填参数
  --host 127.0.0.1      目标主机IP,默认:127.0.0.1
  --port 10022          目标主机ssh服务端口,默认:10022
  --ssh-key ~/.ssh/id_rsa
                        用于ssh登录的证书路径,默认:~/.ssh/id_rsa
```

* * 子命令: **undeploy** _指定gradle工程目录路径, 在目标服务器上停止应用, 并删除应用及其配置_ 

```bash
./sz_deploy.py undeploy --help
```

```
usage: sz_deploy.py undeploy [-h] --prj-dir ~/work/vertx-web-mutli/api_server
                             [--host 127.0.0.1] [--port 10022]
                             [--ssh-key ~/.ssh/id_rsa]

optional arguments:
  -h, --help            show this help message and exit
  --prj-dir ~/work/vertx-web-mutli/api_server
                        [应用]对应的gradle工程目录路径,必填参数
  --host 127.0.0.1      目标主机IP,默认:127.0.0.1
  --port 10022          目标主机ssh服务端口,默认:10022
  --ssh-key ~/.ssh/id_rsa
                        用于ssh登录的证书路径,默认:~/.ssh/id_rsa
```

## 测试环境 SZ应用 的进程管理器
* 测试环境里, 部署应用的容器, 使用的镜像是 **dragonsunmoon/sz_all_in_one:latest**
* 该镜像提供了 ssh 服务, 可以通过 ssh 登录到容器内部, 进行操作
* 该容器使用了 [Python Supervisor](http://supervisord.org/index.html) 来管理多个不同的 SZ 应用的进程.
* 镜像的构建和 Docker File 请参考: https://github.com/LoveInShenZhen/MyDockerfiles/tree/master/java/sz_all_in_one
* 每个部署在该容器内的应用, 都对应一个 Supervisor 的配置文件, 所在目录: **/etc/supervisor/conf.d/**, 该文件由部署的脚本自动创建
* 可以使用 **supervisorctl** 命令来 启动/停止/重启/查看状态 应用

```bash
# 假设应用的名称为 api_server

# 启动 api_server
supervisorctl start api_server

# 停止 api_server
supervisorctl stop api_server

# 重启 api_server
supervisorctl restart api_server

# 查看 api_server 状态
supervisorctl status api_server

```

## 测试环境下 SZ 应用的配置管理
* 为每个 SZ 应用创建一个单独的目录, 保存该应用在测试环境下的配置文件
* 配置文件应该包括如下的几个文件
  * application.conf
  * logback.xml
  * vertxOptions.json
  * zookeeper.json
* 使用 sz_deploy.py conf 子命令进行配置部署和更新操作