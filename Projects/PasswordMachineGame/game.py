"""密码机小游戏：离线桌面版，使用 Python 标准库即可运行。"""

from __future__ import annotations

import ctypes
import json
import os
import random
import time
from collections import Counter
from dataclasses import asdict, dataclass, field
from pathlib import Path


def enable_high_dpi() -> None:
    """让 Windows 以真实像素绘制窗口，避免缩放后变模糊。"""
    try:
        ctypes.windll.user32.SetProcessDpiAwarenessContext(ctypes.c_void_p(-4))
        return
    except (AttributeError, OSError):
        pass
    try:
        ctypes.windll.shcore.SetProcessDpiAwareness(2)
        return
    except (AttributeError, OSError):
        pass
    try:
        ctypes.windll.user32.SetProcessDPIAware()
    except (AttributeError, OSError):
        pass


# 必须在创建 Tk 窗口前调用，Windows 才不会把窗口拉伸成模糊位图。
enable_high_dpi()

import tkinter as tk
from tkinter import messagebox, ttk


@dataclass(frozen=True)
class GameConfig:
    """一局密码题的参数。"""

    code_length: int
    color_count: int
    max_attempts: int


@dataclass
class PlayerProgress:
    """仅保存在本机的游戏进度，不包含账号或网络数据。"""

    highest_level: int = 0
    best_timed_score: int = 0
    total_wins: int = 0
    unlocked_badges: list[str] = field(default_factory=list)
    tutorial_seen: bool = False

    @classmethod
    def from_dict(cls, raw: object) -> "PlayerProgress":
        if not isinstance(raw, dict):
            return cls()
        badges = raw.get("unlocked_badges", [])
        return cls(
            highest_level=max(0, int(raw.get("highest_level", 0))),
            best_timed_score=max(0, int(raw.get("best_timed_score", 0))),
            total_wins=max(0, int(raw.get("total_wins", 0))),
            unlocked_badges=[badge for badge in badges if isinstance(badge, str)] if isinstance(badges, list) else [],
            tutorial_seen=bool(raw.get("tutorial_seen", False)),
        )


class ProgressStore:
    """以 JSON 保存进度；读取或写入失败时游戏仍可正常运行。"""

    def __init__(self, path: Path) -> None:
        self.path = path

    def load(self) -> PlayerProgress:
        try:
            return PlayerProgress.from_dict(json.loads(self.path.read_text(encoding="utf-8")))
        except (OSError, ValueError, TypeError, json.JSONDecodeError):
            return PlayerProgress()

    def save(self, progress: PlayerProgress) -> bool:
        try:
            self.path.parent.mkdir(parents=True, exist_ok=True)
            temporary_path = self.path.with_suffix(".tmp")
            temporary_path.write_text(
                json.dumps(asdict(progress), ensure_ascii=False, indent=2), encoding="utf-8"
            )
            temporary_path.replace(self.path)
            return True
        except OSError:
            return False


def default_progress_path() -> Path:
    local_app_data = os.environ.get("LOCALAPPDATA")
    base = Path(local_app_data) if local_app_data else Path.home() / "AppData" / "Local"
    return base / "密码机小游戏" / "progress.json"


PALETTE = [
    ("#e76f51", "#ffffff"),
    ("#f4a261", "#ffffff"),
    ("#e9c46a", "#1f2937"),
    ("#2a9d8f", "#ffffff"),
    ("#457b9d", "#ffffff"),
    ("#5e60ce", "#ffffff"),
    ("#9b5de5", "#ffffff"),
    ("#d149a0", "#ffffff"),
]

PRESETS = {
    "简单": GameConfig(3, 4, 8),
    "标准": GameConfig(4, 6, 10),
    "困难": GameConfig(5, 8, 10),
}

BADGES = {
    "first_win": ("初露锋芒", "成功破解第一组密码"),
    "first_try": ("一击破解", "第一次猜测就成功"),
    "level_five": ("破译专家", "闯关到达第 5 关"),
    "timed_five": ("闪电解码", "限时挑战累计 5 分"),
}


def score_guess(secret: list[int], guess: list[int]) -> tuple[int, int]:
    """返回（实心提示数，空心提示数），并正确处理重复颜色。"""
    if len(secret) != len(guess):
        raise ValueError("密码与猜测的位数必须一致")
    exact = sum(answer == attempt for answer, attempt in zip(secret, guess))
    shared_colors = sum((Counter(secret) & Counter(guess)).values())
    return exact, shared_colors - exact


def level_config(base: GameConfig, level: int) -> GameConfig:
    """每两关增加一个密码位，每三关增加一种可用颜色。"""
    if level < 1:
        raise ValueError("关卡从第 1 关开始")
    return GameConfig(
        code_length=min(6, base.code_length + (level - 1) // 2),
        color_count=min(len(PALETTE), base.color_count + (level - 1) // 3),
        max_attempts=base.max_attempts,
    )


def unlock_new_badges(progress: PlayerProgress, first_try: bool = False) -> list[str]:
    """根据当前纪录计算新解锁成就，返回这一次刚获得的成就编号。"""
    eligible: set[str] = set()
    if progress.total_wins >= 1:
        eligible.add("first_win")
    if first_try:
        eligible.add("first_try")
    if progress.highest_level >= 5:
        eligible.add("level_five")
    if progress.best_timed_score >= 5:
        eligible.add("timed_five")
    fresh = sorted(eligible.difference(progress.unlocked_badges))
    progress.unlocked_badges.extend(fresh)
    return fresh


class PasswordMachineApp(tk.Tk):
    """游戏窗口、教学、进度和两种游戏模式。"""

    def __init__(self) -> None:
        super().__init__()
        self.title("密码机 · 颜色解码")
        self.configure(bg="#f7f7f5")
        self.minsize(720, 650)
        self.geometry("800x780")
        self.protocol("WM_DELETE_WINDOW", self._on_close)

        self.progress_store = ProgressStore(default_progress_path())
        self.progress = self.progress_store.load()
        self.base_config = PRESETS["简单"]
        self.round_config = self.base_config
        self.secret: list[int] = []
        self.current_guess: list[int] = []
        self.history: list[tuple[list[int], int, int]] = []
        self.game_over = False
        self.game_mode = "单人闯关"
        self.level = 1
        self.score = 0
        self.time_limit = 60
        self.started_at = time.monotonic()
        self.deadline: float | None = None

        self._build_layout()
        self.start_game(self.base_config)
        self.after(400, self._show_first_time_tutorial)
        self.after(500, self._refresh_timer)

    def _build_layout(self) -> None:
        top = tk.Frame(self, bg="#f7f7f5", padx=24, pady=14)
        top.pack(fill="x")
        tk.Label(top, text="密码机", font=("Microsoft YaHei", 25, "bold"), bg="#f7f7f5", fg="#22223b").pack(side="left")
        tk.Label(top, text="破解隐藏的颜色组合", font=("Microsoft YaHei", 10), bg="#f7f7f5", fg="#6b7280").pack(side="left", padx=(12, 0), pady=(9, 0))

        controls = tk.Frame(self, bg="#f7f7f5", padx=24)
        controls.pack(fill="x")
        settings_controls = tk.Frame(controls, bg="#f7f7f5")
        settings_controls.pack(side="left")
        action_controls = tk.Frame(controls, bg="#f7f7f5")
        action_controls.pack(side="right")
        tk.Label(settings_controls, text="模式", bg="#f7f7f5", font=("Microsoft YaHei", 10)).pack(side="left")
        self.mode_var = tk.StringVar(value="单人闯关")
        mode_box = ttk.Combobox(settings_controls, textvariable=self.mode_var, values=["单人闯关", "限时挑战"], state="readonly", width=9)
        mode_box.pack(side="left", padx=(8, 14))
        mode_box.bind("<<ComboboxSelected>>", self._apply_mode)
        tk.Label(settings_controls, text="起始难度", bg="#f7f7f5", font=("Microsoft YaHei", 10)).pack(side="left")
        self.preset_var = tk.StringVar(value="简单")
        preset_box = ttk.Combobox(settings_controls, textvariable=self.preset_var, values=list(PRESETS), state="readonly", width=8)
        preset_box.pack(side="left", padx=8)
        preset_box.bind("<<ComboboxSelected>>", self._apply_preset)
        self._button(settings_controls, "自定义", self.open_settings).pack(side="left", padx=(0, 6))
        self._button(action_controls, "我的记录", self.open_records).pack(side="right")
        self.new_game_button = self._button(action_controls, "新游戏", lambda: self.start_game(self.base_config), primary=True)
        self.new_game_button.pack(side="right", padx=(0, 8))

        self.status_var = tk.StringVar()
        tk.Label(self, textvariable=self.status_var, bg="#22223b", fg="white", font=("Microsoft YaHei", 11), padx=18, pady=10).pack(fill="x", padx=24, pady=(14, 10))

        guide = tk.Frame(self, bg="#ececf0", padx=14, pady=10)
        guide.pack(fill="x", padx=24)
        self.tutorial_button = self._button(guide, "教学", self.open_tutorial)
        self.tutorial_button.pack(side="right")
        tk.Label(guide, text="提示圆点：", bg="#ececf0", fg="#22223b", font=("Microsoft YaHei", 10, "bold")).pack(side="left")
        tk.Label(guide, text="● 实心＝颜色和位置都正确     ○ 空心＝颜色正确、位置不同", bg="#ececf0", fg="#4b5563", font=("Microsoft YaHei", 10)).pack(side="left")

        self.history_frame = tk.Frame(self, bg="#f7f7f5")
        self.history_frame.pack(fill="both", expand=True, padx=24, pady=12)

        current = tk.Frame(self, bg="#ffffff", highlightbackground="#d9d9df", highlightthickness=1, padx=16, pady=14)
        current.pack(fill="x", padx=24, pady=(0, 12))
        tk.Label(current, text="本轮猜测", bg="#ffffff", fg="#22223b", font=("Microsoft YaHei", 11, "bold")).pack(anchor="w")
        self.guess_slots = tk.Frame(current, bg="#ffffff", pady=10)
        self.guess_slots.pack(anchor="w")
        actions = tk.Frame(current, bg="#ffffff")
        actions.pack(fill="x")
        self.undo_button = self._button(actions, "撤销一步", self.undo_guess)
        self.undo_button.pack(side="left")
        self.clear_button = self._button(actions, "清空本轮", self.clear_guess)
        self.clear_button.pack(side="left", padx=6)
        self.submit_button = self._button(actions, "提交猜测", self.submit_guess, primary=True)
        self.submit_button.pack(side="right")

        palette_panel = tk.Frame(self, bg="#f7f7f5", padx=24, pady=2)
        palette_panel.pack(fill="x")
        tk.Label(palette_panel, text="选择颜色（可重复）", bg="#f7f7f5", fg="#4b5563", font=("Microsoft YaHei", 10)).pack(anchor="w")
        self.palette_frame = tk.Frame(palette_panel, bg="#f7f7f5", pady=8)
        self.palette_frame.pack(anchor="w")

    def _button(self, parent: tk.Misc, text: str, command, primary: bool = False) -> tk.Button:
        return tk.Button(
            parent, text=text, command=command, relief="flat", cursor="hand2",
            bg="#22223b" if primary else "#e5e7eb", fg="white" if primary else "#22223b",
            activebackground="#38385e" if primary else "#d1d5db", activeforeground="white" if primary else "#22223b",
            font=("Microsoft YaHei", 10, "bold"), padx=12, pady=6, bd=0,
        )

    def _apply_preset(self, _event=None) -> None:
        self.start_game(PRESETS[self.preset_var.get()])

    def _apply_mode(self, _event=None) -> None:
        self.start_game(self.base_config)

    def start_game(self, config: GameConfig) -> None:
        """重开当前模式；闯关从第 1 关、限时挑战从 0 分开始。"""
        self.base_config = config
        self.game_mode = self.mode_var.get()
        self.level = 1
        self.score = 0
        self.game_over = False
        self.deadline = time.monotonic() + self.time_limit if self.game_mode == "限时挑战" else None
        self._begin_round()

    def _begin_round(self) -> None:
        self.round_config = level_config(self.base_config, self.level) if self.game_mode == "单人闯关" else self.base_config
        self.secret = [random.randrange(self.round_config.color_count) for _ in range(self.round_config.code_length)]
        self.current_guess = []
        self.history = []
        self.started_at = time.monotonic()
        self._render_all()

    def choose_color(self, color_index: int) -> None:
        if not self.game_over and len(self.current_guess) < self.round_config.code_length:
            self.current_guess.append(color_index)
            self._render_current_guess()

    def undo_guess(self) -> None:
        if not self.game_over and self.current_guess:
            self.current_guess.pop()
            self._render_current_guess()

    def clear_guess(self) -> None:
        if not self.game_over:
            self.current_guess = []
            self._render_current_guess()

    def submit_guess(self) -> None:
        if self.game_over:
            return
        if len(self.current_guess) != self.round_config.code_length:
            missing = self.round_config.code_length - len(self.current_guess)
            messagebox.showinfo("还差一点", f"请再选择 {missing} 个颜色。")
            return
        exact, misplaced = score_guess(self.secret, self.current_guess)
        self.history.append((self.current_guess.copy(), exact, misplaced))
        first_try = len(self.history) == 1
        self.current_guess = []

        if exact == self.round_config.code_length:
            self._handle_success(first_try)
            return
        if len(self.history) >= self.round_config.max_attempts:
            self._handle_round_failed()
            return
        self._render_all()

    def _handle_success(self, first_try: bool) -> None:
        self.progress.total_wins += 1
        if self.game_mode == "单人闯关":
            solved_level = self.level
            self.progress.highest_level = max(self.progress.highest_level, solved_level)
            badges = unlock_new_badges(self.progress, first_try)
            self.progress_store.save(self.progress)
            messagebox.showinfo("破解成功", self._success_message(f"恭喜通过第 {solved_level} 关！", badges))
            self.level += 1
        else:
            self.score += 1
            self.progress.best_timed_score = max(self.progress.best_timed_score, self.score)
            badges = unlock_new_badges(self.progress, first_try)
            self.progress_store.save(self.progress)
            # 限时模式不弹窗，保证节奏；新成就会在状态栏和记录页中保留。
        self._begin_round()

    def _handle_round_failed(self) -> None:
        if self.game_mode == "单人闯关":
            self.game_over = True
            self._render_all()
            messagebox.showinfo("本轮结束", f"第 {self.level} 关未破解。密码已用色块显示在记录区底部。")
        else:
            messagebox.showinfo("换一道题", "本题未破解，继续挑战下一题！")
            self._begin_round()

    def _success_message(self, headline: str, badges: list[str]) -> str:
        if not badges:
            return headline + "\n下一关已生成。"
        badge_lines = "\n".join(f"• {BADGES[badge][0]}：{BADGES[badge][1]}" for badge in badges)
        return headline + "\n\n解锁成就：\n" + badge_lines + "\n\n下一关已生成。"

    def _render_all(self) -> None:
        self._render_status()
        self._render_history()
        self._render_current_guess()
        self._render_palette()

    def _render_status(self) -> None:
        remaining = self.round_config.max_attempts - len(self.history)
        if self.game_over:
            state = f"本轮结束　｜　最高闯关：第 {self.progress.highest_level} 关　｜　点击“新游戏”再试一次"
        elif self.game_mode == "限时挑战":
            state = f"限时挑战　｜　得分：{self.score}　｜　最高分：{self.progress.best_timed_score}　｜　剩余：{self._seconds_left():02d} 秒　｜　本题机会：{remaining}"
        else:
            state = f"第 {self.level} 关　｜　最高：第 {self.progress.highest_level} 关　｜　剩余机会：{remaining}　｜　用时：{self._elapsed_text()}"
        self.status_var.set(state)

    def _render_history(self) -> None:
        for child in self.history_frame.winfo_children():
            child.destroy()
        if not self.history and not self.game_over:
            tk.Label(self.history_frame, text="还没有猜测记录。选择下方色块开始吧。", bg="#f7f7f5", fg="#9ca3af", font=("Microsoft YaHei", 11)).pack(pady=42)
            return
        for attempt_no, (guess, exact, misplaced) in enumerate(reversed(self.history), start=1):
            row = tk.Frame(self.history_frame, bg="#ffffff", padx=12, pady=7)
            row.pack(fill="x", pady=3)
            actual_no = len(self.history) - attempt_no + 1
            tk.Label(row, text=f"第 {actual_no} 次", width=7, anchor="w", bg="#ffffff", fg="#6b7280", font=("Microsoft YaHei", 10)).pack(side="left")
            self._draw_color_cells(row, guess, small=True).pack(side="left")
            self._draw_hint_pegs(row, exact, misplaced).pack(side="right")
        if self.game_over:
            answer_row = tk.Frame(self.history_frame, bg="#ececf0", padx=12, pady=8)
            answer_row.pack(fill="x", pady=(8, 3))
            tk.Label(answer_row, text="本局密码", width=7, anchor="w", bg="#ececf0", fg="#22223b", font=("Microsoft YaHei", 10, "bold")).pack(side="left")
            self._draw_color_cells(answer_row, self.secret, small=True).pack(side="left")

    def _render_current_guess(self) -> None:
        for child in self.guess_slots.winfo_children():
            child.destroy()
        filled = self.current_guess + [None] * (self.round_config.code_length - len(self.current_guess))
        self._draw_color_cells(self.guess_slots, filled, small=False).pack()
        state = "disabled" if self.game_over else "normal"
        self.undo_button.configure(state=state)
        self.clear_button.configure(state=state)
        self.submit_button.configure(state=state)

    def _render_palette(self) -> None:
        for child in self.palette_frame.winfo_children():
            child.destroy()
        for index, (color, text_color) in enumerate(PALETTE[:self.round_config.color_count]):
            tk.Button(
                self.palette_frame, text="", command=lambda i=index: self.choose_color(i), bg=color, fg=text_color,
                activebackground=color, relief="flat", cursor="hand2", width=5, height=2, padx=0, pady=0, bd=0,
                state="disabled" if self.game_over else "normal",
            ).pack(side="left", padx=(0, 6))

    def _draw_color_cells(self, parent: tk.Misc, cells: list[int | None], small: bool) -> tk.Frame:
        container = tk.Frame(parent, bg=parent.cget("bg"))
        size = 24 if small else 38
        for color_index in cells:
            color = "#ffffff" if color_index is None else PALETTE[color_index][0]
            cell = tk.Canvas(container, width=size, height=size, highlightthickness=0, bg=container.cget("bg"))
            margin = 3
            cell.create_oval(margin, margin, size - margin, size - margin, fill=color, outline="#c7c7cf", width=1)
            cell.pack(side="left", padx=3)
        return container

    def _draw_hint_pegs(self, parent: tk.Misc, exact: int, misplaced: int) -> tk.Canvas:
        """用高对比度的实心/空心圆表达反馈，不泄露对应位置。"""
        # 浅灰提示底板让白色圆点不会与记录区白底融合。
        canvas = tk.Canvas(parent, width=58, height=38, highlightthickness=0, bg="#d9dde3")
        pegs = ["exact"] * exact + ["misplaced"] * misplaced
        for index, peg in enumerate(pegs[:6]):
            column, row = index % 3, index // 3
            x, y = 11 + column * 18, 11 + row * 16
            if peg == "exact":
                canvas.create_oval(x - 6, y - 6, x + 6, y + 6, fill="#20222b", outline="#20222b")
            else:
                canvas.create_oval(x - 6, y - 6, x + 6, y + 6, fill="#ffffff", outline="#374151", width=2)
        return canvas

    def _elapsed_text(self) -> str:
        seconds = int(time.monotonic() - self.started_at)
        return f"{seconds // 60:02d}:{seconds % 60:02d}"

    def _seconds_left(self) -> int:
        return 0 if self.deadline is None else max(0, int(self.deadline - time.monotonic() + 0.999))

    def _refresh_timer(self) -> None:
        if self.game_mode == "限时挑战" and not self.game_over and self._seconds_left() <= 0:
            self.game_over = True
            self.progress.best_timed_score = max(self.progress.best_timed_score, self.score)
            badges = unlock_new_badges(self.progress)
            self.progress_store.save(self.progress)
            self._render_all()
            suffix = "\n\n新成就：" + "、".join(BADGES[badge][0] for badge in badges) if badges else ""
            messagebox.showinfo("时间到", f"本次限时挑战结束！得分：{self.score} 分。{suffix}")
        elif not self.game_over:
            self._render_status()
        self.after(500, self._refresh_timer)

    def _show_first_time_tutorial(self) -> None:
        if not self.progress.tutorial_seen:
            self.progress.tutorial_seen = True
            self.progress_store.save(self.progress)
            self.open_tutorial()

    def open_tutorial(self) -> None:
        pages = [
            ("第 1 步：明确目标", "机器已经藏好一串颜色。\n每轮选满所有空位后提交，尽量用更少次数破解它。"),
            ("第 2 步：读懂提示", "● 实心点表示颜色和位置都正确。\n○ 空心点表示颜色正确，但所在位置需要调整。"),
            ("第 3 步：开始推理", "先用不同颜色测试范围，再交换位置确认顺序。\n你不需要靠运气，每一轮都应带来新信息。"),
        ]
        dialog = tk.Toplevel(self)
        dialog.title("密码机 · 玩法教学")
        dialog.configure(bg="#f7f7f5")
        dialog.resizable(False, False)
        dialog.transient(self)
        dialog.grab_set()
        page_index = tk.IntVar(value=0)
        content = tk.Frame(dialog, bg="#f7f7f5", padx=28, pady=24)
        content.pack(fill="both", expand=True)

        def render_page() -> None:
            for child in content.winfo_children():
                child.destroy()
            title, body = pages[page_index.get()]
            tk.Label(content, text=title, bg="#f7f7f5", fg="#22223b", font=("Microsoft YaHei", 17, "bold")).pack(anchor="w")
            tk.Label(content, text=body, bg="#f7f7f5", fg="#4b5563", justify="left", font=("Microsoft YaHei", 11), pady=12).pack(anchor="w")
            sample = tk.Frame(content, bg="#ffffff", padx=16, pady=14, highlightbackground="#d9d9df", highlightthickness=1)
            sample.pack(fill="x", pady=(4, 16))
            if page_index.get() == 0:
                tk.Label(sample, text="示例密码位", bg="#ffffff", fg="#6b7280", font=("Microsoft YaHei", 10)).pack(anchor="w")
                self._draw_color_cells(sample, [0, 1, 2], small=False).pack(anchor="w", pady=(8, 0))
            elif page_index.get() == 1:
                tk.Label(sample, text="一轮猜测的反馈示例", bg="#ffffff", fg="#6b7280", font=("Microsoft YaHei", 10)).pack(anchor="w")
                sample_row = tk.Frame(sample, bg="#ffffff", pady=8)
                sample_row.pack(fill="x")
                self._draw_color_cells(sample_row, [0, 1, 2, 3], small=True).pack(side="left")
                self._draw_hint_pegs(sample_row, 1, 2).pack(side="right")
            else:
                tk.Label(sample, text="推荐的第一轮", bg="#ffffff", fg="#6b7280", font=("Microsoft YaHei", 10)).pack(anchor="w")
                self._draw_color_cells(sample, [0, 1, 2, 3], small=True).pack(anchor="w", pady=(8, 0))

            actions = tk.Frame(content, bg="#f7f7f5")
            actions.pack(fill="x", pady=(8, 0))
            previous = self._button(actions, "上一步", lambda: change_page(-1))
            previous.pack(side="left")
            previous.configure(state="disabled" if page_index.get() == 0 else "normal")
            label = "开始游戏" if page_index.get() == len(pages) - 1 else "下一步"
            self._button(actions, label, lambda: dialog.destroy() if page_index.get() == len(pages) - 1 else change_page(1), primary=True).pack(side="right")

        def change_page(delta: int) -> None:
            page_index.set(max(0, min(len(pages) - 1, page_index.get() + delta)))
            render_page()

        render_page()

    def open_records(self) -> None:
        dialog = tk.Toplevel(self)
        dialog.title("我的记录与成就")
        dialog.configure(bg="#f7f7f5")
        dialog.resizable(False, False)
        dialog.transient(self)

        panel = tk.Frame(dialog, bg="#f7f7f5", padx=26, pady=22)
        panel.pack(fill="both", expand=True)
        tk.Label(panel, text="我的记录", bg="#f7f7f5", fg="#22223b", font=("Microsoft YaHei", 18, "bold")).pack(anchor="w")
        summary = tk.Frame(panel, bg="#ffffff", padx=16, pady=12, highlightbackground="#d9d9df", highlightthickness=1)
        summary.pack(fill="x", pady=(12, 16))
        tk.Label(summary, text=f"最高闯关：第 {self.progress.highest_level} 关", bg="#ffffff", fg="#22223b", font=("Microsoft YaHei", 11, "bold")).pack(anchor="w")
        tk.Label(summary, text=f"限时最高分：{self.progress.best_timed_score} 分", bg="#ffffff", fg="#22223b", font=("Microsoft YaHei", 11, "bold")).pack(anchor="w", pady=5)
        tk.Label(summary, text=f"累计破解：{self.progress.total_wins} 题", bg="#ffffff", fg="#22223b", font=("Microsoft YaHei", 11, "bold")).pack(anchor="w")

        tk.Label(panel, text="成就", bg="#f7f7f5", fg="#22223b", font=("Microsoft YaHei", 13, "bold")).pack(anchor="w")
        for badge, (name, description) in BADGES.items():
            unlocked = badge in self.progress.unlocked_badges
            row = tk.Frame(panel, bg="#ffffff" if unlocked else "#eeeeef", padx=12, pady=9)
            row.pack(fill="x", pady=3)
            marker = "✓" if unlocked else "○"
            tk.Label(row, text=marker, width=2, bg=row.cget("bg"), fg="#2a9d8f" if unlocked else "#9ca3af", font=("Microsoft YaHei", 12, "bold")).pack(side="left")
            tk.Label(row, text=name, width=9, anchor="w", bg=row.cget("bg"), fg="#22223b" if unlocked else "#6b7280", font=("Microsoft YaHei", 10, "bold")).pack(side="left")
            tk.Label(row, text=description, bg=row.cget("bg"), fg="#4b5563", font=("Microsoft YaHei", 10)).pack(side="left")
        self._button(panel, "关闭", dialog.destroy, primary=True).pack(anchor="e", pady=(16, 0))

    def open_settings(self) -> None:
        dialog = tk.Toplevel(self)
        dialog.title("自定义难度")
        dialog.configure(bg="#f7f7f5")
        dialog.resizable(False, False)
        dialog.transient(self)
        dialog.grab_set()
        tk.Label(dialog, text="自定义难度", font=("Microsoft YaHei", 16, "bold"), bg="#f7f7f5", fg="#22223b").grid(row=0, column=0, columnspan=2, padx=24, pady=(20, 12), sticky="w")
        tk.Label(dialog, text="修改后会开始新游戏。", font=("Microsoft YaHei", 9), bg="#f7f7f5", fg="#6b7280").grid(row=1, column=0, columnspan=2, padx=24, pady=(0, 12), sticky="w")
        values = [
            ("密码位数", self.base_config.code_length, 3, 6),
            ("可用颜色数", self.base_config.color_count, 4, len(PALETTE)),
            ("猜测机会数", self.base_config.max_attempts, 5, 15),
            ("限时模式时长（秒）", self.time_limit, 30, 300),
        ]
        variables: list[tk.IntVar] = []
        for row, (label, current, minimum, maximum) in enumerate(values, start=2):
            tk.Label(dialog, text=label, bg="#f7f7f5", font=("Microsoft YaHei", 10)).grid(row=row, column=0, padx=24, pady=7, sticky="w")
            variable = tk.IntVar(value=current)
            variables.append(variable)
            tk.Spinbox(dialog, from_=minimum, to=maximum, textvariable=variable, width=7, font=("Microsoft YaHei", 10)).grid(row=row, column=1, padx=(0, 24), pady=7)

        def save_settings() -> None:
            length, colors, attempts, time_limit = (variable.get() for variable in variables)
            if colors < length:
                messagebox.showwarning("参数不合适", "可用颜色数建议不小于密码位数。", parent=dialog)
                return
            self.preset_var.set("自定义")
            self.time_limit = time_limit
            self.start_game(GameConfig(length, colors, attempts))
            dialog.destroy()

        actions = tk.Frame(dialog, bg="#f7f7f5")
        actions.grid(row=6, column=0, columnspan=2, padx=24, pady=20, sticky="e")
        self._button(actions, "取消", dialog.destroy).pack(side="left", padx=6)
        self._button(actions, "开始新游戏", save_settings, primary=True).pack(side="left")

    def _on_close(self) -> None:
        self.progress_store.save(self.progress)
        self.destroy()


if __name__ == "__main__":
    PasswordMachineApp().mainloop()
