#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/pipe_new.sh"

# 检查是否以 root 用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以 root 用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到 root 用户，然后再次运行此脚本。"
    exit 1
fi

# 安装节点的函数
function install_node() {
    local USER_TOKEN="${1:-}"
    local USER_EMAIL="${2:-}"
    local USER_PROXY="${3:-}"

    # 检查是否提供了必要参数
    if [ -z "$USER_TOKEN" ] || [ -z "$USER_EMAIL" ]; then
        echo "错误：必须提供 TOKEN 和 EMAIL"
        return 1
    fi

    # 使用邮箱创建唯一目录名，替换特殊字符
    UNIQUE_DIR="pipe_$(echo "$USER_EMAIL" | sed 's/[^a-zA-Z0-9]/_/g')"

    # 检查是否已经存在目录
    if [ -d "$UNIQUE_DIR" ]; then
        read -p "$UNIQUE_DIR 目录已存在，是否删除重新安装？(y/n): " confirm
        if [ "$confirm" != "y" ]; then
            echo "安装已取消"
            return
        fi
        rm -rf "$UNIQUE_DIR"
    fi

    # 克隆仓库到唯一目录
    git clone https://github.com/sdohuajia/pipe.git "$UNIQUE_DIR"
    cd "$UNIQUE_DIR" || { echo "进入目录失败"; return 1; }

    pip install -r requirements.txt

    # 将 token 和邮箱保存到唯一的 token.txt 文件中
    echo "$USER_TOKEN,$USER_EMAIL" > token.txt

    # 如果提供了代理，保存到 proxy.txt
    if [ -n "$USER_PROXY" ]; then
        echo "$USER_PROXY" > proxy.txt
    fi

    # 使用 tmux 启动，会话名基于邮箱
    SESSION_NAME="pipe_$(echo "$USER_EMAIL" | sed 's/[^a-zA-Z0-9]/_/g')"
    tmux new-session -d -s "$SESSION_NAME"
    tmux send-keys -t "$SESSION_NAME" "cd $UNIQUE_DIR" C-m
    tmux send-keys -t "$SESSION_NAME" "python3 main.py" C-m

    echo "节点已启动，会话名：$SESSION_NAME"
    echo "使用 'tmux attach -t $SESSION_NAME' 查看日志"
     echo "要退出 tmux 会话，请按 Ctrl+B 然后按 D。"
}

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "多实例 PiPe 节点管理器"
        echo "================================================================"
        echo "1) 添加新的 PiPe 节点实例"
        echo "2) 列出所有 PiPe 节点会话"
        echo "3) 退出"
        read -p "输入选项: " option

        case $option in
            1)
                read -p "请输入 TOKEN: " TOKEN
                read -p "请输入 EMAIL: " EMAIL
                read -p "请输入代理 IP (可选): " PROXY
                install_node "$TOKEN" "$EMAIL" "$PROXY"
                read -n 1 -s -r -p "按任意键继续..."
                ;;
            2)
                tmux ls | grep "pipe_"
                read -n 1 -s -r -p "按任意键继续..."
                ;;
            3)
                echo "退出脚本。"
                exit 0
                ;;
            *)
                echo "无效选项，请重试"
                read -n 1 -s -r -p "按任意键继续..."
                ;;
        esac
    done
}

# 调用主菜单函数
main_menu