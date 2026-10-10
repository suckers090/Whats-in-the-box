"""Run the real Lua slice function against exported garage mesh bounds, without Roblox.
Usage: python tests/garage_shutter.py /path/to/luau
"""
import re
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = (root / "src/ServerScriptService/WarehouseDoors.server.luau").read_text()
match = re.search(r"local function shutterSlice\(.*?\nend", source, re.S)
assert match, "Missing tested shutter geometry function"
place = ET.parse(root / "backups/Whats-in-the-box-v1-positioned-markers.rbxlx")
panel = next(item for item in place.iter("Item")
             if item.find("Properties/*[@name='Name']") is not None
             and item.find("Properties/*[@name='Name']").text == "GarageDoor_Panel")
parts = [panel] + list(panel.iter("Item"))[1:]
panel_y = float(panel.find("Properties/*[@name='CFrame']/Y").text)
fixtures = []
for item in parts:
    if item.get("class") not in ("MeshPart", "Part"):
        continue
    props = item.find("Properties")
    height = float(props.find("*[@name='size']/Y").text)
    frame = props.find("*[@name='CFrame']")
    assert all(abs(float(frame.find(key).text) - expected) < 1e-6
               for key, expected in (("R00", 1), ("R11", 1), ("R22", 1),
                                     ("R01", 0), ("R02", 0), ("R10", 0),
                                     ("R12", 0), ("R20", 0), ("R21", 0))), "Fixture requires aligned meshes"
    fixtures.append((float(frame.find("Y").text) - panel_y, height))
assert len(fixtures) == 15, "Expected solid panel and 14 decorative slats"
header = max(y + height / 2 for y, height in fixtures)
bottom = min(y - height / 2 for y, height in fixtures)
rows = ",\n".join("{%r, %r}" % row for row in fixtures)
test = match.group() + f"\nlocal parts = {{{rows}}}\nlocal header = {header!r}\nlocal bottom = {bottom!r}\n" + """
for _, part in ipairs(parts) do
    local previousHeight = part[2]
    for step = 0, 200 do
        local alpha = step / 200
        local travel = (header - bottom) * alpha
        local height, center = shutterSlice(part[1] + travel, part[2], header)
        assert(height >= 0 and height <= part[2] + 1e-6)
        assert(height <= previousHeight + 1e-6, "Opening must retract continuously")
        if height > 0.05 then
            assert(center + height / 2 <= header + 1e-6, "Visible geometry crossed header")
        end
        if step == 0 then
            assert(math.abs(height - part[2]) < 1e-6, "Closed dimensions not preserved")
            assert(math.abs(center - part[1]) < 1e-6, "Closed placement not preserved")
        elseif step == 200 then
            assert(height <= 0.05, "Open shutter must hide every mesh")
        end
        previousHeight = height
    end
    local previousClosedHeight = 0
    for step = 200, 0, -1 do
        local height = shutterSlice(part[1] + (header - bottom) * step / 200, part[2], header)
        assert(height >= previousClosedHeight - 1e-6, "Closing must restore geometry continuously")
        previousClosedHeight = height
    end
end
print("PASS: panel and 14 slats stay below header, fully hide, and restore through open/close cycles")
"""
collision_match = re.search(r"local function setCollision\(enabled\).*?\n\tend(?=\n\tsetCollision\(true\))", source, re.S)
assert collision_match
# Exercise the actual collision function with part-property doubles; this is not an engine test.
test += "\nlocal garage = true\nlocal panel = {}\nlocal child = {}\nlocal parts = {panel, child}\nlocal originals = {[panel] = {CanTouch = true, CanQuery = true}, [child] = {CanTouch = false, CanQuery = true}}\n"
test += collision_match.group() + "\n" + """
setCollision(false)
for _, part in ipairs(parts) do
    assert(part.CanCollide == false and part.CanTouch == false and part.CanQuery == false,
        "Open/moving garage meshes must not obstruct or be query targets")
end
setCollision(true)
assert(panel.CanCollide == true and child.CanCollide == false)
assert(panel.CanTouch == true and child.CanTouch == false)
assert(panel.CanQuery == true and child.CanQuery == true)
print("PASS: actual collision function clears all open garage meshes and restores closed settings")
"""
with tempfile.TemporaryDirectory(prefix="witb-shutter-") as directory:
    path = Path(directory) / "shutter-test.luau"
    path.write_text(test)
    subprocess.run([sys.argv[1] if len(sys.argv) > 1 else "luau", str(path)], check=True)
