#!/usr/bin/env bash

LANG_CODE="${LANG_CODE:-zh}"

i18n_normalize_lang() {
  case "$(echo "${1:-}" | tr '[:upper:]' '[:lower:]')" in
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

  [[ -n "$resolved" ]] || resolved="zh"
  LANG_CODE="$resolved"
  export LANG_CODE
  export BDTOOL_LANG="$LANG_CODE"
}

t() {
  local key="$1"
  case "$LANG_CODE:$key" in
    zh:APP_TITLE) echo "PT-BDtool 交互控制台" ;;
    en:APP_TITLE) echo "PT-BDtool Interactive Console" ;;
    zh:APP_SUBTITLE) echo "极限稳定版" ;;
    en:APP_SUBTITLE) echo "Extreme stable edition" ;;
    zh:VERSION_LABEL) echo "版本" ;;
    en:VERSION_LABEL) echo "Version" ;;
    zh:GITHUB_LABEL) echo "项目地址" ;;
    en:GITHUB_LABEL) echo "GitHub" ;;

    zh:MENU_PROMPT) echo "请输入选项（1-7，q退出）" ;;
    en:MENU_PROMPT) echo "Choose an option (1-7, q to quit)" ;;
    zh:MENU_INVALID) echo "无效选项，请重试。" ;;
    en:MENU_INVALID) echo "Invalid option. Try again." ;;
    zh:MENU_1) echo "1) 一键安装" ;;
    en:MENU_1) echo "1) One-click install" ;;
    zh:MENU_2) echo "2) 环境体检" ;;
    en:MENU_2) echo "2) Doctor" ;;
    zh:MENU_3) echo "3) 扫描/生成" ;;
    en:MENU_3) echo "3) Scan/Generate" ;;
    zh:MENU_4) echo "4) 清理" ;;
    en:MENU_4) echo "4) Clean" ;;
    zh:MENU_5) echo "5) 查看日志" ;;
    en:MENU_5) echo "5) View logs" ;;
    zh:MENU_6) echo "6) 切换语言" ;;
    en:MENU_6) echo "6) Switch language" ;;
    zh:MENU_7) echo "7) 退出" ;;
    en:MENU_7) echo "7) Quit" ;;
    zh:MENU_BYE) echo "已退出。" ;;
    en:MENU_BYE) echo "Bye." ;;

    zh:HELP_TITLE) echo "用法" ;;
    en:HELP_TITLE) echo "Usage" ;;
    zh:HELP_DESC) echo "支持交互菜单与子命令模式。" ;;
    en:HELP_DESC) echo "Supports interactive menu and command mode." ;;
    zh:HELP_NONTTY_POLICY) echo "无参数且非交互终端：输出帮助并退出。" ;;
    en:HELP_NONTTY_POLICY) echo "No args in non-interactive terminal: show help and exit." ;;

    zh:ACTION_DONE) echo "已完成" ;;
    en:ACTION_DONE) echo "completed" ;;
    zh:ACTION_FAIL) echo "失败，详情见：" ;;
    en:ACTION_FAIL) echo "failed, see: " ;;
    zh:PRESS_ENTER_RETURN) echo "按回车返回菜单" ;;
    en:PRESS_ENTER_RETURN) echo "Press Enter to return" ;;

    zh:INSTALL_DONE) echo "安装完成，命令可用：bdtool" ;;
    en:INSTALL_DONE) echo "Install done, command ready: bdtool" ;;
    zh:INSTALL_NEXT) echo "下一步：执行“bdtool”进入菜单" ;;
    en:INSTALL_NEXT) echo "Next: run 'bdtool' to open menu" ;;

    zh:DOCTOR_DONE) echo "体检完成" ;;
    en:DOCTOR_DONE) echo "Doctor completed" ;;
    zh:SCAN_RUNNING) echo "扫描/生成" ;;
    en:SCAN_RUNNING) echo "Scan/Generate" ;;

    zh:SCAN_MENU_TITLE) echo "扫描模式" ;;
    en:SCAN_MENU_TITLE) echo "Scan mode" ;;
    zh:SCAN_MENU_1) echo "1) 扫描全盘" ;;
    en:SCAN_MENU_1) echo "1) Full disk scan" ;;
    zh:SCAN_MENU_2) echo "2) 扫描指定目录" ;;
    en:SCAN_MENU_2) echo "2) Scan specific directory" ;;
    zh:SCAN_MENU_3) echo "3) 后台扫描" ;;
    en:SCAN_MENU_3) echo "3) Background scan" ;;
    zh:SCAN_MENU_0) echo "0) 返回" ;;
    en:SCAN_MENU_0) echo "0) Back" ;;
    zh:SCAN_MENU_PROMPT) echo "请选择扫描模式" ;;
    en:SCAN_MENU_PROMPT) echo "Choose scan mode" ;;

    zh:SCAN_RISK_1) echo "风险提示：全盘扫描将产生高 IO。" ;;
    en:SCAN_RISK_1) echo "Risk: full scan may cause high IO." ;;
    zh:SCAN_RISK_2) echo "风险提示：任务可能持续较长时间。" ;;
    en:SCAN_RISK_2) echo "Risk: task may run for a long time." ;;
    zh:SCAN_RISK_3) echo "风险提示：可能影响系统性能。" ;;
    en:SCAN_RISK_3) echo "Risk: system performance may be impacted." ;;
    zh:SCAN_RISK_CONFIRM) echo "输入 1 继续，其它键返回" ;;
    en:SCAN_RISK_CONFIRM) echo "Type 1 to continue, others to return" ;;

    zh:SCAN_DIR_PROMPT) echo "请输入扫描目录" ;;
    en:SCAN_DIR_PROMPT) echo "Enter scan directory" ;;

    zh:BG_MENU_1) echo "1) 启动后台扫描" ;;
    en:BG_MENU_1) echo "1) Start background scan" ;;
    zh:BG_MENU_2) echo "2) 查看任务状态" ;;
    en:BG_MENU_2) echo "2) View task status" ;;
    zh:BG_MENU_3) echo "3) 停止任务" ;;
    en:BG_MENU_3) echo "3) Stop task" ;;
    zh:BG_MENU_4) echo "4) 恢复扫描" ;;
    en:BG_MENU_4) echo "4) Resume scan" ;;
    zh:BG_MENU_0) echo "0) 返回" ;;
    en:BG_MENU_0) echo "0) Back" ;;
    zh:BG_MENU_PROMPT) echo "请选择后台操作" ;;
    en:BG_MENU_PROMPT) echo "Choose background action" ;;
    zh:BG_TASK_ID) echo "任务ID" ;;
    en:BG_TASK_ID) echo "Task ID" ;;
    zh:BG_STARTED) echo "后台任务已启动" ;;
    en:BG_STARTED) echo "Background task started" ;;

    zh:CLEAN_DRYRUN_DONE) echo "清理预演完成（未实际删除）" ;;
    en:CLEAN_DRYRUN_DONE) echo "Clean dry-run completed (nothing deleted)" ;;
    zh:CLEAN_CONFIRM_1) echo "确认执行实际删除吗？" ;;
    en:CLEAN_CONFIRM_1) echo "Confirm real deletion?" ;;
    zh:CLEAN_CONFIRM_2) echo "二次确认：仅删除 manifest 记录文件，继续？" ;;
    en:CLEAN_CONFIRM_2) echo "Second confirm: delete only manifest entries, continue?" ;;

    zh:LANG_SWITCH_ZH) echo "已切换为中文。" ;;
    en:LANG_SWITCH_ZH) echo "Switched to Chinese." ;;
    zh:LANG_SWITCH_EN) echo "已切换为英文。" ;;
    en:LANG_SWITCH_EN) echo "Switched to English." ;;

    zh:ERR_UNCAUGHT) echo "发生未捕捉错误。" ;;
    en:ERR_UNCAUGHT) echo "Uncaught error occurred." ;;
    zh:ERR_NEED_VALUE) echo "缺少参数值。" ;;
    en:ERR_NEED_VALUE) echo "Missing parameter value." ;;
    zh:ERR_INVALID_PATH) echo "路径无效或不可读。" ;;
    en:ERR_INVALID_PATH) echo "Path is invalid or unreadable." ;;
    zh:ERR_LOG_PATH) echo "详情见日志：" ;;
    en:ERR_LOG_PATH) echo "See log: " ;;
    zh:ERR_LOCKED) echo "已有任务运行中，请稍后重试。" ;;
    en:ERR_LOCKED) echo "Another task is running. Please retry later." ;;

    *) echo "$key" ;;
  esac
}
