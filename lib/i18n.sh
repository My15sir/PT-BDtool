#!/usr/bin/env bash

# i18n helpers for PT-BDtool CLI.

LANG_CODE="${LANG_CODE:-}"

i18n_normalize_lang() {
  local raw="$(echo "${1:-}" | tr '[:upper:]' '[:lower:]')"
  case "$raw" in
    zh|zh_cn|zh-cn|cn|chinese) echo "zh" ;;
    en|en_us|en-us|english) echo "en" ;;
    *) return 1 ;;
  esac
}

i18n_detect_lang() {
  local locale="${LC_ALL:-${LANG:-}}"
  if [[ -z "$locale" ]]; then
    echo "zh"
  elif [[ "$locale" == *zh* || "$locale" == *ZH* ]]; then
    echo "zh"
  else
    echo "en"
  fi
}

set_lang() {
  local candidate="${1:-}"
  if [[ -n "$candidate" ]]; then
    LANG_CODE="$(i18n_normalize_lang "$candidate" 2>/dev/null || true)"
  fi
  if [[ -z "$LANG_CODE" && -n "${BDTOOL_LANG:-}" ]]; then
    LANG_CODE="$(i18n_normalize_lang "$BDTOOL_LANG" 2>/dev/null || true)"
  fi
  if [[ -z "$LANG_CODE" ]]; then
    LANG_CODE="$(i18n_detect_lang)"
  fi
  export LANG_CODE
  export BDTOOL_LANG="$LANG_CODE"
}

t() {
  local key="$1"
  case "$LANG_CODE:$key" in
    zh:APP_TITLE) echo "PT-BDtool 交互控制台" ;;
    en:APP_TITLE) echo "PT-BDtool Interactive Console" ;;

    zh:APP_SUBTITLE) echo "新手菜单 + 老手子命令" ;;
    en:APP_SUBTITLE) echo "Menu for beginners + commands for power users" ;;

    zh:HELP_TITLE) echo "用法" ;;
    en:HELP_TITLE) echo "Usage" ;;

    zh:HELP_DESC) echo "支持交互菜单与子命令模式。" ;;
    en:HELP_DESC) echo "Supports interactive menu and command mode." ;;

    zh:HELP_NONTTY_POLICY) echo "无参数且非交互终端：输出帮助并退出。" ;;
    en:HELP_NONTTY_POLICY) echo "No args in non-interactive terminal: show help and exit." ;;

    zh:HELP_COMMANDS) echo "子命令" ;;
    en:HELP_COMMANDS) echo "Commands" ;;

    zh:HELP_EXAMPLES) echo "示例" ;;
    en:HELP_EXAMPLES) echo "Examples" ;;

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

    zh:MENU_1) echo "1) 一键安装 / One-click install" ;;
    en:MENU_1) echo "1) 一键安装 / One-click install" ;;

    zh:MENU_2) echo "2) 环境体检 / Doctor" ;;
    en:MENU_2) echo "2) 环境体检 / Doctor" ;;

    zh:MENU_3) echo "3) 扫描/生成 / Scan" ;;
    en:MENU_3) echo "3) 扫描/生成 / Scan" ;;

    zh:MENU_4) echo "4) 清理 / Clean (危险操作)" ;;
    en:MENU_4) echo "4) 清理 / Clean (dangerous)" ;;

    zh:MENU_5) echo "5) 查看日志 / View logs" ;;
    en:MENU_5) echo "5) 查看日志 / View logs" ;;

    zh:MENU_6) echo "6) 切换语言 / Switch language" ;;
    en:MENU_6) echo "6) 切换语言 / Switch language" ;;

    zh:MENU_7) echo "7) 退出 / Quit" ;;
    en:MENU_7) echo "7) 退出 / Quit" ;;

    zh:MENU_SWITCHED_ZH) echo "已切换为中文。" ;;
    en:MENU_SWITCHED_ZH) echo "Switched to Chinese." ;;

    zh:MENU_SWITCHED_EN) echo "已切换为英文。" ;;
    en:MENU_SWITCHED_EN) echo "Switched to English." ;;

    zh:MENU_BYE) echo "已退出。" ;;
    en:MENU_BYE) echo "Bye." ;;

    zh:ERR_UNCAUGHT) echo "发生未捕捉错误，详情见日志。" ;;
    en:ERR_UNCAUGHT) echo "Uncaught error occurred. See logs for details." ;;

    zh:ERR_REQUIRE_TTY) echo "当前为非交互终端，无法显示菜单。" ;;
    en:ERR_REQUIRE_TTY) echo "Non-interactive terminal detected. Menu is unavailable." ;;

    zh:ERR_NEED_VALUE) echo "缺少必要参数，请补充后重试。" ;;
    en:ERR_NEED_VALUE) echo "Missing required value. Please retry." ;;

    zh:ERR_BAD_LANG) echo "无效语言，请使用 zh 或 en。" ;;
    en:ERR_BAD_LANG) echo "Invalid language. Use zh or en." ;;

    zh:ERR_NONINT_NEED_YES) echo "无人值守 clean 必须显式传入 --yes。" ;;
    en:ERR_NONINT_NEED_YES) echo "Non-interactive clean requires explicit --yes." ;;

    zh:ERR_SCAN_PATH_EMPTY) echo "扫描路径不能为空。" ;;
    en:ERR_SCAN_PATH_EMPTY) echo "Scan path must not be empty." ;;

    zh:ERR_LOG_TAIL_INT) echo "--tail 必须是正整数。" ;;
    en:ERR_LOG_TAIL_INT) echo "--tail must be a positive integer." ;;

    zh:HINT_LOG) echo "请查看运行日志" ;;
    en:HINT_LOG) echo "Check run log" ;;

    zh:HINT_USE_HELP) echo "可使用 --help 查看完整用法。" ;;
    en:HINT_USE_HELP) echo "Use --help for full usage." ;;

    zh:CONFIRM_CLEAN_1) echo "确认清理 bdtool-output 吗？" ;;
    en:CONFIRM_CLEAN_1) echo "Confirm cleaning bdtool-output?" ;;

    zh:CONFIRM_CLEAN_2) echo "二次确认：该操作不可恢复，继续？" ;;
    en:CONFIRM_CLEAN_2) echo "Second confirm: this action is irreversible. Continue?" ;;

    zh:INSTALL_RUNNING) echo "执行安装流程" ;;
    en:INSTALL_RUNNING) echo "Running install flow" ;;

    zh:DOCTOR_RUNNING) echo "执行环境体检" ;;
    en:DOCTOR_RUNNING) echo "Running doctor" ;;

    zh:SCAN_RUNNING) echo "执行扫描/生成" ;;
    en:SCAN_RUNNING) echo "Running scan/generation" ;;

    zh:CLEAN_RUNNING) echo "执行清理" ;;
    en:CLEAN_RUNNING) echo "Running cleanup" ;;

    zh:LOGS_RUNNING) echo "查看日志" ;;
    en:LOGS_RUNNING) echo "Viewing logs" ;;

    zh:SCAN_PATH_PROMPT) echo "请输入扫描路径" ;;
    en:SCAN_PATH_PROMPT) echo "Enter scan path" ;;

    zh:SCAN_PATH_DEFAULT) echo "默认当前目录 ." ;;
    en:SCAN_PATH_DEFAULT) echo "Default current dir ." ;;

    zh:MSG_NONTTY_HELP) echo "检测到非交互终端，显示帮助后退出。" ;;
    en:MSG_NONTTY_HELP) echo "Non-interactive terminal detected, showing help and exiting." ;;

    zh:LOG_PATH) echo "详情日志" ;;
    en:LOG_PATH) echo "Log path" ;;

    *) echo "$key" ;;
  esac
}
