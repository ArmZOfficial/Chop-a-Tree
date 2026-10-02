"""Run actual map Luau modules against deterministic boundary mocks; never opens Roblox profiles.
Usage: python tools/tests/run_map_systems.py --luau PATH_TO_LUAU_EXE
"""
import argparse
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
SHARED = "ReplicatedStorage.Shared."
SERVER = "ServerScriptService.Server."

def read(name):
    return (ROOT / name).read_text(encoding="utf-8")

def module(path, source):
    return f'register("{path}",function()\nlocal script=node("{path}")\n{source}\nend)\n'

def build():
    out = [read("tools/tests/MapSystemsMocks.luau")]
    for name in ["Config/Zones", "ZoneUtil", "MapMigration", "Config/Explorer", "Config/DayCycle", "Config/WorldEvents", "Config/Forest", "Config/Story", "Config/Weather", "Config/WeatherEncounters", "EncounterMath", "Config/BalanceConfig", "Balance", "Config/Currencies", "Config/LegacyWeaponMap"]:
        out.append(module(SHARED + name.replace("/", "."), read(f"src/shared/{name}.luau")))
    data = read("src/server/Services/DataService.luau")
    # Execute the REAL template/migrations/reconcile code, excluding ProfileStore.New and every live API.
    pure = data[:data.index("local store = ProfileStore.New")]
    pure += data[data.index("local function deepCopy"):data.index("local function splitPath")]
    out.append(module(SERVER + "Services.DataService", pure + "\nreturn DataService"))
    out.append('''
Data=require(node("ServerScriptService.Server.Services.DataService"))
function Data.IsLoaded(p) return p.data~=nil end
function Data.GetData(p) return p.data end
function Data.Get(p,path) local v=p.data;for k in path:gmatch("[^.]+") do v=type(v)=="table" and v[k] or nil end;return v end
function Data.Set(p,path,value) local parts=path:split(".");local v=p.data;for i=1,#parts-1 do v=v[parts[i]] end;v[parts[#parts]]=value end
function Data.Increment(p,path,n) Data.Set(p,path,(Data.Get(p,path) or 0)+n) end
function Data.AddCurrency(p,key,n) Data.Increment(p,"Currencies."..key,n) end
local function fixture(p) p.data=Data.Migrate({DataVersion=2});return p end
''')
    for name in ["Services/RunService", "Services/TreeService", "Services/ZoneService", "Services/GateService", "Services/ExplorerService", "Services/TravelService", "Services/WorldEventService", "Services/WeatherEncounterService", "AdminCommands/MapMigrationCheck"]:
        out.append(module(SERVER + name.replace("/", "."), read(f"src/server/{name}.luau")))
    out.append(read("tools/tests/MapSystemsAssertions.luau"))
    return "\n".join(out)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--luau", required=True)
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="map-systems-test-") as directory:
        target = Path(directory) / "test.luau"
        target.write_text(build(), encoding="utf-8")
        result = subprocess.run([args.luau, str(target)], text=True, capture_output=True)
        print(result.stdout, end="")
        print(result.stderr, end="")
        raise SystemExit(result.returncode)
