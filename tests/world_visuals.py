"""Execute additive world visuals with Roblox doubles and actual exported mesh bounds.
No Roblox renderer, physics or Lighting engine is exercised.
"""
from pathlib import Path
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
place = ET.parse(root / 'build/Whats-in-the-box-marker-test.rbxlx')
fixtures = []
for item in place.iter('Item'):
    props = item.find('Properties')
    if props is None or item.get('class') not in ('Part', 'MeshPart'):
        continue
    name = props.find("*[@name='Name']")
    if name is None:
        continue
    wanted = {'WareHouse_Floor', 'Warehouse_Roof', 'PackageDrop', 'ScannerLocation',
              'TruckStop', 'DoorFrame_Top', 'Warehouse_backwall', 'EmployeeLight_Panel',
              'EmployeeLight_Panel.001', 'EmployeeDoor_panel', 'GarageDoor_Panel'}
    if name.text not in wanted:
        continue
    cf, size = props.find("*[@name='CFrame']"), props.find("*[@name='size']")
    xyz = [float(cf.find(k).text) for k in ('X', 'Y', 'Z')]
    dimensions = [float(size.find(k).text) for k in ('X', 'Y', 'Z')]
    fixtures.append((name.text, xyz, dimensions))
source = (root / 'src/ServerScriptService/WarehouseVisuals.server.luau').read_text()
source = source.replace('require(RS:WaitForChild("UITheme"))', 'theme')
source = source.replace('require(RS:WaitForChild("VisualConfig"))', 'config')
source = source.replace('require(script.Parent:WaitForChild("PlotRegistry"))', 'registry')
prefix = r'''
local function triple(x,y,z) return {X=x,Y=y,Z=z} end
local Vector3 = {new=triple}
local Vector2 = {new=function(x,y) return {X=x,Y=y} end}
local frameMT = {__mul=function(a,b) return setmetatable(triple(a.X+b.X,a.Y+b.Y,a.Z+b.Z),getmetatable(a)) end}
local CFrame = {new=function(x,y,z) return setmetatable(triple(x or 0,y or 0,z or 0),frameMT) end}
local Color3 = {fromRGB=triple}
local UDim2 = {fromScale=function(x,y) return {x,y} end,fromOffset=function(x,y) return {x,y} end}
local Enum = {Material={Metal='Metal',Neon='Neon',Wood='Wood',SmoothPlastic='SmoothPlastic',Concrete='Concrete'},
 SurfaceGuiSizingMode={PixelsPerStud='PixelsPerStud'},
 NormalId={Front='Front',Top='Top'},Font={GothamBold='GothamBold'}}
local all = {}
local methods = {}
local function signal() return {Connect=function() return {Disconnect=function() end} end} end
function methods:IsA(name) return name == self.ClassName or (name=='BasePart' and (self.ClassName=='Part' or self.ClassName=='MeshPart')) end
function methods:FindFirstChild(name,recursive)
 for _,child in ipairs(self.children) do
  if child.Name==name then return child end
  if recursive then local found=child:FindFirstChild(name,true); if found then return found end end
 end
end
function methods:FindFirstChildOfClass(class)
 for _,child in ipairs(self.children) do if child.ClassName==class then return child end end
end
function methods:WaitForChild(name) return self:FindFirstChild(name) end
function methods:GetAttribute(name) return self.attributes[name] end
function methods:GetAttributeChangedSignal() return signal() end
local mt = {__index=methods,__newindex=function(self,key,value)
 if key=='Parent' then rawset(self,key,value); if value then table.insert(value.children,self) end
 else rawset(self,key,value) end
end}
local Instance = {new=function(class)
 local value=setmetatable({ClassName=class,children={},attributes={}},mt)
 table.insert(all,value); return value
end}
local function node(class,name,parent)
 local value=Instance.new(class); value.Name=name; value.Parent=parent; return value
end
local Lighting=node('Lighting','Lighting')
local RS=node('ReplicatedStorage','ReplicatedStorage')
local game={GetService=function(_,name) return name=='Lighting' and Lighting or RS end}
local config={LightingEnabled=true,WorldEnabled=true}
local theme={Text=triple(235,241,249),Accent=triple(105,167,205),Success=triple(79,201,147)}
local workspace={}
local plot={Model=node('Model','Warehouse_1',workspace),Slot=1,Markers={}}
plot.Runtime=node('Folder','WarehousePrototype',plot.Model)
workspace.children = workspace.children or {}
'''
# Workspace needs children before setting Parent.
prefix = prefix.replace('local workspace={}', 'local workspace={children={}}')
for name, xyz, dimensions in fixtures:
    prefix += 'do local p=node("MeshPart",'+repr(name)+',plot.Model); p.CFrame=CFrame.new('+','.join(map(str,xyz))+'); p.Size=Vector3.new('+','.join(map(str,dimensions))+'); '
    if name in ('PackageDrop','ScannerLocation','TruckStop'):
        prefix += 'plot.Markers['+repr(name)+']=p; '
    prefix += 'end\n'
prefix += r'''
local before={}
for _,child in ipairs(plot.Model.children) do before[child]={frame=child.CFrame,size=child.Size} end
local callback
local registry={GetAll=function() return {plot} end,Added={Connect=function(_,fn) callback=fn end}}
local foreign=node('ColorCorrectionEffect','ArtistGrade',Lighting); foreign.Contrast=0.77
local function run()
'''
checks = r'''
end
run()
assert(foreign.Contrast==0.77,'Existing post effect must be preserved')
local folder=plot.Runtime:FindFirstChild('VisualPolish')
assert(folder)
local count,lights=0,0
for _,object in ipairs(all) do
 if object:IsA('BasePart') and object.Parent==folder then
  count+=1
  assert(object.Anchored and object.CanCollide==false and object.CanTouch==false and object.CanQuery==false)
  if object.Name=='RackUpright' or object.Name=='RackShelf' or object.Name=='StorageCrate' then
   assert(math.abs(object.CFrame.X-plot.Model:FindFirstChild('WareHouse_Floor').CFrame.X)>15,'Props must leave central aisle clear')
   for _,marker in pairs(plot.Markers) do
    local dx,dz=object.CFrame.X-marker.CFrame.X,object.CFrame.Z-marker.CFrame.Z
    assert(dx*dx+dz*dz>64,'Props must stay away from stations')
   end
  end
 elseif object.ClassName=='PointLight' then lights+=1; assert(object.Shadows==false) end
end
assert(count==52 and lights==6,'Keep reference per-plot props and lights bounded')
local receiving=folder:FindFirstChild('ReceivingLabel')
local receivingGui=receiving.children[1]
assert(receivingGui.SizingMode=='PixelsPerStud' and receivingGui.PixelsPerStud==80)
local lettering=receivingGui.children[1]
assert(lettering.Rotation==90 and lettering.Size[1]>lettering.Size[2], 'Floor text must follow the long strip axis')
local finish=folder:FindFirstChild('FloorFinish')
assert(finish.Material=='Concrete' and finish.CanCollide==false, 'Finish must not replace collision geometry')
assert(finish.CFrame.Y+finish.Size.Y/2 < receiving.CFrame.Y+receiving.Size.Y/2, 'Receiving markings must stay above the finish')
for object,original in pairs(before) do
 assert(object.CFrame==original.frame and object.Size==original.size,'Imported meshes/markers must not move')
end
local total=#all
callback(plot)
assert(#all==total,'Repeated plot notification must not duplicate decoration')
config.WorldEnabled=false; config.LightingEnabled=false
run()
assert(#all==total,'Disabled visuals must not create objects')
print('PASS: actual visual script, bounded props/lights, clear stations, mesh preservation, idempotence and toggles')
'''
with tempfile.TemporaryDirectory() as directory:
    driver=Path(directory)/'world.luau'
    driver.write_text(prefix+source+checks)
    subprocess.run([sys.argv[1],str(driver)],check=True)
