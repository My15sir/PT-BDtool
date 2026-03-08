#!/usr/bin/env python3
import json
import os
import platform
import queue
import shutil
import subprocess
import sys
import threading
import time
from pathlib import Path
from tkinter import BOTH, END, LEFT, RIGHT, TOP, W, X, filedialog, messagebox, ttk
import tkinter as tk
from tkinter.scrolledtext import ScrolledText


APP_NAME = "PT-BDtool"


def resolve_script_path(path: str) -> Path:
    return Path(path).expanduser().resolve()


def find_app_root() -> Path:
    script_path = resolve_script_path(__file__)
    script_dir = script_path.parent
    candidates = [
        Path(os.environ.get("PTBDTOOL_ROOT", "")),
        Path(os.environ.get("PTBD_INSTALL_ROOT", "")),
        script_dir,
        script_dir.parent,
        Path("/opt/PT-BDtool"),
        Path.home() / ".local/share/pt-bdtool/PT-BDtool-app",
    ]
    for candidate in candidates:
        if not str(candidate):
            continue
        if (candidate / "ptbd-remote.sh").is_file() and (candidate / "scripts/remote-upload-server.py").is_file():
            return candidate.resolve()
    return script_dir


APP_ROOT = find_app_root()


def config_path() -> Path:
    system = platform.system()
    home = Path.home()
    if system == "Windows":
        base = Path(os.environ.get("APPDATA", home / "AppData/Roaming"))
        return base / APP_NAME / "gui-config.json"
    if system == "Darwin":
        return home / "Library/Application Support" / APP_NAME / "gui-config.json"
    return home / ".config/ptbd-gui/config.json"


CONFIG_PATH = config_path()


def default_save_dir() -> str:
    home = Path.home()
    candidates = [
        home / "Desktop",
        home / "桌面",
        home / "Downloads",
    ]
    for candidate in candidates:
        if candidate.is_dir():
            return str(candidate)
    return str(home)


DEFAULT_CONFIG = {
    "remote_host": "root@your-vps",
    "remote_port": "22",
    "remote_password": "",
    "remote_cmd": "pt",
    "save_dir": default_save_dir(),
    "scan_include": "/home/admin/Downloads",
    "scan_exclude": "",
    "auto_cleanup": True,
}


def load_config() -> dict:
    if not CONFIG_PATH.is_file():
        return DEFAULT_CONFIG.copy()
    try:
        data = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except Exception:
        return DEFAULT_CONFIG.copy()
    merged = DEFAULT_CONFIG.copy()
    merged.update({k: v for k, v in data.items() if k in merged})
    return merged


def save_config(data: dict) -> None:
    CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
    CONFIG_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def find_bash() -> str | None:
    if os.name != "nt":
        return shutil.which("bash")
    candidates = [
        shutil.which("bash"),
        r"C:\Program Files\Git\bin\bash.exe",
        r"C:\Program Files\Git\usr\bin\bash.exe",
        r"C:\Program Files (x86)\Git\bin\bash.exe",
        r"C:\Program Files (x86)\Git\usr\bin\bash.exe",
    ]
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return candidate
    return None


def shell_script_path() -> Path:
    return APP_ROOT / "ptbd-remote.sh"


class App:
    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.root.title("PT-BDtool 小白启动器")
        self.root.geometry("920x720")
        self.process: subprocess.Popen[str] | None = None
        self.reader_threads: list[threading.Thread] = []
        self.log_queue: queue.Queue[str] = queue.Queue()
        self.status_var = tk.StringVar(value="就绪：先填配置，保存后点击“一步到位启动”")
        self.config_vars = {}
        self._build_ui()
        self._load_into_form(load_config())
        self._poll_logs()
        self.root.protocol("WM_DELETE_WINDOW", self.on_close)

    def _build_ui(self) -> None:
        container = ttk.Frame(self.root, padding=12)
        container.pack(fill=BOTH, expand=True)

        title = ttk.Label(
            container,
            text="PT-BDtool 小白启动器（Win / macOS / Linux MVP）",
            font=("Arial", 15, "bold"),
        )
        title.pack(anchor=W)

        subtitle = ttk.Label(
            container,
            text="第一次填好 VPS 和保存目录，以后双击后点一下启动即可。",
        )
        subtitle.pack(anchor=W, pady=(4, 12))

        form = ttk.Frame(container)
        form.pack(fill=X)

        self._add_entry(form, "VPS 地址", "remote_host", 0, "例如：root@1.2.3.4")
        self._add_entry(form, "SSH 端口", "remote_port", 1, "默认 22")
        self._add_entry(form, "SSH 密码", "remote_password", 2, "留空表示走密钥", show="*")
        self._add_entry(form, "远端命令", "remote_cmd", 3, "默认 pt")
        self._add_entry(form, "扫描白名单", "scan_include", 4, "默认 /home/admin/Downloads")
        self._add_entry(form, "额外排除", "scan_exclude", 5, "可留空")
        self._add_entry(form, "本机保存目录", "save_dir", 6, "结果回到本机这里")

        save_row = ttk.Frame(form)
        save_row.grid(row=7, column=1, sticky="ew", pady=(2, 8))
        ttk.Button(save_row, text="选择目录", command=self.pick_save_dir).pack(side=LEFT)
        self.config_vars["auto_cleanup"] = tk.BooleanVar(value=True)
        ttk.Checkbutton(
            save_row,
            text="成功后自动清理 VPS 生成目录",
            variable=self.config_vars["auto_cleanup"],
        ).pack(side=LEFT, padx=(12, 0))

        form.columnconfigure(1, weight=1)

        tips = ttk.Label(
            container,
            text="说明：Windows 目前建议安装 Git for Windows；macOS / Linux 需要本机有 bash、ssh、python3。",
        )
        tips.pack(anchor=W, pady=(0, 12))

        actions = ttk.Frame(container)
        actions.pack(fill=X, pady=(0, 8))
        ttk.Button(actions, text="保存配置", command=self.save_form).pack(side=LEFT)
        ttk.Button(actions, text="打开配置目录", command=self.open_config_dir).pack(side=LEFT, padx=(8, 0))
        ttk.Button(actions, text="一步到位启动", command=self.start_remote).pack(side=LEFT, padx=(8, 0))
        ttk.Button(actions, text="停止当前任务", command=self.stop_remote).pack(side=LEFT, padx=(8, 0))

        status = ttk.Label(container, textvariable=self.status_var)
        status.pack(anchor=W, pady=(4, 8))

        self.log_view = ScrolledText(container, wrap="word", font=("Consolas", 10))
        self.log_view.pack(fill=BOTH, expand=True)
        self.log_view.insert(END, f"App root: {APP_ROOT}\n")
        self.log_view.insert(END, f"Config: {CONFIG_PATH}\n")
        self.log_view.insert(END, "准备完成。\n")
        self.log_view.configure(state="disabled")

    def _add_entry(self, parent, label_text: str, key: str, row: int, hint: str, show: str | None = None) -> None:
        ttk.Label(parent, text=label_text).grid(row=row, column=0, sticky=W, padx=(0, 10), pady=4)
        variable = tk.StringVar()
        self.config_vars[key] = variable
        entry = ttk.Entry(parent, textvariable=variable, show=show or "")
        entry.grid(row=row, column=1, sticky="ew", pady=4)
        ttk.Label(parent, text=hint).grid(row=row, column=2, sticky=W, padx=(10, 0), pady=4)

    def _load_into_form(self, data: dict) -> None:
        for key, value in data.items():
            var = self.config_vars.get(key)
            if isinstance(var, tk.BooleanVar):
                var.set(bool(value))
            elif var is not None:
                var.set(str(value))

    def form_data(self) -> dict:
        return {
            "remote_host": self.config_vars["remote_host"].get().strip(),
            "remote_port": self.config_vars["remote_port"].get().strip() or "22",
            "remote_password": self.config_vars["remote_password"].get(),
            "remote_cmd": self.config_vars["remote_cmd"].get().strip() or "pt",
            "save_dir": self.config_vars["save_dir"].get().strip() or default_save_dir(),
            "scan_include": self.config_vars["scan_include"].get().strip() or "/home/admin/Downloads",
            "scan_exclude": self.config_vars["scan_exclude"].get().strip(),
            "auto_cleanup": bool(self.config_vars["auto_cleanup"].get()),
        }

    def save_form(self) -> bool:
        data = self.form_data()
        if not data["remote_host"]:
            messagebox.showerror("缺少配置", "请先填写 VPS 地址。")
            return False
        try:
            save_config(data)
        except Exception as exc:
            messagebox.showerror("保存失败", str(exc))
            return False
        self.status_var.set(f"已保存配置：{CONFIG_PATH}")
        self.append_log(f"[gui] 配置已保存到 {CONFIG_PATH}")
        return True

    def pick_save_dir(self) -> None:
        chosen = filedialog.askdirectory(initialdir=self.config_vars["save_dir"].get() or default_save_dir())
        if chosen:
            self.config_vars["save_dir"].set(chosen)

    def open_config_dir(self) -> None:
        CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
        target = str(CONFIG_PATH.parent)
        try:
            if platform.system() == "Windows":
                os.startfile(target)
            elif platform.system() == "Darwin":
                subprocess.Popen(["open", target])
            else:
                subprocess.Popen(["xdg-open", target])
        except Exception as exc:
            messagebox.showinfo("配置目录", f"{target}\n\n无法自动打开：{exc}")

    def start_remote(self) -> None:
        if self.process and self.process.poll() is None:
            messagebox.showinfo("任务进行中", "当前已经有任务在运行。")
            return
        if not self.save_form():
            return

        bash_bin = find_bash()
        if not bash_bin:
            messagebox.showerror(
                "缺少 bash",
                "当前机器没有找到 bash。\n\nWindows 请先安装 Git for Windows；macOS / Linux 请确认 bash 可用。",
            )
            return

        remote_script = shell_script_path()
        if not remote_script.is_file():
            messagebox.showerror("缺少脚本", f"找不到远端入口：{remote_script}")
            return

        data = self.form_data()
        save_dir = Path(data["save_dir"]).expanduser()
        save_dir.mkdir(parents=True, exist_ok=True)

        env = os.environ.copy()
        env.update(
            {
                "PTBD_REMOTE_HOST": data["remote_host"],
                "PTBD_REMOTE_PORT": data["remote_port"],
                "PTBD_REMOTE_PASSWORD": data["remote_password"],
                "PTBD_REMOTE_PT_CMD": data["remote_cmd"],
                "PTBD_LOCAL_SAVE_DIR": str(save_dir),
                "PTBD_SCAN_INCLUDE_ROOTS": data["scan_include"],
                "PTBD_SCAN_EXCLUDE_ROOTS": data["scan_exclude"],
                "PTBD_AUTO_CLEANUP": "1" if data["auto_cleanup"] else "0",
            }
        )

        cmd = [bash_bin, str(remote_script)]
        creationflags = 0
        if os.name == "nt":
            creationflags = subprocess.CREATE_NO_WINDOW

        self.append_log("")
        self.append_log(f"[gui] 启动命令：{' '.join(cmd)}")
        self.append_log(f"[gui] 本机保存目录：{save_dir}")
        self.status_var.set("运行中：请在弹出的终端/当前输出里完成远端菜单选择")

        self.process = subprocess.Popen(
            cmd,
            cwd=str(APP_ROOT),
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            stdin=subprocess.DEVNULL,
            text=True,
            bufsize=1,
            creationflags=creationflags,
        )
        self._start_reader(self.process)

    def _start_reader(self, proc: subprocess.Popen[str]) -> None:
        def read_stream() -> None:
            assert proc.stdout is not None
            for line in proc.stdout:
                self.log_queue.put(line.rstrip("\n"))
            rc = proc.wait()
            self.log_queue.put(f"[gui] 任务结束，退出码：{rc}")
            self.log_queue.put(f"[gui] 如果成功，结果应该已经回到：{self.form_data()['save_dir']}")

        thread = threading.Thread(target=read_stream, daemon=True)
        thread.start()
        self.reader_threads.append(thread)

    def stop_remote(self) -> None:
        if not self.process or self.process.poll() is not None:
            self.status_var.set("当前没有运行中的任务。")
            return
        try:
            self.process.terminate()
            self.append_log("[gui] 已请求停止当前任务")
            self.status_var.set("已请求停止，请稍等。")
        except Exception as exc:
            messagebox.showerror("停止失败", str(exc))

    def append_log(self, text: str) -> None:
        self.log_view.configure(state="normal")
        self.log_view.insert(END, text + "\n")
        self.log_view.see(END)
        self.log_view.configure(state="disabled")

    def _poll_logs(self) -> None:
        try:
            while True:
                line = self.log_queue.get_nowait()
                self.append_log(line)
                if line.startswith("[gui] 任务结束"):
                    self.status_var.set("任务已结束。请查看上面的输出和本机保存目录。")
        except queue.Empty:
            pass
        self.root.after(150, self._poll_logs)

    def on_close(self) -> None:
        if self.process and self.process.poll() is None:
            if not messagebox.askyesno("退出", "当前任务还在运行。确定要退出并停止它吗？"):
                return
            self.stop_remote()
            time.sleep(0.2)
        self.root.destroy()


def cli_main() -> int:
    if "--print-config-path" in sys.argv:
        print(CONFIG_PATH)
        return 0
    if "--self-check" in sys.argv:
        bash_bin = find_bash() or "<missing>"
        print(f"app_root={APP_ROOT}")
        print(f"config={CONFIG_PATH}")
        print(f"bash={bash_bin}")
        print(f"remote_script={shell_script_path()}")
        return 0

    root = tk.Tk()
    style = ttk.Style(root)
    if "clam" in style.theme_names():
        style.theme_use("clam")
    App(root)
    root.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(cli_main())
