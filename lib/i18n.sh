#!/usr/bin/env bash

# i18n helpers for PT-BDtool CLI.

LANG_CODE="${LANG_CODE:-zh}"

i18n_normalize_lang() {
  local raw
  raw="$(echo "${1:-}" | tr '[:upper:]' '[:lower:]')"
  case "$raw" in
    zh|zh_cn|zh-cn|cn|chinese) echo "zh" ;;
    en|en_us|en-us|english) echo "en" ;;
    *) return 1 ;;
  esac
}

set_lang() {
  local candidate="${1:-}"
  local resolved=""

  if [[ -n "$candidate" ]]; then
    resolved="$(i18n_normalize_lang "$candidate" 2>/dev/null || true)"
  elif [[ -n "${LANG_CODE:-}" ]]; then
    resolved="$(i18n_normalize_lang "$LANG_CODE" 2>/dev/null || true)"
  elif [[ -n "${BDTOOL_LANG:-}" ]]; then
    resolved="$(i18n_normalize_lang "$BDTOOL_LANG" 2>/dev/null || true)"
  fi

  if [[ -z "$resolved" ]]; then
    resolved="zh"
  fi

  LANG_CODE="$resolved"
  export LANG_CODE
  export BDTOOL_LANG="$LANG_CODE"
}

t() {
  local key="$1"
  case "$LANG_CODE:$key" in
    zh:APP_TITLE) echo "PT-BDtool 交互控制台" ;;
    en:APP_TITLE) echo "PT-BDtool Interactive Console" ;;

    zh:APP_SUBTITLE) echo "简洁稳定的命令行工具" ;;
    en:APP_SUBTITLE) echo "Simple and stable command line tool" ;;

    zh:VERSION_LABEL) echo "版本" ;;
    en:VERSION_LABEL) echo "Version" ;;

    zh:GITHUB_LABEL) echo "项目地址" ;;
    en:GITHUB_LABEL) echo "GitHub" ;;

    zh:HELP_TITLE) echo "用法" ;;
    en:HELP_TITLE) echo "Usage" ;;

    zh:HELP_DESC) echo "支持交互菜单与子命令模式。" ;;
    en:HELP_DESC) echo "Supports interactive menu and command mode." ;;

    zh:HELP_NONTTY_POLICY) echo "无参数且非交互终端：输出帮助并退出。" ;;
    en:HELP_NONTTY_POLICY) echo "No args in non-interactive terminal: show help and exit." ;;

    zh:HELP_COMMANDS) echo "子命令" ;;
    en:HELP_COMMANDS) echo "Commands" ;;

    zh:HELP_OPT_LANG) echo "强制语言（zh/en）" ;;
    en:HELP_OPT_LANG) echo "Force language (zh/en)" ;;

    zh:HELP_OPT_NONINT) echo "无人值守（禁止交互输入）" ;;
    en:HELP_OPT_NONINT) echo "Non-interactive mode (no blocking input)" ;;

    zh:HELP_OPT_YES) echo "跳过危险确认" ;;
    en:HELP_OPT_YES) echo "Skip dangerous confirmations" ;;

    zh:HELP_OPT_TAIL) echo "日志 tail 行数" ;;
    en:HELP_OPT_TAIL) echo "Tail line count" ;;

    zh:MENU_PROMPT) echo "请输入选项（1-7，q退出）" ;;
    en:MENU_PROMPT) echo "Choose an option (1-7, q to quit)" ;;

    zh:MENU_INVALID) echo "无效选项，请输入 1-7 或 q。" ;;
    en:MENU_INVALID) echo "Invalid option. Enter 1-7 or q." ;;

    zh:MENU_1) echo "1) 一键安装" ;;
    en:MENU_1) echo "1) One-click install" ;;

    zh:MENU_2) echo "2) 环境体检" ;;
    en:MENU_2) echo "2) Doctor" ;;

    zh:MENU_3) echo "3) 扫描/生成" ;;
    en:MENU_3) echo "3) Scan" ;;

    zh:MENU_4) echo "4) 清理（危险）" ;;
    en:MENU_4) echo "4) Clean (dangerous)" ;;

    zh:MENU_5) echo "5) 查看日志" ;;
    en:MENU_5) echo "5) View logs" ;;

    zh:MENU_6) echo "6) 切换语言" ;;
    en:MENU_6) echo "6) Switch language" ;;

    zh:MENU_7) echo "7) 退出" ;;
    en:MENU_7) echo "7) Quit" ;;

    zh:MENU_SWITCHED_ZH) echo "已切换为中文。" ;;
    en:MENU_SWITCHED_ZH) echo "Switched to Chinese." ;;

    zh:MENU_SWITCHED_EN) echo "已切换为英文。" ;;
    en:MENU_SWITCHED_EN) echo "Switched to English." ;;

    zh:MENU_BYE) echo "已退出。" ;;
    en:MENU_BYE) echo "Bye." ;;

    zh:MENU_SCAN_NA) echo "扫描功能未实现，已跳过。" ;;
    en:MENU_SCAN_NA) echo "Scan is not available, skipped." ;;

    zh:ERR_UNCAUGHT) echo "发生未捕捉错误，详情见日志。" ;;
    en:ERR_UNCAUGHT) echo "Uncaught error occurred. See logs for details." ;;

    zh:ERR_NEED_VALUE) echo "缺少必要参数，请补充后重试。" ;;
    en:ERR_NEED_VALUE) echo "Missing required value. Please retry." ;;

    zh:ERR_NONINT_NEED_YES) echo "无人值守 clean 必须显式传入 --yes。" ;;
    en:ERR_NONINT_NEED_YES) echo "Non-interactive clean requires explicit --yes." ;;

    zh:ERR_LOG_TAIL_INT) echo "--tail 必须是正整数。" ;;
    en:ERR_LOG_TAIL_INT) echo "--tail must be a positive integer." ;;

    zh:HINT_USE_HELP) echo "可使用 --help 查看完整用法。" ;;
    en:HINT_USE_HELP) echo "Use --help for full usage." ;;

    zh:CONFIRM_CLEAN_1) echo "确认清理数据目录吗？" ;;
    en:CONFIRM_CLEAN_1) echo "Confirm cleaning data directory?" ;;

    zh:CONFIRM_CLEAN_2) echo "二次确认：该操作不可恢复，继续？" ;;
    en:CONFIRM_CLEAN_2) echo "Second confirm: this action is irreversible. Continue?" ;;

    zh:INSTALL_RUNNING) echo "一键安装" ;;
    en:INSTALL_RUNNING) echo "Install" ;;

    zh:DOCTOR_RUNNING) echo "环境体检" ;;
    en:DOCTOR_RUNNING) echo "Doctor" ;;

    zh:SCAN_RUNNING) echo "扫描/生成" ;;
    en:SCAN_RUNNING) echo "Scan" ;;

    zh:CLEAN_RUNNING) echo "清理" ;;
    en:CLEAN_RUNNING) echo "Clean" ;;

    zh:LOGS_RUNNING) echo "查看日志" ;;
    en:LOGS_RUNNING) echo "View logs" ;;

    zh:MSG_NONTTY_HELP) echo "检测到非交互终端，显示帮助后退出。" ;;
    en:MSG_NONTTY_HELP) echo "Non-interactive terminal detected, showing help and exiting." ;;

    zh:LOG_PATH) echo "日志路径" ;;
    en:LOG_PATH) echo "Log path" ;;

    zh:ACTION_SUCCESS_PREFIX) echo "【成功】" ;;
    en:ACTION_SUCCESS_PREFIX) echo "" ;;

    zh:ACTION_FAIL_PREFIX) echo "【失败】" ;;
    en:ACTION_FAIL_PREFIX) echo "" ;;

    zh:ACTION_DONE_SUFFIX) echo "已完成" ;;
    en:ACTION_DONE_SUFFIX) echo " completed" ;;

    zh:ACTION_FAIL_SUFFIX) echo "失败，详情见：" ;;
    en:ACTION_FAIL_SUFFIX) echo " failed, see: " ;;

    zh:PRESS_ENTER_RETURN) echo "按回车返回菜单" ;;
    en:PRESS_ENTER_RETURN) echo "Press Enter to return" ;;

    zh:SCAN_MENU_TITLE) echo "扫描目录选择" ;;
    en:SCAN_MENU_TITLE) echo "Select scan directory" ;;

    zh:SCAN_MENU_BACK) echo "0) 返回上一级" ;;
    en:SCAN_MENU_BACK) echo "0) Back" ;;

    zh:SCAN_MENU_PROMPT) echo "请选择扫描目录编号" ;;
    en:SCAN_MENU_PROMPT) echo "Select directory number" ;;

    zh:SCAN_MENU_NO_DIR) echo "没有可用扫描目录，已返回主菜单。" ;;
    en:SCAN_MENU_NO_DIR) echo "No available scan directories. Back to menu." ;;

    zh:SCAN_MENU_INVALID) echo "目录选项无效，请重新输入。" ;;
    en:SCAN_MENU_INVALID) echo "Invalid directory option. Try again." ;;

    zh:SCAN_MENU_SELECTED) echo "已选择目录：" ;;
    en:SCAN_MENU_SELECTED) echo "Selected directory: " ;;

    zh:LOGS_CAPTURED) echo "最近日志已写入交互日志。" ;;
    en:LOGS_CAPTURED) echo "Recent logs written to UI log." ;;

    *) echo "$key" ;;
  esac
}
