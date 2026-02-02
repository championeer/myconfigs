#!/bin/bash

# ==========================================
# Jason Chao's Lume VM Manager (Start/Stop/Create)
# version:1.0.0
# update: 2026/02/02
# ==========================================

# --- 全局配置 ---
SHARED_DIR="/Volumes/Extreme-Pro/Share-With-VM:rw"

# --- 新建 VM 默认配置 ---
DEFAULT_PRESET="sequoia"
DEFAULT_CPU="8"
DEFAULT_RAM="16GB"
DEFAULT_DISK="100GB"

# ==========================================
# Functions
# ==========================================

function stop_vm() {
  local name=$1
  echo "🛑 Stopping [$name]..."

  # 尝试停止
  lume stop "$name"

  if [ $? -eq 0 ]; then
    echo "✅ [$name] stopped successfully."
  else
    echo "⚠️  Failed to stop [$name]. Is it running?"
  fi
}

function start_vm_flow() {
  local name=$1

  echo ""
  echo "🤔 How do you want to launch [$name]?"
  echo "   1) 🖥️  Standard (GUI, Terminal Attached)   - [Default]"
  echo "   2) 👻 Headless (No Display, Attached)    - Debugging logs"
  echo "   3) 🏃 Background (GUI, Detached)          - Keep terminal free"
  echo "   4) 🥷 Service Mode (No Display, Detached) - Pure background agent"

  echo ""
  read -p "👉 Select mode (1-4) [Enter for 1]: " mode_choice
  mode_choice=${mode_choice:-1}

  # 基础命令
  local cmd="lume run \"$name\" --shared-dir \"$SHARED_DIR\""

  echo ""
  case "$mode_choice" in
  1)
    echo "🚀 Booting [$name] in Standard mode..."
    eval "$cmd"
    ;;
  2)
    echo "👻 Booting [$name] in Headless mode..."
    eval "$cmd --no-display"
    ;;
  3)
    echo "🏃 Booting [$name] in Background..."
    eval "$cmd > /dev/null 2>&1 &"
    echo "✅ VM launched in background (PID: $!)."
    ;;
  4)
    echo "🥷 Booting [$name] in Service mode..."
    eval "$cmd --no-display > /dev/null 2>&1 &"
    echo "✅ Headless VM launched in background (PID: $!)."
    ;;
  *)
    echo "❌ Invalid mode. Falling back to Standard..."
    eval "$cmd"
    ;;
  esac
}

function handle_vm_selection() {
  local name=$1

  echo ""
  echo "⚡️ Action for [$name]:"
  echo "   1) 🟢 Start (Boot the VM)"
  echo "   2) 🔴 Stop  (Shutdown the VM)"
  echo "   3) 🔙 Cancel"

  echo ""
  read -p "👉 Choose action [Enter for Start]: " action
  action=${action:-1}

  case "$action" in
  1)
    start_vm_flow "$name"
    ;;
  2)
    stop_vm "$name"
    ;;
  *)
    echo "🔙 Action cancelled."
    ;;
  esac
}

function create_vm() {
  echo ""
  echo "🛠  Enter new VM name (e.g., ai-agent-01):"
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
    # 新建完成后直接进入启动流程
    start_vm_flow "$new_name"
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
# 兼容 Bash 3.2 读取列表
while IFS= read -r line; do
  if [[ -n "$line" ]]; then
    VM_LIST+=("$line")
  fi
done < <(lume ls | awk 'NR>1 {print $1}')

if [ ${#VM_LIST[@]} -eq 0 ]; then
  echo "⚠️  No existing VMs found."
  create_vm
else
  echo "📋 Available VMs:"
  PS3="👉 Select a VM (enter number): "

  select opt in "${VM_LIST[@]}" "++ Create New ++"; do
    if [[ "$opt" == "++ Create New ++" ]]; then
      create_vm
      break
    elif [[ -n "$opt" ]]; then
      handle_vm_selection "$opt"
      break
    else
      echo "❌ Invalid selection."
    fi
  done
fi
