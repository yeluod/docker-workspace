# MySQL Docker Compose

本目录提供一套用于本地开发的 MySQL 8.4 环境，包含以下能力：

- 固定容器名 `mysql-server`
- 宿主机端口映射，支持通过 `127.0.0.1` 连接
- 独立的 MySQL 配置文件 `conf.d/my.cnf`
- 首次启动时自动执行 `initdb/` 下的初始化 SQL
- 数据持久化到宿主机目录 `/Users/wang/workspace/docker_work/mysql`
- 统一的运维脚本 `manage.sh`

## 目录结构

```text
.
├── .env
├── compose.yaml
├── conf.d/
│   └── my.cnf
├── initdb/
│   └── 01-init_db.sql
├── manage.sh
└── README.md
```

## 前置条件

- 已安装 Docker Engine
- 已安装 Docker Compose
- 当前系统为 macOS，且允许 Docker 挂载宿主机目录

## 默认配置

- MySQL 版本：`mysql:8.4`
- 容器名称：`mysql-server`
- 宿主机端口：`3306`
- 宿主机数据目录：`/Users/wang/workspace/docker_work/mysql`
- 默认 root 密码：`123456`
- 默认初始化数据库：`init_db`
- 默认初始化用户：`init_user`
- 默认初始化用户密码：`init_pass`

如需调整账号、密码或端口，请修改 `.env`。

## 快速开始

首次使用建议先赋予脚本执行权限：

```bash
chmod +x manage.sh
```

启动服务：

```bash
./manage.sh start
```

查看状态：

```bash
./manage.sh status
```

查看日志：

```bash
./manage.sh logs
./manage.sh logs -f
```

停止服务：

```bash
./manage.sh stop
```

重启服务：

```bash
./manage.sh restart
```

## 连接方式

在宿主机上可直接通过 `127.0.0.1` 连接：

```bash
mysql -h 127.0.0.1 -P 3306 -u root -p123456
```

连接初始化数据库：

```bash
mysql -h 127.0.0.1 -P 3306 -u init_user -pinit_pass init_db
```

验证初始化数据：

```bash
mysql -h 127.0.0.1 -P 3306 -u init_user -pinit_pass -D init_db -e "select * from demo_message;"
```

## 初始化说明

- `initdb/` 下的 SQL 脚本只会在数据目录首次初始化时执行
- 当前初始化脚本会创建数据库 `init_db`
- 当前初始化脚本会创建表 `demo_message`
- 当前初始化脚本会插入一条示例数据 `hello mysql`

如果宿主机数据目录已经存在，再修改 `initdb/` 脚本不会自动重新执行。

## 删除说明

执行以下命令：

```bash
./manage.sh delete
```

该操作会先要求输入 `YES` 确认，随后执行以下清理：

- 删除当前 Compose 项目创建的容器
- 删除当前 Compose 项目创建的网络
- 删除宿主机数据目录 `/Users/wang/workspace/docker_work/mysql`

如果需要跳过确认，可使用：

```bash
./manage.sh delete -y
```

## 文件说明

- `compose.yaml`：Docker Compose 主配置
- `conf.d/my.cnf`：MySQL 服务配置
- `initdb/`：首次初始化 SQL
- `manage.sh`：统一管理脚本
- `.env`：本地环境变量
