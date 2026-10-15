#!/usr/bin/env python3
"""Regression checks for Raohane's compositor entry/exit motion.

Pure Python: does not start Hyprland, write config files or use a GPU.
"""
from __future__ import annotations

import importlib.util
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "scripts" / "hyprland-sync.py"
SPEC = importlib.util.spec_from_file_location("raohane_hyprland_sync", SOURCE)
assert SPEC is not None and SPEC.loader is not None
motion = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(motion)


class MotionAudit(unittest.TestCase):
    def setUp(self) -> None:
        self.cfg = motion.animations_from({
            "animations": {
                "enabled": True, "windowMs": 260, "layerMs": 235,
                "fadeMs": 185, "workspaceMs": 290, "workspaceDistance": 12,
            }
        })

    def test_lua_and_legacy_explicitly_define_entry_and_exit(self) -> None:
        lua = "\n".join(motion.lua_animation_lines(self.cfg))
        legacy = "\n".join(motion.legacy_animation_lines(self.cfg))
        for leaf in ("windowsIn", "windowsOut", "layersIn", "layersOut", "fadeIn", "fadeOut"):
            self.assertIn(f'leaf = "{leaf}"', lua, leaf)
            self.assertIn(f"animation = {leaf}, 1,", legacy, leaf)
        self.assertIn('style = "popin 92%"', lua)
        self.assertIn('style = "popin 96%"', lua)
        self.assertIn('style = "fade"', lua)
        self.assertIn("popin 92%", legacy)
        self.assertIn("popin 96%", legacy)

    def test_exit_is_faster_for_every_surface(self) -> None:
        t = motion.motion_phase_speeds(self.cfg)
        for opening, closing in (
            ("window", "windowOut"),
            ("layer", "layerOut"),
            ("fade", "fadeOut"),
        ):
            self.assertLess(float(t[closing]), float(t[opening]))
        for renderer in (motion.lua_animation_lines, motion.legacy_animation_lines):
            output = "\n".join(renderer(self.cfg))
            for tname in ("windowOut", "layerOut", "fadeOut"):
                self.assertIn(t[tname], output)

    def test_off_profile_does_not_emit_reenabled_child_animations(self) -> None:
        off = dict(self.cfg, enabled=False)
        lua = "\n".join(motion.lua_animation_lines(off))
        legacy = "\n".join(motion.legacy_animation_lines(off))
        self.assertIn("enabled = false", lua)
        self.assertIn("enabled = false", legacy)
        for leaf in ("windowsIn", "windowsOut", "layersIn", "layersOut"):
            self.assertNotIn(leaf, lua)
            self.assertNotIn(leaf, legacy)

    def test_short_duration_floor_and_legacy_consistency(self) -> None:
        cfg = motion.animations_from({
            "animations": {
                "enabled": True, "windowMs": 80, "layerMs": 80, "fadeMs": 60
            }
        })
        t = motion.motion_phase_speeds(cfg)
        self.assertGreaterEqual(float(t["windowOut"]), 0.6)
        self.assertGreaterEqual(float(t["layerOut"]), 0.6)
        self.assertGreaterEqual(float(t["fadeOut"]), 0.5)
        for opening, closing in (("window", "windowOut"), ("layer", "layerOut"), ("fade", "fadeOut")):
            self.assertLess(float(t[closing]), float(t[opening]))
        lua = "\n".join(motion.lua_animation_lines(cfg))
        legacy = "\n".join(motion.legacy_animation_lines(cfg))
        for key in ("windowOut", "layerOut", "fadeOut"):
            self.assertIn(t[key], lua)
            self.assertIn(t[key], legacy)

    def test_workspace_distance_and_persisted_settings_stay_intact(self) -> None:
        lua = "\n".join(motion.lua_animation_lines(self.cfg))
        legacy = "\n".join(motion.legacy_animation_lines(self.cfg))
        self.assertIn("slidefade 12%", lua)
        self.assertIn("slidefade 12%", legacy)
        self.assertEqual(self.cfg["windowMs"], 260)
        self.assertEqual(self.cfg["layerMs"], 235)


if __name__ == "__main__":
    unittest.main(verbosity=2)
