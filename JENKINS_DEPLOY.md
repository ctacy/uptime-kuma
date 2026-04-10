# Jenkins 部署命令模板

> 适用于 Uptime Kuma 项目。复制后只需改变量即可。
>
> 数据库配置来源已按源码确认：
> - `server/database.js:137` 读取 `DATA_DIR`
> - `server/database.js:173` 读取 `$DATA_DIR/db-config.json`
> - `server/database.js:286` 起根据 `type` 连接数据库

## 方案一：Jenkins Execute Shell / Freestyle 任务

### 1. SQLite 版本

```bash
set -euo pipefail

PROJECT_DIR="/data/www/uptime-kuma"
DATA_DIR="/data/uptime-kuma"
BRANCH="master"
APP_NAME="uptime-kuma"

cd "$PROJECT_DIR"

echo "===> 拉取最新代码"
git fetch --all
git checkout "$BRANCH"
git reset --hard "origin/$BRANCH"

echo "===> 安装依赖"
npm ci

echo "===> 构建前端"
npm run build

echo "===> 准备数据目录"
mkdir -p "$DATA_DIR"

cat > "$DATA_DIR/db-config.json" <<'EOF'
{
  "type": "sqlite"
}
EOF

echo "===> 重启服务"
if pm2 describe "$APP_NAME" >/dev/null 2>&1; then
  DATA_DIR="$DATA_DIR" pm2 restart "$APP_NAME" --update-env
else
  DATA_DIR="$DATA_DIR" pm2 start server/server.js --name "$APP_NAME"
fi

pm2 save

echo "===> 部署完成"
```

SQLite 数据库文件位置：

```bash
$DATA_DIR/kuma.db
```

---

### 2. MariaDB / MySQL 版本

> 注意：源码判断类型是 `mariadb`，不要写成 `mysql`。
> 数据库名字段是 `dbName`，不要写成 `database`。

```bash
set -euo pipefail

PROJECT_DIR="/data/www/uptime-kuma"
DATA_DIR="/data/uptime-kuma"
BRANCH="master"
APP_NAME="uptime-kuma"

DB_HOST="127.0.0.1"
DB_PORT="3306"
DB_NAME="kuma"
DB_USER="kuma"
DB_PASS="your_password"

cd "$PROJECT_DIR"

echo "===> 拉取最新代码"
git fetch --all
git checkout "$BRANCH"
git reset --hard "origin/$BRANCH"

echo "===> 安装依赖"
npm ci

echo "===> 构建前端"
npm run build

echo "===> 准备数据目录"
mkdir -p "$DATA_DIR"

cat > "$DATA_DIR/db-config.json" <<EOF
{
  "type": "mariadb",
  "hostname": "$DB_HOST",
  "port": "$DB_PORT",
  "dbName": "$DB_NAME",
  "username": "$DB_USER",
  "password": "$DB_PASS"
}
EOF

echo "===> 重启服务"
if pm2 describe "$APP_NAME" >/dev/null 2>&1; then
  DATA_DIR="$DATA_DIR" pm2 restart "$APP_NAME" --update-env
else
  DATA_DIR="$DATA_DIR" pm2 start server/server.js --name "$APP_NAME"
fi

pm2 save

echo "===> 部署完成"
```

---

### 3. MariaDB / MySQL Socket 版本

```bash
cat > "$DATA_DIR/db-config.json" <<'EOF'
{
  "type": "mariadb",
  "hostname": "localhost",
  "port": "3306",
  "dbName": "kuma",
  "username": "kuma",
  "password": "your_password",
  "socketPath": "/var/run/mysqld/mysqld.sock"
}
EOF
```

---

### 4. MariaDB / MySQL SSL 版本

```bash
cat > "$DATA_DIR/db-config.json" <<'EOF'
{
  "type": "mariadb",
  "hostname": "db.example.com",
  "port": "3306",
  "dbName": "kuma",
  "username": "kuma",
  "password": "your_password",
  "ssl": true,
  "ca": "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----"
}
EOF
```

---

## 方案二：Jenkins Pipeline 中的 `sh`

### SQLite 版本

```groovy
pipeline {
    agent any

    stages {
        stage('Deploy') {
            steps {
                sh '''
                    set -euo pipefail

                    PROJECT_DIR="/data/www/uptime-kuma"
                    DATA_DIR="/data/uptime-kuma"
                    BRANCH="master"
                    APP_NAME="uptime-kuma"

                    cd "$PROJECT_DIR"

                    git fetch --all
                    git checkout "$BRANCH"
                    git reset --hard "origin/$BRANCH"

                    npm ci
                    npm run build

                    mkdir -p "$DATA_DIR"

                    cat > "$DATA_DIR/db-config.json" <<'EOF'
                    {
                      "type": "sqlite"
                    }
                    EOF

                    if pm2 describe "$APP_NAME" >/dev/null 2>&1; then
                      DATA_DIR="$DATA_DIR" pm2 restart "$APP_NAME" --update-env
                    else
                      DATA_DIR="$DATA_DIR" pm2 start server/server.js --name "$APP_NAME"
                    fi

                    pm2 save
                '''
            }
        }
    }
}
```

---

### MariaDB / MySQL 版本

```groovy
pipeline {
    agent any

    stages {
        stage('Deploy') {
            steps {
                sh '''
                    set -euo pipefail

                    PROJECT_DIR="/data/www/uptime-kuma"
                    DATA_DIR="/data/uptime-kuma"
                    BRANCH="master"
                    APP_NAME="uptime-kuma"

                    DB_HOST="127.0.0.1"
                    DB_PORT="3306"
                    DB_NAME="kuma"
                    DB_USER="kuma"
                    DB_PASS="your_password"

                    cd "$PROJECT_DIR"

                    git fetch --all
                    git checkout "$BRANCH"
                    git reset --hard "origin/$BRANCH"

                    npm ci
                    npm run build

                    mkdir -p "$DATA_DIR"

                    cat > "$DATA_DIR/db-config.json" <<EOF
                    {
                      "type": "mariadb",
                      "hostname": "$DB_HOST",
                      "port": "$DB_PORT",
                      "dbName": "$DB_NAME",
                      "username": "$DB_USER",
                      "password": "$DB_PASS"
                    }
                    EOF

                    if pm2 describe "$APP_NAME" >/dev/null 2>&1; then
                      DATA_DIR="$DATA_DIR" pm2 restart "$APP_NAME" --update-env
                    else
                      DATA_DIR="$DATA_DIR" pm2 start server/server.js --name "$APP_NAME"
                    fi

                    pm2 save
                '''
            }
        }
    }
}
```

---

## 首次部署初始化

### SQLite

```bash
cd /data/www
git clone <你的仓库地址> uptime-kuma
cd uptime-kuma
npm ci
npm run build
mkdir -p /data/uptime-kuma
cat > /data/uptime-kuma/db-config.json <<'EOF'
{
  "type": "sqlite"
}
EOF
DATA_DIR="/data/uptime-kuma" pm2 start server/server.js --name uptime-kuma
pm2 save
```

### MariaDB / MySQL

```bash
cd /data/www
git clone <你的仓库地址> uptime-kuma
cd uptime-kuma
npm ci
npm run build
mkdir -p /data/uptime-kuma
cat > /data/uptime-kuma/db-config.json <<'EOF'
{
  "type": "mariadb",
  "hostname": "127.0.0.1",
  "port": "3306",
  "dbName": "kuma",
  "username": "kuma",
  "password": "your_password"
}
EOF
DATA_DIR="/data/uptime-kuma" pm2 start server/server.js --name uptime-kuma
pm2 save
```

---

## 常用可改变量

```bash
PROJECT_DIR="/data/www/uptime-kuma"   # 项目目录
DATA_DIR="/data/uptime-kuma"          # 数据目录（db-config.json 和 kuma.db 都在这里）
BRANCH="master"                       # 部署分支
APP_NAME="uptime-kuma"                # pm2 进程名
```

MariaDB / MySQL 额外变量：

```bash
DB_HOST="127.0.0.1"
DB_PORT="3306"
DB_NAME="kuma"
DB_USER="kuma"
DB_PASS="your_password"
```

---

## 部署后检查

```bash
pm2 status
pm2 logs uptime-kuma --lines 100
curl -I http://127.0.0.1:3001
curl -I http://127.0.0.1:3000
```

重点查看日志里是否出现：

```bash
Database Type: sqlite
```

或：

```bash
Database Type: mariadb
```

---

## 如果你用 systemd，不用 pm2

把启动/重启部分替换成：

```bash
DATA_DIR="/data/uptime-kuma" sudo systemctl restart uptime-kuma
sudo systemctl status uptime-kuma --no-pager
```

如果是 systemd，记得在 service 文件里配置环境变量，例如：

```ini
Environment=DATA_DIR=/data/uptime-kuma
```
