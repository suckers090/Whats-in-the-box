"""Execute actual exterior script with doubles and exported mesh geometry; no Roblox runtime."""
import ast
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
# Reuse the small visual object/service adapter rather than duplicate it.
tree = ast.parse((root / 'tests/world_visuals.py').read_text())
prefix = next(node.value.value for node in tree.body if isinstance(node, ast.Assign)
              and any(isinstance(t, ast.Name) and t.id == 'prefix' for t in node.targets)
              and isinstance(node.value, ast.Constant))
prefix = prefix.replace('local workspace={}', 'local workspace={children={}}')
prefix += r'''
Enum.Material.Asphalt='Asphalt'; Enum.Material.Grass='Grass'; Enum.Material.DiamondPlate='DiamondPlate'
Enum.PartType={Ball='Ball',Cylinder='Cylinder'}; Enum.NormalId.Left='Left'
local vectorMT={__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end}
Vector3.new=function(x,y,z) return setmetatable(triple(x,y,z),vectorMT) end
local typeof=function(value)
 if type(value)=='table' and getmetatable(value)==vectorMT then return 'Vector3' end
 return type(value)
end
frameMT.__index=function(self,key) if key=='Position' then return Vector3.new(self.X,self.Y,self.Z) end end
CFrame.new=function(x,y,z)
 if type(x)=='table' then return setmetatable(triple(x.X,x.Y,x.Z),frameMT) end
 return setmetatable(triple(x or 0,y or 0,z or 0),frameMT)
end
function methods:GetChildren() return table.clone(self.children) end
function methods:GetDescendants()
 local list={}
 local function walk(value)
  for _,child in ipairs(value.children) do table.insert(list,child); walk(child) end
 end
 walk(self); return list
end
setmetatable(workspace,{__index=methods})
local plate=node('Part','Baseplate',workspace)
plate.CFrame=CFrame.new(0,-8,0); plate.Size=Vector3.new(2048,16,2048); plate.CanCollide=true
local grid=node('Texture','Texture',plate); grid.Transparency=0
local legacy=node('SpawnLocation','SpawnLocation',workspace); legacy.CanCollide=true; legacy.Transparency=0
local star=node('Decal','SpawnLogo',legacy); star.Transparency=0
local layout=require('./YardLayout')
local facilityLayout=require('./FacilityLayout')
local originals={}
local function references(target, shiftX, shiftZ)
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
    prefix += 'do local p=node("MeshPart",'+repr(name.text)+',target.Model); '
    prefix += f'p.CFrame=CFrame.new({xyz[0]}+shiftX,{xyz[1]},{xyz[2]}+shiftZ); '
    prefix += 'p.Size=Vector3.new('+','.join(map(str, dimensions))+'); '
    prefix += 'p.Color="Original"; p.Material="Original"; p.TextureID="AuthoredTexture"; p.MeshId="ImportedMesh"; p.CanCollide=true; p.Transparency=0; originals[p]={frame=p.CFrame,size=p.Size,color=p.Color,material=p.Material}; '
    if name.text in ('TruckStop', 'ScannerLocation', 'PackageDrop'):
        prefix += 'target.Markers['+repr(name.text)+']=p; '
    prefix += 'end\n'
prefix += r'''
end
plot.Slot=5
references(plot,0,140)
local callback
local registry={GetAll=function() return {plot} end,Added={Connect=function(_,fn) callback=fn end}}
local function run()
'''
source = (root / 'src/ServerScriptService/WarehouseExterior.server.luau').read_text()
source = source.replace('require(script.Parent:WaitForChild("WarehouseExteriorBuilder"))', 'loadExteriorBuilder()')
source = 'local function loadExteriorBuilder()\n' + (root / 'src/ServerScriptService/WarehouseExteriorBuilder.luau').read_text() + '\nend\n' + source
source = source.replace('require(script.Parent:WaitForChild("FacilityPolish"))', 'loadFacility()')
source = 'local function loadFacility()\n' + (root / 'src/ServerScriptService/FacilityPolish.luau').read_text() + '\nend\n' + source
source = source.replace('require(script.Parent:WaitForChild("FacilityLayout"))', 'facilityLayout')
source = source.replace('require(RS:WaitForChild("VisualConfig"))', 'config')
source = source.replace('require(script.Parent:WaitForChild("PlotRegistry"))', 'registry')
source = source.replace('require(script.Parent:WaitForChild("YardLayout"))', 'layout')
checks = r'''
end
run()
local park=workspace:FindFirstChild('IndustrialParkRuntime')
assert(park and #park.children==2,'First snapshot may start with a plot on the second row')
local section=park:FindFirstChild('EstateRow_0')
local ground=section:FindFirstChild('EstateGround')
assert(math.abs(ground.CFrame.Z-31.94146538)<0.001,'Origin must remove the first observed plot slot shift')
assert(math.abs(ground.CFrame.Y+ground.Size.Y/2-1.03)<0.001)
assert(grid.Transparency==1 and plate.Material=='Grass' and legacy.Transparency==1 and star.Transparency==1)
assert(plate.CanCollide and legacy.CanCollide,'Legacy collision must be preserved')
for value,old in pairs(originals) do
 assert(value.CFrame==old.frame and value.Size==old.size and value.CanCollide and value.Transparency==0)
 assert(value.TextureID=='AuthoredTexture' and value.MeshId=='ImportedMesh','Imported assets must survive')
 if value.Name=='WareHouse_Floor' or value.Name:match('Wall') or value.Name=='Warehouse_backwall' then
  assert(value.Color==old.color and value.Material==old.material,'Wall/floor textures must keep their tint/material')
 end
end
assert(plot.Model:FindFirstChild('Warehouse_Roof').Color~='Original')
assert(plot.Model:FindFirstChild('LoadingDock_Platform').Material=='Concrete')
local count=#all; callback(plot); assert(#all==count,'Duplicate event must not duplicate dressing')
local second={Model=node('Model','Warehouse_2',workspace),Markers={},Slot=6}
second.Runtime=node('Folder','WarehousePrototype',second.Model)
references(second,90,140)
callback(second)
assert(#park.children==2,'Another plot in a row must share the road and lights')
local folder=second.Runtime:FindFirstChild('ExteriorPolish')
assert(#folder.children==23)
local facilities=second.Runtime:FindFirstChild('FacilityPolish')
assert(facilities and facilities.ParkedDeliveryVan and facilities.ParkedDeliveryVan.CargoBody.Anchored)
assert(facilities.ParkedDeliveryVan.Tyre.Shape=='Cylinder')
assert(section:FindFirstChild('FacilityPolish'))
local lights=0
for _,value in ipairs(park:GetDescendants()) do
 if value:IsA('BasePart') then
  assert(value.Anchored and value.CanTouch==false)
  assert(value.CanCollide==(value.Name=='EstateGround' or value.Name=='ServiceRoad'))
 elseif value.ClassName=='PointLight' then lights+=1; assert(value.Shadows==false) end
end
assert(lights==8,'Four streetlights per shared row')
local edited=section:FindFirstChild('RoadCenterDash'); edited.Color='ArtistPaint'
count=#all
run()
assert(#all==count and edited.Color=='ArtistPaint','Fresh runtime must reuse saved roads and preserve edits')
local indicatorCount=#all
config.FacilityDetailsEnabled=false
local third={Model=node('Model','Warehouse_3',workspace),Markers={},Slot=7}
third.Runtime=node('Folder','WarehousePrototype',third.Model); references(third,180,140)
callback(third); assert(not third.Runtime:FindFirstChild('FacilityPolish'))
indicatorCount=#all; config.WorldEnabled=false; run(); assert(#all==indicatorCount)
print('PASS: actual exterior setup, arbitrary snapshot order, shared rows/idempotence, imported asset/physics preservation and toggles')
'''
with tempfile.TemporaryDirectory() as directory:
    shutil.copyfile(root / 'src/ServerScriptService/YardLayout.luau', Path(directory) / 'YardLayout.luau')
    shutil.copyfile(root / 'src/ServerScriptService/FacilityLayout.luau', Path(directory) / 'FacilityLayout.luau')
    driver = Path(directory) / 'exterior.luau'
    driver.write_text(prefix + source + checks)
    subprocess.run([sys.argv[1], str(driver)], check=True)
