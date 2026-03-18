# Redis Docker Compose

本目录提供一套用于本地开发的 Redis 环境，包含以下能力：

- 固定容器名 `redis-server`
- 宿主机端口映射，支持通过 `127.0.0.1` 连接
- 独立的 Redis 配置文件 `conf/redis.conf`
- Redis 持久化数据保存到宿主机目录 `/Users/wang/workspace/docker_work/redis`
- 统一的运维脚本 `manage.sh`

## 目录结构

```text
.
├── .env
├── compose.yaml
├── conf/
│   └── redis.conf
├── manage.sh
└── README.md
```

## 前置条件

- 已安装 Docker Engine
- 已安装 Docker Compose
- 当前系统为 macOS，且允许 Docker 挂载宿主机目录

## 默认配置

- Redis 镜像：`redis:7`
- 容器名称：`redis-server`
- 宿主机端口：`6379`
- 宿主机数据目录：`/Users/wang/workspace/docker_work/redis`
- 默认密码：`123456`

如需调整端口或密码，请修改 `.env`。

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

宿主机上可直接通过 `127.0.0.1` 连接：

```bash
redis-cli -h 127.0.0.1 -p 6379 -a 123456
```

验证连接：

```bash
redis-cli -h 127.0.0.1 -p 6379 -a 123456 ping
```

## 配置说明

- Redis 主要配置在 `conf/redis.conf`
- 当前启用了 AOF 持久化：`appendonly yes`
- 当前保留 RDB 快照规则，便于本地开发恢复
- Redis 启动时通过环境变量注入密码 `REDIS_PASSWORD`

## 删除说明

执行以下命令：

```bash
./manage.sh delete
```

该操作会先要求输入 `YES` 确认，随后执行以下清理：

- 删除当前 Compose 项目创建的容器
- 删除当前 Compose 项目创建的网络
- 删除宿主机数据目录 `/Users/wang/workspace/docker_work/redis`

如果需要跳过确认，可使用：

```bash
./manage.sh delete -y
```

## 文件说明

- `compose.yaml`：Docker Compose 主配置
- `conf/redis.conf`：Redis 服务配置
- `manage.sh`：统一管理脚本
- `.env`：本地环境变量
