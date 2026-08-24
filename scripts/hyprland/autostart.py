#!/usr/bin/env python3
import json, subprocess, time, os

lockfile = "/tmp/qs-autostart.lock"
if os.path.exists(lockfile):
    exit(0)
open(lockfile, 'w').close()

config_home = os.environ.get("XDG_CONFIG_HOME", os.path.join(os.environ["HOME"], ".config"))
with open(os.path.join(config_home, "raohane", "config.json")) as f:
    data = json.load(f)

autostart = data.get('hyprland', {}).get('autostartApps', {})
if not autostart.get('enable', False):
    exit(0)

for app in autostart.get('apps', []):
    cmd = app.get('cmd', '').strip()
    workspace = app.get('workspace', 1)
    delay = app.get('delay', 0)
    if not cmd:
        continue

    subprocess.run(['hyprctl', 'dispatch', f'hl.dsp.focus({{workspace = {workspace}}})'])

    expanded_cmd = os.path.expanduser(cmd)
    subprocess.Popen(
        ['hyprctl', 'dispatch', f'hl.dsp.exec_cmd("{expanded_cmd}")'],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        close_fds=True
    )

    time.sleep(delay)