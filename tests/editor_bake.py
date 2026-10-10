"""Exercise actual editor bake/clear and runtime reuse with Roblox doubles.
Does not execute Studio's plugin host or native Undo engine.
"""
import ast
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
tree = ast.parse((root / 'tests/world_visuals.py').read_text())
prefix = next(node.value.value for node in tree.body if isinstance(node, ast.Assign)
              and any(isinstance(t, ast.Name) and t.id == 'prefix' for t in node.targets)
              and isinstance(node.value, ast.Constant))
prefix = prefix.replace('local workspace={}', 'local workspace={children={}}')
prefix += r'''
Enum.Material.Asphalt='Asphalt'; Enum.Material.Grass='Grass'; Enum.Material.DiamondPlate='DiamondPlate'
Enum.Material.Plastic={Name='Plastic',isEnum=true}
Enum.PartType={Ball='Ball',Cylinder='Cylinder'}; Enum.NormalId.Left='Left'
Enum.FinishRecordingOperation={Commit='Commit',Cancel='Cancel'}
local vectorMT={__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end}
Vector3.new=function(x,y,z) return setmetatable(triple(x,y,z),vectorMT) end
local typeof=function(value)
 if type(value)=='table' and value.isEnum then return 'EnumItem' end
 if type(value)=='table' and getmetatable(value)==vectorMT then return 'Vector3' end
 return type(value)
end
frameMT.__index=function(self,key) if key=='Position' then return Vector3.new(self.X,self.Y,self.Z) end end
CFrame.new=function(x,y,z)
 if type(x)=='table' then return setmetatable(triple(x.X,x.Y,x.Z),frameMT) end
 return setmetatable(triple(x or 0,y or 0,z or 0),frameMT)
end
function methods:GetDescendants()
 local list={}; local function walk(value)
 for _,child in ipairs(value.children) do table.insert(list,child); walk(child) end end
 walk(self); return list
end
function methods:Clone()
 local value=Instance.new(self.ClassName)
 for key,property in pairs(self) do
  if key~='_parent' and key~='children' and key~='signals' and key~='Destroying' and key~='attributes' then value[key]=property end
 end
 value.attributes=table.clone(self.attributes)
 for _,child in ipairs(self.children) do child:Clone().Parent=value end
 return value
end
setmetatable(workspace,{__index=methods})
local Storage=node('ServerStorage','ServerStorage')
local running,busy=false,false
local recordCount,lastOperation=0,nil
local History={TryBeginRecording=function()
 if busy then return nil end; recordCount+=1; return 'record'..recordCount
end,FinishRecording=function(_,id,operation) lastOperation=operation end}
game.GetService=function(_,name)
 if name=='Lighting' then return Lighting elseif name=='ReplicatedStorage' then return RS
 elseif name=='ServerStorage' then return Storage elseif name=='ChangeHistoryService' then return History
 elseif name=='RunService' then return {IsRunning=function() return running end} end
 error('Unexpected service: '..name)
end
Lighting.ClockTime=14.5; Lighting.Brightness=3; Lighting.Ambient='OriginalAmbient'; Lighting.OutdoorAmbient='OriginalOutdoor'
Lighting.ExposureCompensation=0; Lighting.EnvironmentDiffuseScale=1; Lighting.EnvironmentSpecularScale=1
Lighting.GlobalShadows=true; Lighting.ShadowSoftness=0.2
local foreign=node('ColorCorrectionEffect','ArtistGrade',Lighting); foreign.Contrast=0.77
plot.Model.Name='WITB_StarterWarehousetest'; plot.Runtime:Destroy(); plot.Runtime=nil
local markers=node('Folder','WarehouseMarkers',workspace)
local plate=node('Part','Baseplate',workspace); plate.Color='OriginalGrass'; plate.Material=Enum.Material.Plastic; plate.Transparency=0
local grid=node('Texture','Texture',plate); grid.Transparency=0
local spawn=node('SpawnLocation','SpawnLocation',workspace); spawn.Color='OriginalSpawn'; spawn.Material=Enum.Material.Plastic; spawn.Transparency=0
local star=node('Decal','Star',spawn); star.Transparency=0
'''
place = ET.parse(root / 'build/Whats-in-the-box-marker-test.rbxlx')
for item in place.iter('Item'):
    props = item.find('Properties')
    if props is None or item.get('class') not in ('MeshPart', 'Part'):
        continue
    name = props.find("*[@name='Name']")
    if name is None or name.text == 'Baseplate':
        continue
    frame, size = props.find("*[@name='CFrame']"), props.find("*[@name='size']")
    xyz = [float(frame.find(k).text) for k in ('X', 'Y', 'Z')]
    dimensions = [float(size.find(k).text) for k in ('X', 'Y', 'Z')]
    parent = 'markers' if name.text in ('TruckStop', 'PackageDrop', 'ScannerLocation') else 'plot.Model'
    prefix += 'do local p=node("MeshPart",'+repr(name.text)+','+parent+'); '
    prefix += 'p.CFrame=CFrame.new('+','.join(map(str, xyz))+'); p.Size=Vector3.new('+','.join(map(str, dimensions))+'); '
    prefix += 'p.Color="OriginalMeshColor"; p.Material=Enum.Material.Plastic; p.CanCollide=true; p.Transparency=0; end\n'
prefix += 'local layout=require("./YardLayout")\nlocal facilityLayout=require("./FacilityLayout")\n'
for fn, path in [('loadVisualBuilder', 'src/ServerScriptService/WarehouseVisualBuilder.luau'),
                 ('loadExteriorBuilder', 'src/ServerScriptService/WarehouseExteriorBuilder.luau'),
                 ('loadFacility', 'src/ServerScriptService/FacilityPolish.luau'),
                 ('loadBake', 'studio-tools/VisualBake.luau')]:
    prefix += f'local function {fn}()\n'+(root / path).read_text()+'\nend\n'
prefix += r'''
local api=loadBake()(loadVisualBuilder(),loadExteriorBuilder(),layout,theme,config,loadFacility(),facilityLayout)
local count=#all
running=true; assert(not api.Bake()); assert(#all==count and recordCount==0)
running=false; busy=true; assert(not api.Bake()); assert(#all==count)
busy=false
assert(api.Bake()); assert(lastOperation=='Commit')
local backup=Storage:FindFirstChild('WITB_VisualBakeBackup')
local decor=plot.Model:FindFirstChild('WITB_BakedDecor')
local park=workspace:FindFirstChild('IndustrialParkRuntime')
assert(backup and decor and park and Lighting:GetAttribute('WITB_VisualBakeVersion')==1)
assert(#park.children==1 and decor:FindFirstChild('VisualPolish') and decor:FindFirstChild('ExteriorPolish'))
assert(grid.Transparency==1 and spawn.Transparency==1 and plate.Material=='Grass')
assert(foreign.Contrast==0.77 and plot.Model:FindFirstChild('GarageDoor_Panel').signals.DoorBusy==nil,'Editor must not bind runtime door state')
count=#all; assert(not api.Bake()); assert(#all==count and backup.Parent==Storage,'Repeated bake must retain edited scenery')
local visual=decor:FindFirstChild('VisualPolish'); visual:FindFirstChild('FloorFinish').Color='ArtistFloor'
local road=park:FindFirstChild('EstateRow_0'):FindFirstChild('RoadCenterDash'); road.Color='ArtistRoad'
Lighting.ClockTime=18.1
local atmosphere=Lighting:FindFirstChildOfClass('Atmosphere')
atmosphere.Density=0.2
count=#all; running=true; assert(not api.Polish() and #all==count); running=false
assert(api.Polish())
local facilities=decor:FindFirstChild('FacilityPolish')
local stage=Storage:FindFirstChild('WITB_FacilityBakeBackup')
assert(facilities and stage and Lighting.ClockTime==14.3 and atmosphere.Density==0.12)
assert(Lighting.Ambient.X > Lighting.Ambient.Z,'Ambient should be neutral rather than blue')
assert(foreign.Contrast==0.77,'Artist-authored grading must remain unchanged')
assert(visual.FloorFinish.Color=='ArtistFloor' and road.Color=='ArtistRoad','Additive polish must retain old edits')
facilities.ParkedDeliveryVan.CargoBody.Color='ArtistVan'
count=#all; assert(not api.Polish() and #all==count,'Repeat polish must preserve new edits')
local deletedRef=node('ObjectValue','DeletedOriginalEffect',stage.ExistingLighting); deletedRef.Value=nil
assert(api.ClearPolish())
assert(not decor:FindFirstChild('FacilityPolish') and not park.EstateRow_0:FindFirstChild('FacilityPolish'))
assert(Lighting.ClockTime==18.1 and atmosphere.Density==0.2 and visual.FloorFinish.Color=='ArtistFloor' and road.Color=='ArtistRoad','Clear only the added stage, restoring previous lighting')
assert(api.Polish()); decor.FacilityPolish.ParkedDeliveryVan.CargoBody.Color='ArtistVan'
Lighting.ClockTime=18.1
local building=plot.Model:Clone(); building.Name='RuntimeClone'; building.Parent=workspace
local runtime=node('Folder','WarehousePrototype',building)
'''
registry_source = (root / 'src/ServerScriptService/PlotRegistry.luau').read_text()
start = registry_source.index('\tlocal baked = building:FindFirstChild("WITB_BakedDecor")')
end = registry_source.index('\tlocal packages = Instance.new', start)
prefix += registry_source[start:end]
prefix += r'''
assert(not building:FindFirstChild('WITB_BakedDecor'))
assert(runtime:FindFirstChild('VisualPolish') and runtime:FindFirstChild('ExteriorPolish'),'Actual allocation must reuse the baked folders')
local runtimePlot={Model=building,Runtime=runtime,Slot=2,Markers={TruckStop=markers.TruckStop}}
local registry={Added={Connect=function() end},GetAll=function() return {runtimePlot} end}
count=#all
'''
for path in ('WarehouseVisuals.server.luau', 'WarehouseExterior.server.luau'):
    source = (root / 'src/ServerScriptService' / path).read_text()
    for original, replacement in [('require(RS:WaitForChild("VisualConfig"))', 'config'),
                                  ('require(RS:WaitForChild("UITheme"))', 'theme'),
                                  ('require(script.Parent:WaitForChild("PlotRegistry"))', 'registry'),
                                  ('require(script.Parent:WaitForChild("WarehouseVisualBuilder"))', 'loadVisualBuilder()'),
                                  ('require(script.Parent:WaitForChild("WarehouseExteriorBuilder"))', 'loadExteriorBuilder()'),
                                  ('require(script.Parent:WaitForChild("YardLayout"))', 'layout'),
                                  ('require(script.Parent:WaitForChild("FacilityPolish"))', 'loadFacility()'),
                                  ('require(script.Parent:WaitForChild("FacilityLayout"))', 'facilityLayout')]:
        source = source.replace(original, replacement)
    prefix += 'do\n'+source+'\nend\n'
checks = r'''
assert(#all==count and Lighting.ClockTime==18.1 and road.Color=='ArtistRoad','Runtime must preserve edited baked art and lighting without duplication')
assert(runtime.VisualPolish.FloorFinish.Color=='ArtistFloor')
assert(runtime.FacilityPolish.ParkedDeliveryVan.CargoBody.Color=='ArtistVan','Baked facility models must clone and retain edits')
assert(runtime.VisualPolish.DockSign.children[1].children[1].Text=='BAY 02  /  WITB','Cloned bay label must match owner slot')
local door=building:FindFirstChild('GarageDoor_Panel')
local indicator=runtime.VisualPolish:FindFirstChild('DoorStatus_GarageDoor_Panel')
door:SetAttribute('DoorBusy',true); assert(indicator.Color.X==215,'Cloned door lamp must rebind')
door:SetAttribute('DoorBusy',false); door:SetAttribute('DoorOpen',true); assert(indicator.Color==theme.Success)
building:Destroy()
assert(api.Clear()); assert(lastOperation=='Commit')
assert(not Storage:FindFirstChild('WITB_FacilityBakeBackup') and not Storage:FindFirstChild('WITB_VisualBakeBackup') and not plot.Model:FindFirstChild('WITB_BakedDecor') and not workspace:FindFirstChild('IndustrialParkRuntime'))
assert(Lighting.ClockTime==14.5 and Lighting.Brightness==3 and Lighting:GetAttribute('WITB_VisualBakeVersion')==nil)
assert(#Lighting.children==1 and Lighting.children[1]==foreign and foreign.Contrast==0.77)
assert(plate.Color=='OriginalGrass' and plate.Material==Enum.Material.Plastic and grid.Transparency==0 and spawn.Transparency==0 and star.Transparency==0)
assert(plot.Model:FindFirstChild('GarageDoor_Panel').Color=='OriginalMeshColor')
assert(plot.Model:FindFirstChild('Warehouse_Roof').Material==Enum.Material.Plastic,'Enum material backup must restore')
count=#all; assert(not api.Clear()); assert(#all==count,'Clear without an owned backup must not remove anything')
local failure=loadBake()(function()
 return {ApplyLighting=function() Lighting.Brightness=0; error('Injected build failure') end}
end,loadExteriorBuilder(),layout,theme,config)
assert(not failure.Bake() and lastOperation=='Cancel')
assert(Lighting.Brightness==3 and grid.Transparency==0 and not Storage:FindFirstChild('WITB_VisualBakeBackup') and not workspace:FindFirstChild('IndustrialParkRuntime') and not plot.Model:FindFirstChild('WITB_BakedDecor'),'Failed bake must roll back all owned changes')
assert(api.Bake())
local partial=loadBake()(loadVisualBuilder(),loadExteriorBuilder(),layout,theme,config,function()
 return {Decorate=function(p,park,created)
  local folder=node('Folder','FacilityPolish',p.Runtime); created(folder)
  Lighting.Brightness=0; error('Injected partial facility failure')
 end}
end,facilityLayout)
local originalBrightness=Lighting.Brightness
assert(not partial.Polish() and lastOperation=='Cancel')
assert(Lighting.Brightness==originalBrightness and not Storage:FindFirstChild('WITB_FacilityBakeBackup') and not plot.Model.WITB_BakedDecor:FindFirstChild('FacilityPolish'),'Failed polish must roll back its partial layer and preserve original bake')
assert(api.Clear())
local foreignPark=node('Folder','IndustrialParkRuntime',workspace)
assert(not api.Bake() and foreignPark.Parent==workspace,'Do not overwrite unmanaged scenery')
print('PASS: editor bake and additive facility stage, separate clear/lighting restoration, idempotence, partial-failure rollback, edited cloned runtime reuse and door/bay rebinding')
'''
with tempfile.TemporaryDirectory() as directory:
    shutil.copyfile(root / 'src/ServerScriptService/YardLayout.luau', Path(directory) / 'YardLayout.luau')
    shutil.copyfile(root / 'src/ServerScriptService/FacilityLayout.luau', Path(directory) / 'FacilityLayout.luau')
    driver = Path(directory) / 'bake.luau'
    driver.write_text(prefix + checks)
    subprocess.run([sys.argv[1], str(driver)], check=True)
