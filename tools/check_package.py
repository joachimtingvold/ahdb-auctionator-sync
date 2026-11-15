"""Check the actual BigWigs ZIP before publishing (standard library only)."""
import os
from pathlib import Path
import zipfile

archives = list(Path(".release").glob("*.zip"))
assert len(archives) == 1, f"Expected one package, found {archives}"
with zipfile.ZipFile(archives[0]) as archive:
    files = {name for name in archive.namelist() if not name.endswith("/")}
    prefix = "AHDBAuctionatorSync/"
    required = {prefix + name for name in (
        "AHDBAuctionatorSync.lua", "AHDBAuctionatorSync.toc", "LICENSE",
        "README.md", "CHANGELOG.md",
    )}
    assert required <= files, f"Missing addon files: {required - files}"
    assert all(name.startswith(prefix) and ".." not in name.split("/") for name in files)
    assert not any(part in {".github", "tests", "tools", "docs", ".git"}
                   for name in files for part in name.split("/")), files
    toc = archive.read(prefix + "AHDBAuctionatorSync.toc").decode()
    assert "@project-version@" not in toc, "Version token was not replaced"
    assert "## Interface: 16001" in toc
    assert "## Dependencies: AuctionDB, Auctionator" in toc
    expected = os.environ.get("EXPECTED_VERSION")
    if expected:
        version = next(line.split(":", 1)[1].strip() for line in toc.splitlines()
                       if line.startswith("## Version:"))
        assert version.removeprefix("v") == expected.removeprefix("v"), version
    assert archive.read(prefix + "AHDBAuctionatorSync.lua").replace(b"\r\n", b"\n") == Path(
        "AHDBAuctionatorSync.lua").read_bytes().replace(b"\r\n", b"\n"), "Addon code changed during packaging"
    assert archive.read(prefix + "CHANGELOG.md").replace(b"\r\n", b"\n") == Path(
        "CHANGELOG.md").read_bytes().replace(b"\r\n", b"\n"), "Changelog differs"
print(f"PASS: {archives[0]} contains an installable Forever addon and changelog")
