"""Build the .love archive; bundle the installed Windows LÖVE runtime when available."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile

root = Path(__file__).resolve().parents[1]
build = root / "build"
build.mkdir(exist_ok=True)
archive = build / "Arrowfallen.love"
with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as package:
    for name in ("main.lua", "conf.lua", "README.md"):
        package.write(root / name, name)
    for folder in ("src", "vendor", "tests", "docs", "assets"):
        for path in sorted((root / folder).rglob("*")):
            if path.is_file():
                package.write(path, path.relative_to(root).as_posix())
with zipfile.ZipFile(archive) as package:
    assert package.testzip() is None
    assert {"main.lua", "conf.lua", "vendor/concord/init.lua", "vendor/versions.json"} <= set(package.namelist())
    assert len([name for name in package.namelist() if name.startswith("assets/audio/") and name.endswith(".wav")]) == 8

runtime = Path("C:/Program Files/LOVE")
if (runtime / "love.exe").is_file():
    windows = build / "Windows"
    windows.mkdir(exist_ok=True)
    # Keep the runtime unchanged so Windows application control can recognize it.
    shutil.copy2(runtime / "love.exe", windows / "love.exe")
    shutil.copy2(archive, windows / archive.name)
    (windows / "Jogar.bat").write_text(
        '@echo off\nstart "" "%~dp0love.exe" "%~dp0Arrowfallen.love"\n', encoding="ascii"
    )
    old_executable = windows / "Arrowfallen.exe"
    if old_executable.is_file():
        old_executable.unlink()
    assert (windows / "love.exe").read_bytes() == (runtime / "love.exe").read_bytes()
    for path in runtime.glob("*.dll"):
        shutil.copy2(path, windows / path.name)
    shutil.copy2(runtime / "license.txt", windows / "LOVE-LICENSE.txt")
    shutil.copy2(root / "README.md", windows / "README.md")

(build / "manifest.json").write_text(json.dumps({
    "archive": archive.name, "sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
    "love": "11.5", "dependencies": json.loads((root / "vendor/versions.json").read_text())
}, indent=2) + "\n", encoding="utf-8")
print(archive)
print("Archive verified; Windows runtime bundled when installed.")
