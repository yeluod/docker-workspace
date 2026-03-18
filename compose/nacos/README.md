# Nacos Docker Run

本目录提供一套基于 `docker run` 的 Nacos 本地开发方案，不依赖 `docker compose`。

特点：

- 使用本地已有镜像 `nacos/nacos-server:latest`
- 通过 `manage.sh` 统一管理启动、停止、重建和删除
- 默认通过 `192.168.1.120:3306` 连接你已经启动好的 MySQL
- 本地日志目录落到 `/Users/wang/workspace/docker_work/nacos`

## 目录结构

```text
.
├── .env
├── manage.sh
└── README.md
```

## 前置条件

- 本机已安装 Docker
- 本机已有镜像 `nacos/nacos-server:latest`
- MySQL 已启动，且 `root/123456` 可以访问 `192.168.1.120:3306`

## 默认配置

- Nacos 镜像：`nacos/nacos-server:latest`
- 容器名：`nacos-server`
- HTTP 端口：`8848`
- Console 端口：`8080`
- gRPC 端口：`9848`
- MySQL 地址：`192.168.1.120:3306`
- MySQL 数据库：`nacos_config`
- MySQL 用户：`root`
- MySQL 密码：`123456`
- 鉴权默认开启：`NACOS_AUTH_ENABLE=true`
- JVM 堆内存：`JVM_XMS=2048m`、`JVM_XMX=2048m`

如需修改，请调整 `.env`。

## 快速开始

赋予脚本执行权限：

```bash
chmod +x manage.sh
```

启动 Nacos：

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

如果你改了 `.env`，建议重建：

```bash
./manage.sh recreate
```

## 生成 docker run 命令

如果你只想看实际执行的 `docker run`，可以直接输出：

```bash
./manage.sh print-run
```

## 连接地址

- OpenAPI / Server: `http://127.0.0.1:8848/nacos`
- Console: `http://127.0.0.1:8080/`

## 删除说明

执行以下命令：

```bash
./manage.sh delete
```

该操作会：

- 删除 `nacos-server` 容器
- 删除本地日志目录 `/Users/wang/workspace/docker_work/nacos`

该操作不会删除：

- 外部 MySQL 服务
- MySQL 中的 `nacos_config` 数据库

## 文件说明

- `.env`：Nacos 与外部 MySQL 运行参数
- `manage.sh`：统一管理脚本
