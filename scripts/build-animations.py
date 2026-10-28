#!/usr/bin/env python3
"""Собирает niri/cfg/animations.kdl из шаблона и шейдеров shaders/*.frag.

niri 26.04 не умеет `custom-shader path=...`, шейдер нужно вписывать строкой.
Правьте shaders/*.frag и niri/animations.kdl.in, затем:

    python3 -I scripts/build-animations.py && niri validate
"""
import re
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
template = (REPO / "niri" / "animations.kdl.in").read_text()


def shader(match):
    name = match.group(1)
    src = (REPO / "shaders" / f"{name}.frag").read_text()
    if '"#' in src:
        raise SystemExit(f"{name}.frag: последовательность '\"#' сломает raw-строку KDL")
    return 'custom-shader r#"\n' + src.rstrip() + '\n"#'


out = re.sub(r"@shader\((\w+)\)", shader, template)
header = "// СГЕНЕРИРОВАНО scripts/build-animations.py из niri/animations.kdl.in и shaders/*.frag.\n// Не править вручную.\n\n"
(REPO / "niri" / "cfg" / "animations.kdl").write_text(header + out)
print("niri/cfg/animations.kdl")
