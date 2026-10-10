"""Test actual plot-event adapter with a copying event double, outside Roblox."""
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "src/ServerScriptService/PlotRegistry.luau").read_text()
assert "added:Fire(player)" in source and "added:Fire(plot)" not in source
adapter = source[source.index("local added ="):source.index("function registry.Assign")]
prefix = 'local handlers = {}\nlocal signal = {Connect = function(_, callback)\n table.insert(handlers, callback)\n return {Disconnect = function() end}\nend}\nlocal event = {Event = signal}\nfunction event:Fire(arg)\n -- Model the table copy at a BindableEvent boundary.\n local delivered = type(arg) == "table" and table.clone(arg) or arg\n for _, callback in ipairs(handlers) do callback(delivered) end\nend\nlocal Instance = {new = function() return event end}\n'
checks = '-- An opaque value stands in for a Player Instance; it must survive the event.\nlocal owner = "PlayerInstance"\nlocal plot = {Owner = owner, Prizes = {}}\nplots[owner] = plot\nlocal received\nregistry.Added:Connect(function(value)\n received = value\n value.PurchaseScanner = function() return "purchase" end\nend)\nadded:Fire(owner)\nassert(received == registry.Get(owner), "Subscriber must receive the original plot")\nassert(plot.PurchaseScanner() == "purchase", "Callback mutation must reach registry")\nlocal box = {}\nplot.Prizes[box] = {value = 650}\nassert(received.Prizes[box].value == 650, "Scanner must share future package prizes")\nplots[owner] = nil\nreceived = nil\nadded:Fire(owner)\nassert(received == nil, "Released plots must not initialize")\nprint("PASS: plot identity, purchase callback, shared prizes and released plot events")\n'
with tempfile.TemporaryDirectory() as directory:
    driver = Path(directory) / "plot_event.luau"
    driver.write_text(prefix + adapter + checks)
    subprocess.run([sys.argv[1], str(driver)], check=True)
