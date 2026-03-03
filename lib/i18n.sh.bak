#!/usr/bin/env bash

LANG_CODE="${LANG_CODE:-zh}"

normalize_lang() {
  case "$(echo "${1:-}" | tr '[:upper:]' '[:lower:]')" in
    en|en_us|en-us|english) echo "en" ;;
    zh|zh_cn|zh-cn|cn|chinese|"") echo "zh" ;;
    *) echo "zh" ;;
  esac
}

set_lang() {
  local cli_lang="${1:-}"
  if [[ -n "$cli_lang" ]]; then
    LANG_CODE="$(normalize_lang "$cli_lang")"
  elif [[ -n "${LANG_CODE:-}" ]]; then
    LANG_CODE="$(normalize_lang "$LANG_CODE")"
  else
    LANG_CODE="zh"
  fi
  export LANG_CODE
}

t() {
  local key="$1"
  case "$LANG_CODE:$key" in
    zh:APP_TITLE) echo "PT-BDtool" ;;
    en:APP_TITLE) echo "PT-BDtool" ;;
    zh:MENU_TITLE) echo "主菜单" ;;
    en:MENU_TITLE) echo "Main Menu" ;;
    zh:MENU_PROMPT) echo "请输入选项" ;;
    en:MENU_PROMPT) echo "Choose an option" ;;

    zh:MENU_1) echo "1) 扫描" ;;
    en:MENU_1) echo "1) Scan" ;;
    zh:MENU_2) echo "2) 切换语言" ;;
    en:MENU_2) echo "2) Switch language" ;;
    zh:MENU_3) echo "3) 退出" ;;
    en:MENU_3) echo "3) Quit" ;;
    zh:MENU_INVALID) echo "输入无效，请重试。" ;;
    en:MENU_INVALID) echo "Invalid input. Please retry." ;;

    zh:SCAN_TITLE) echo "扫描方式" ;;
    en:SCAN_TITLE) echo "Scan Mode" ;;
    zh:SCAN_MENU_1) echo "1) 扫描全盘" ;;
    en:SCAN_MENU_1) echo "1) Full disk scan" ;;
    zh:SCAN_MENU_2) echo "2) 扫描指定目录" ;;
    en:SCAN_MENU_2) echo "2) Scan specific directory" ;;
    zh:SCAN_MENU_0) echo "0) 返回" ;;
    en:SCAN_MENU_0) echo "0) Back" ;;

    zh:SCAN_WARN_1) echo "全盘扫描可能耗时很久。" ;;
    en:SCAN_WARN_1) echo "Full disk scan may take a long time." ;;
    zh:SCAN_WARN_2) echo "全盘扫描会产生较高 IO。" ;;
    en:SCAN_WARN_2) echo "Full disk scan may cause high IO." ;;
    zh:SCAN_WARN_3) echo "可能影响系统性能。" ;;
    en:SCAN_WARN_3) echo "System performance may be affected." ;;
    zh:SCAN_CONFIRM_FULL) echo "输入 1 继续，其它键返回" ;;
    en:SCAN_CONFIRM_FULL) echo "Type 1 to continue, other keys to go back" ;;
    zh:SCAN_DIR_PROMPT) echo "请输入要扫描的目录" ;;
    en:SCAN_DIR_PROMPT) echo "Enter directory to scan" ;;
    zh:SCAN_DIR_INVALID) echo "目录无效，请重试。" ;;
    en:SCAN_DIR_INVALID) echo "Invalid directory. Please retry." ;;

    zh:SCAN_NONE) echo "未发现可处理条目。" ;;
    en:SCAN_NONE) echo "No items found." ;;
    zh:SCAN_RESULTS) echo "扫描结果（最多显示前 50 条）" ;;
    en:SCAN_RESULTS) echo "Scan results (first 50 items)" ;;
    zh:SCAN_MORE) echo "更多结果已省略。" ;;
    en:SCAN_MORE) echo "More results omitted." ;;
    zh:SCAN_PICK) echo "输入序号选择条目，输入 0 返回" ;;
    en:SCAN_PICK) echo "Select an item number, 0 to return" ;;
    zh:SCAN_PICK_INVALID) echo "选择无效，请重试。" ;;
    en:SCAN_PICK_INVALID) echo "Invalid selection. Please retry." ;;
    zh:SCAN_PICK_LIMIT) echo "错误次数过多，已返回。" ;;
    en:SCAN_PICK_LIMIT) echo "Too many invalid attempts. Returned." ;;

    zh:GEN_DONE) echo "生成完成：" ;;
    en:GEN_DONE) echo "Generated: " ;;
    zh:POST_MENU_1) echo "1) 下载结果到本地（打包下载）" ;;
    en:POST_MENU_1) echo "1) Download result package" ;;
    zh:POST_MENU_2) echo "2) 返回菜单" ;;
    en:POST_MENU_2) echo "2) Back to menu" ;;
    zh:POST_PROMPT) echo "请输入选项" ;;
    en:POST_PROMPT) echo "Choose an option" ;;

    zh:DL_DONE) echo "下载包已生成：" ;;
    en:DL_DONE) echo "Package created: " ;;
    zh:CLEAN_TMP_PROMPT) echo "是否清理临时文件？" ;;
    en:CLEAN_TMP_PROMPT) echo "Clean temporary files?" ;;
    zh:CLEAN_TMP_1) echo "1) 清理" ;;
    en:CLEAN_TMP_1) echo "1) Clean" ;;
    zh:CLEAN_TMP_2) echo "2) 不清理" ;;
    en:CLEAN_TMP_2) echo "2) Keep" ;;
    zh:ALL_DONE) echo "已完成" ;;
    en:ALL_DONE) echo "Done" ;;

    zh:LANG_SW_TO_ZH) echo "已切换到中文。" ;;
    en:LANG_SW_TO_ZH) echo "Switched to Chinese." ;;
    zh:LANG_SW_TO_EN) echo "已切换到英文。" ;;
    en:LANG_SW_TO_EN) echo "Switched to English." ;;

    zh:HELP_TEXT) echo "用法: bdtool [--lang zh|en] [--help]" ;;
    en:HELP_TEXT) echo "Usage: bdtool [--lang zh|en] [--help]" ;;

    zh:DEPEND_OK) echo "已安装" ;;
    en:DEPEND_OK) echo "installed" ;;
    zh:DEPEND_INSTALLING) echo "正在安装" ;;
    en:DEPEND_INSTALLING) echo "installing" ;;
    zh:DEPEND_FAIL) echo "安装失败" ;;
    en:DEPEND_FAIL) echo "install failed" ;;

    zh:ERR_HINT_FILE) echo "错误详情：" ;;
    en:ERR_HINT_FILE) echo "Error details: " ;;

    *) echo "$key" ;;
  esac
}
