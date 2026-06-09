#!/usr/bin/env python3
"""
RamOS Settings GUI
Tkinter GUI for RamOS settings.
Shows autoupdate status and allows toggling it.
"""

import os
import shutil
import subprocess
import tkinter as tk
from tkinter import filedialog, messagebox, ttk

# -------------------- Paths --------------------
HOME = os.path.expanduser("~")
CONFIG_DIR = os.path.join(HOME, ".config", "RamOS")
WALLPAPER_DIR = os.path.join(CONFIG_DIR, "Wallpapers")

WALLPAPER = os.path.join(WALLPAPER_DIR, "wallpaper.png")
LOCKSCREEN = os.path.join(WALLPAPER_DIR, "lockscreen.png")

PDF_PATH = os.path.join(CONFIG_DIR, "RamOS.pdf")
UPDATE_FILE = os.path.join(CONFIG_DIR, "update")
BACKUP_DIR = os.path.join(HOME, ".local", "share", "ramos_backups")

WLRLUI_PATH = os.path.expanduser("~/.local/bin/wlr-layout-ui/myenv/bin/wlrlui")
NWG_PATH = "/usr/bin/nwg-look"

os.makedirs(WALLPAPER_DIR, exist_ok=True)
os.makedirs(BACKUP_DIR, exist_ok=True)


# -------------------- Desktop Entry --------------------
def create_desktop_entry():
    desktop_dir = os.path.join(HOME, ".local", "share", "applications")
    os.makedirs(desktop_dir, exist_ok=True)

    desktop_file = os.path.join(desktop_dir, "ramos-settings.desktop")

    content = f"""[Desktop Entry]
Name=RamOS Settings
Comment=Configure RamOS settings
Exec=python3.14 {os.path.abspath(__file__)}
Icon=preferences-system
Terminal=false
Type=Application
Categories=Utility;Settings;
StartupNotify=true
"""

    if not os.path.exists(desktop_file):
        with open(desktop_file, "w") as f:
            f.write(content)
        os.chmod(desktop_file, 0o644)


create_desktop_entry()

# -------------------- Utility Functions --------------------


def get_autoupdate_status():
    if not os.path.exists(UPDATE_FILE):
        return "Unknown"

    with open(UPDATE_FILE) as f:
        for line in f:
            if line.strip().startswith("autoupdate"):
                if "true" in line:
                    return "ON"
                else:
                    return "OFF"
    return "Unknown"


def update_autoupdate_label():
    status = get_autoupdate_status()
    autoupdate_var.set(f"Autoupdate: {status}")


def backup_file(path):
    if os.path.exists(path):
        shutil.copy2(path, os.path.join(BACKUP_DIR, os.path.basename(path)))


def set_image(target):

    file_path = filedialog.askopenfilename(
        title="Select image",
        initialdir=HOME,
        filetypes=[("Images", "*.png *.jpg *.jpeg *.webp"), ("All files", "*")],
    )

    if not file_path:
        return

    backup_file(target)
    shutil.copy2(file_path, target)

    messagebox.showinfo("Success", f"Set {os.path.basename(target)}")


def revert_image(filename):

    backup = os.path.join(BACKUP_DIR, filename)
    target = os.path.join(WALLPAPER_DIR, filename)

    if not os.path.exists(backup):
        messagebox.showerror("Error", "No backup found")
        return

    shutil.copy2(backup, target)
    messagebox.showinfo("Reverted", f"Reverted {filename}")


def toggle_autoupdate():

    if not os.path.exists(UPDATE_FILE):
        messagebox.showerror("Error", "Update file not found")
        return

    with open(UPDATE_FILE, "r") as f:
        lines = f.readlines()

    new_lines = []

    for line in lines:
        if line.strip().startswith("autoupdate"):
            if "true" in line:
                new_lines.append("autoupdate = false\n")
            else:
                new_lines.append("autoupdate = true\n")
        else:
            new_lines.append(line)

    with open(UPDATE_FILE, "w") as f:
        f.writelines(new_lines)

    update_autoupdate_label()


def open_manual():

    if not os.path.exists(PDF_PATH):
        messagebox.showerror("Error", "RamOS.pdf not found")
        return

    browser = shutil.which("LibreWolf.AppImage") or shutil.which("librewolf")

    if not browser:
        messagebox.showerror("Error", "LibreWolf not found in PATH")
        return

    subprocess.Popen([browser, PDF_PATH])


def open_flatseal():

    flatseal = shutil.which("flatpak")

    if not flatseal:
        messagebox.showerror("Error", "Flatpak not found in PATH")
        return

    subprocess.Popen([flatseal, "run", "com.github.tchx84.Flatseal"])


def open_pulsemixer():

    terminal = (
        shutil.which("foot")
        or shutil.which("st")
        or shutil.which("kitty")
        or shutil.which("alacritty")
        or shutil.which("gnome-terminal")
        or shutil.which("xterm")
    )

    if not terminal:
        messagebox.showerror("Error", "No supported terminal found")
        return

    subprocess.Popen([terminal, "-e", "pulsemixer"])


def open_wlrlui():

    if not os.path.exists(WLRLUI_PATH):
        messagebox.showerror("Error", f"wlrlui not found at {WLRLUI_PATH}")
        return

    subprocess.Popen([WLRLUI_PATH])


def open_nwg():

    if not os.path.exists(NWG_PATH):
        messagebox.showerror("Error", f"nwg-look not found at {NWG_PATH}")
        return

    subprocess.Popen([NWG_PATH])


# -------------------- GUI Styling --------------------
BG = "#1e1e1e"
FG = "#eeeeee"
ACCENT = "#3584e4"
BTN_BG = "#2b2b2b"
BTN_HOVER = "#3a3a3a"

root = tk.Tk()
root.title("RamOS Settings")
root.geometry("420x580")
root.resizable(False, False)
root.configure(bg=BG)

style = ttk.Style()
style.theme_use("clam")

style.configure(".", background=BG, foreground=FG, font=("Cantarell", 11))
style.configure("Card.TFrame", background=BG)

style.configure(
    "Title.TLabel",
    font=("Cantarell", 16, "bold"),
    background=BG,
    foreground=FG,
)

style.configure(
    "Adw.TButton",
    background=BTN_BG,
    foreground=FG,
    padding=(12, 8),
    borderwidth=0,
)

style.map(
    "Adw.TButton",
    background=[("active", BTN_HOVER)],
)

style.configure("Accent.TButton", background=ACCENT, foreground="white")
style.map("Accent.TButton", background=[("active", "#4a90e2")])

# -------------------- Layout --------------------
frame = ttk.Frame(root, style="Card.TFrame", padding=20)
frame.pack(fill="both", expand=True)

ttk.Label(frame, text="RamOS Settings", style="Title.TLabel").pack(pady=(0, 18))

# Wallpaper
ttk.Button(
    frame,
    text="Change Wallpaper",
    style="Accent.TButton",
    command=lambda: set_image(WALLPAPER),
).pack(fill="x", pady=4)

ttk.Button(
    frame,
    text="Revert Wallpaper",
    style="Adw.TButton",
    command=lambda: revert_image("wallpaper.png"),
).pack(fill="x", pady=4)

# Lockscreen
ttk.Button(
    frame,
    text="Change Lockscreen",
    style="Accent.TButton",
    command=lambda: set_image(LOCKSCREEN),
).pack(fill="x", pady=(12, 4))

ttk.Button(
    frame,
    text="Revert Lockscreen",
    style="Adw.TButton",
    command=lambda: revert_image("lockscreen.png"),
).pack(fill="x", pady=4)

# -------------------- Autoupdate Indicator --------------------
autoupdate_var = tk.StringVar()
update_autoupdate_label()

ttk.Label(frame, textvariable=autoupdate_var).pack(pady=(18, 4))

ttk.Button(
    frame,
    text="Toggle Autoupdate",
    style="Adw.TButton",
    command=toggle_autoupdate,
).pack(fill="x", pady=4)

# Other Options
ttk.Button(
    frame, text="Open Flatseal", style="Adw.TButton", command=open_flatseal
).pack(fill="x", pady=4)
ttk.Button(
    frame, text="Open Pulsemixer", style="Adw.TButton", command=open_pulsemixer
).pack(fill="x", pady=4)
ttk.Button(frame, text="Open WLRLUI", style="Adw.TButton", command=open_wlrlui).pack(
    fill="x", pady=4
)
ttk.Button(
    frame, text="Change appearance settings", style="Adw.TButton", command=open_nwg
).pack(fill="x", pady=4)
ttk.Button(
    frame, text="Open RamOS Manual (PDF)", style="Adw.TButton", command=open_manual
).pack(fill="x", pady=(14, 4))

ttk.Button(frame, text="Exit", style="Adw.TButton", command=root.destroy).pack(
    fill="x", pady=(18, 0)
)

root.mainloop()
