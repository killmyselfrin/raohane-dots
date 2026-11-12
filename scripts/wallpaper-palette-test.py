#!/usr/bin/env python3
"""Exercise the real palette CLI with generated wallpaper fixtures."""
import colorsys
import subprocess
import sys
import tempfile
from pathlib import Path
from PIL import Image, ImageDraw

script = Path(__file__).with_name('wallpaper-palette.py')
with tempfile.TemporaryDirectory() as directory:
    path = Path(directory) / 'wallpaper.png'
    for color in ('#808080', '#ffffff', '#000000', '#ff0000', '#00ff00', '#0000ff'):
        Image.new('RGB', (96, 96), color).save(path)
        result = subprocess.run([sys.executable, str(script), '--dual', str(path)],
                                capture_output=True, text=True, check=True)
        pair = result.stdout.split()
        assert len(pair) == 2
        rgb = tuple(int(pair[0][i:i+2], 16) / 255 for i in (1, 3, 5))
        hue, saturation, _ = colorsys.rgb_to_hsv(*rgb)
        expected = Image.new('RGB', (1, 1), color).getpixel((0, 0))
        eh, es, _ = colorsys.rgb_to_hsv(*(x / 255 for x in expected))
        assert saturation < .01 if es == 0 else abs(hue - eh) < .01, (color, pair)
    # Small saturated decorations must not dominate the surrounding wallpaper.
    image = Image.new('RGB', (96, 96), '#808080')
    ImageDraw.Draw(image).rectangle((0, 0, 8, 8), fill='#ff0000')
    image.save(path)
    result = subprocess.check_output([sys.executable, str(script), str(path)], text=True).strip()
    assert result == '#808080', result
    assert subprocess.run([sys.executable, str(script), str(path.with_name('missing.png'))],
                          capture_output=True).returncode == 2
print('wallpaper-palette-test: neutral, saturated, area dominance and missing-file cases pass')
