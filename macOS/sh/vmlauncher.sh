#!/bin/bash

# ==========================================
# Jason Chao's Lume VM Launcher
# version: 1.0.0
# updated: 2026/02/02
# ==========================================

# --- 全局配置 ---
# 宿主机共享目录 (格式: 宿主机路径:读写权限)
SHARED_DIR="/Volumes/Extreme-Pro/Share-With-VM:rw"

# --- 新建 VM 的默认模板 ---
DEFAULT_PRESET="sequoia"
DEFAULT_CPU="8"
DEFAULT_RAM="16GB"
DEFAULT_DISK="100GB"

# ==========================================
# Functions
# ==========================================

function run_vm() {
  local name=$1
  echo ""
  echo "🚀 Booting [$name]..."
  echo "   - Shared Dir: $SHARED_DIR"

  # 使用 lume run 启动
  lume run "$name" --shared-dir "$SHARED_DIR"
}

function create_vm() {
  echo ""
  echo "🛠  Enter new VM name (e.g., ai-agent-01):"
  # read -r 在 bash 3.2 中也是安全的
  read -r new_name

  if [[ -z "$new_name" ]]; then
    echo "❌ Name cannot be empty."
    exit 1
  fi

  echo "⚙️  Creating instance [$new_name]..."

  lume create "$new_name" \
    --unattended "$DEFAULT_PRESET" \
    --cpu "$DEFAULT_CPU" \
    --memory "$DEFAULT_RAM" \
    --disk-size "$DEFAULT_DISK"

  if [ $? -eq 0 ]; then
    echo "✅ Creation complete."
    run_vm "$new_name"
  else
    echo "❌ Creation failed."
    exit 1
  fi
}

# ==========================================
# Main Logic
# ==========================================

echo "🔍 Scanning VMs using 'lume ls'..."

VM_LIST=()

# 兼容 Bash 3.2 的读入方式
# 1. 执行 lume ls
# 2. awk 'NR>1 {print $1}': 跳过第一行标题，只打印第一列(名称)
while IFS= read -r line; do
  if [[ -n "$line" ]]; then
    VM_LIST+=("$line")
  fi
done < <(lume ls | awk 'NR>1 {print $1}')

# 检查列表是否为空
if [ ${#VM_LIST[@]} -eq 0 ]; then
  echo "⚠️  No existing VMs found."
  create_vm
else
  echo "📋 Available VMs:"

  PS3="👉 Select a VM to start (enter number): "

  select opt in "${VM_LIST[@]}" "++ Create New ++"; do
    if [[ "$opt" == "++ Create New ++" ]]; then
      create_vm
      break
    elif [[ -n "$opt" ]]; then
      run_vm "$opt"
      break
    else
      echo "❌ Invalid selection."
    fi
  done
fi
