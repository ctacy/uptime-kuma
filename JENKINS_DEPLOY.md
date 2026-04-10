# Jenkins 部署命令模板

> 适用于 Uptime Kuma 项目。复制后只需改变量即可。

## 方案一：Jenkins Execute Shell / Freestyle 任务

```bash
set -euo pipefail

PROJECT_DIR="/data/www/uptime-kuma"
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

echo "===> 重启服务"
if pm2 describe "$APP_NAME" >/dev/null 2>&1; then
  pm2 restart "$APP_NAME" --update-env
else
  pm2 start server/server.js --name "$APP_NAME"
fi

pm2 save

echo "===> 部署完成"
```

---

## 方案二：Jenkins Pipeline 中的 `sh`

```groovy
pipeline {
    agent any

    stages {
        stage('Deploy') {
            steps {
                sh '''
                    set -euo pipefail

                    PROJECT_DIR="/data/www/uptime-kuma"
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

                    echo "===> 重启服务"
                    if pm2 describe "$APP_NAME" >/dev/null 2>&1; then
                      pm2 restart "$APP_NAME" --update-env
                    else
                      pm2 start server/server.js --name "$APP_NAME"
                    fi

                    pm2 save

                    echo "===> 部署完成"
                '''
            }
        }
    }
}
```

---

## 首次部署初始化

```bash
cd /data/www
git clone <你的仓库地址> uptime-kuma
cd uptime-kuma
npm ci
npm run build
pm2 start server/server.js --name uptime-kuma
pm2 save
```

---

## 常用可改变量

```bash
PROJECT_DIR="/data/www/uptime-kuma"   # 项目目录
BRANCH="master"                       # 部署分支
APP_NAME="uptime-kuma"                # pm2 进程名
```

---

## 部署后检查

```bash
pm2 status
curl -I http://127.0.0.1:3001
curl -I http://127.0.0.1:3000
```

---

## 如果你用 systemd，不用 pm2

把“重启服务”部分替换成：

```bash
npm ci
npm run build
sudo systemctl restart uptime-kuma
sudo systemctl status uptime-kuma --no-pager
```
