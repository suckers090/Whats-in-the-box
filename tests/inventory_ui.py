"""Run real HUD/reveal callbacks against GUI doubles, not Roblox layout/rendering."""
import ast
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
tree = ast.parse((root / 'tests/world_visuals.py').read_text())
prefix = next(n.value.value for n in tree.body if isinstance(n, ast.Assign)
              and any(isinstance(t, ast.Name) and t.id == 'prefix' for t in n.targets))
prefix = prefix.replace('local workspace={}', 'local workspace={children={}}')
prefix += r'''
local import=require
local delayed={}
local task={spawn=function() end,delay=function(seconds,callback) table.insert(delayed,{seconds=seconds,callback=callback}) end}
for name,namespace in pairs(Enum) do setmetatable(namespace,{__index=function(_,key) return key end}) end
setmetatable(Enum,{__index=function(self,key)
 local namespace=setmetatable({},{__index=function(_,name) return name end}); rawset(self,key,namespace); return namespace
end})
local UDim={new=function(scale,offset) return {scale,offset} end}
UDim2.new=function(...) return {...} end
UDim2.fromOffset=function(x,y) return {0,x,0,y} end
UDim2.fromScale=function(x,y) return {x,0,y,0} end
Color3.new=function(r,g,b) return triple(r,g,b) end
local colorMT={}
function colorMT:Lerp(other,t) return setmetatable(triple(self.X+(other.X-self.X)*t,self.Y+(other.Y-self.Y)*t,self.Z+(other.Z-self.Z)*t),{__index=colorMT}) end
Color3.fromRGB=function(r,g,b) return setmetatable(triple(r,g,b),{__index=colorMT}) end
CFrame.lookAt=function() return CFrame.new() end; CFrame.Angles=function() return CFrame.new() end
local oldIsA=methods.IsA
function methods:IsA(name)
 return oldIsA(self,name) or (name=='GuiObject' and (self.ClassName=='Frame' or self.ClassName=='TextLabel'
 or self.ClassName=='TextButton' or self.ClassName=='ScrollingFrame' or self.ClassName=='ViewportFrame'))
end
function methods:GetPropertyChangedSignal(name) return self:GetAttributeChangedSignal('property_'..name) end
function methods:ClearAllChildren() for _,child in ipairs(self:GetChildren()) do child:Destroy() end end
function methods:PivotTo(frame) self.frame=frame end
local baseNew=Instance.new
Instance.new=function(class,parent)
 local value=baseNew(class); value.Name=class; value.Visible=true; value.Active=true; value.Selectable=true
 value.AbsoluteSize={X=620,Y=500}; value.Activated=signal();
 value.MouseEnter=signal(); value.MouseLeave=signal(); value.SelectionGained=signal(); value.SelectionLost=signal();
 value.InputBegan=signal(); value.InputEnded=signal(); value.OnClientEvent=signal()
 value.sent={}; function value:FireServer(...) table.insert(self.sent,{...}) end
 if parent then value.Parent=parent end
 return value
end
theme.Background=triple(13,19,29); theme.Panel=Color3.fromRGB(24,32,45); theme.Raised=triple(32,42,56)
theme.Muted=triple(150,165,181); theme.Rarity={Common=theme.Text,Uncommon=theme.Success,Rare=theme.Accent,Legendary=triple(207,128,58)}
local player=node('Player','Owner'); player:SetAttribute('DataReady',true)
local playerGui=node('PlayerGui','PlayerGui',player)
local event=node('RemoteEvent','WarehouseState',RS); local boxEvent=node('RemoteEvent','BoxEvent',RS)
local noticeEvent=node('RemoteEvent','WarehouseNotice',RS)
local obsolete=node('ScreenGui','WarehouseHUD',playerGui)
for _,name in ipairs({'UITheme','UIStyle','Presentation','VisualConfig','ItemCatalog','CollectionMilestones','InventoryView','RevealStyle','HUDLayout','HUDNavigation'}) do node('ModuleScript',name,RS) end
local dependencies={UITheme=theme,
 UIStyle={Surface=function(value) return value:FindFirstChildOfClass('UIStroke') or node('UIStroke','UIStroke',value) end,Button=function() end},
 Presentation={Play=function() end,Burst=function() end},
 VisualConfig={EffectsEnabled=true,ReducedMotion=true},
 ItemCatalog=import('./ItemCatalog'),CollectionMilestones=import('./CollectionMilestones'),
 InventoryView=import('./InventoryView'),RevealStyle=import('./RevealStyle'),HUDLayout=import('./HUDLayout')}
local function require(value) return dependencies[value.Name] end
local GuiService={SelectedObject=nil}
local input=node('UserInputService','Input'); input.TouchEnabled=false; input.InputBegan=signal()
workspace.GetServerTimeNow=function() return 0 end
local TweenInfo={new=function(...) return {...} end}
game.GetService=function(_,name)
 if name=='Players' then return {LocalPlayer=player} elseif name=='ReplicatedStorage' then return RS
 elseif name=='TweenService' then return {Create=function(_,target,_,properties)
  return {Play=function() for k,v in pairs(properties) do target[k]=v end end,Cancel=function() end}
 end} elseif name=='UserInputService' then return input elseif name=='GuiService' then return GuiService
 elseif name=='RunService' then return {RenderStepped=signal()} end; error(name)
end
'''
prefix += '\nlocal function loadNavigation()\n' + (root / 'src/ReplicatedStorage/HUDNavigation.luau').read_text() + '\nend\ndependencies.HUDNavigation=loadNavigation()\n'
prefix += '\nlocal function runHUD()\n' + (root / 'src/StarterPlayer/StarterPlayerScripts/WarehouseHUD.client.luau').read_text() + '\nend\nrunHUD()\nrunHUD()\n'
for file in ('BoxClient.client.luau', 'WarehouseNotifications.client.luau'):
    prefix += '\ndo\n' + (root / 'src/StarterPlayer/StarterPlayerScripts' / file).read_text() + '\nend\n'
checks = r'''
local function descendants(parent)
 local values={}; local function visit(p) for _,c in ipairs(p:GetChildren()) do table.insert(values,c); visit(c) end end
 visit(parent); return values
end
local function findText(parent,value,class)
 for _,p in ipairs(descendants(parent)) do if p.Text==value and (not class or p.ClassName==class) then return p end end
 error('Missing text: '..value)
end
local function click(parent,value)
 local nav=parent:FindFirstChild(value..'Nav',true)
 if nav then nav.Activated:Fire() else findText(parent,value,'TextButton').Activated:Fire() end
end
local gui=playerGui:FindFirstChild('WarehouseHUD')
assert(gui)
assert(obsolete.Parent==nil,'Obsolete HUD removed before controller mounts')
local hudCount=0; for _,child in ipairs(playerGui:GetChildren()) do if child.Name=='WarehouseHUD' then hudCount+=1 end end
assert(hudCount==1 and #event.OnClientEvent.callbacks==1,'A second script must not duplicate HUD or inventory listeners')
assert(gui.ResetOnSpawn==false and gui.ScreenInsets==Enum.ScreenInsets.CoreUISafeInsets)
local nav=gui:FindFirstChild('IconNavigation',true)
local safe=gui:FindFirstChild('SafeArea'); local cash=gui:FindFirstChild('CashCard',true)
local noticeGui=playerGui:FindFirstChild('WarehouseNotifications')
local noticeSafe=noticeGui:FindFirstChild('NotificationSafeArea')
local notice=noticeSafe:FindFirstChild('Notice')
local function box(value)
 return {x=value.Position[2],y=value.Position[4],w=value.Size[2],h=value.Size[4]}
end
local function overlaps(a,b) return a.x<b.x+b.w and a.x+a.w>b.x and a.y<b.y+b.h and a.y+a.h>b.y end
for _,device in ipairs({{1920,980,false},{1024,690,false},{768,900,true},{390,720,true},{320,500,true},{844,300,true},{568,230,true}}) do
 local w,h,touch=device[1],device[2],device[3]; input.TouchEnabled=touch
 safe.AbsoluteSize={X=w,Y=h}; noticeSafe.AbsoluteSize={X=w,Y=h}
 safe:GetPropertyChangedSignal('AbsoluteSize'):Fire(); noticeSafe:GetPropertyChangedSignal('AbsoluteSize'):Fire()
 local c,n,t=box(cash),box(nav),box(notice)
 assert(c.x>=0 and c.x+c.w<=w and n.y>c.y+c.h and n.x+n.w<=w and n.y+n.h<=h)
 assert(not overlaps(c,t) and not overlaps(n,t),'Cash/navigation must not overlap notices across device sizes')
 if touch then assert(n.y+n.h<=h-math.min(150,h*0.4),'Navigation leaves a thumbstick region') end
 for _,item in ipairs(dependencies.HUDNavigation(theme,dependencies.VisualConfig,dependencies.UIStyle,dependencies.Presentation).Items) do
  local b=nav:FindFirstChild(item.id..'Nav'); assert(b and b.Text=='' and b:FindFirstChild(item.id..'Icon',true))
  assert(b.Size[4]>=48,'Touch targets must remain usable')
 end
end
input.TouchEnabled=false; safe.AbsoluteSize={X=1280,Y=720}; safe:GetPropertyChangedSignal('AbsoluteSize'):Fire()
local inventoryNav=nav:FindFirstChild('InventoryNav'); local navScale=inventoryNav:FindFirstChildOfClass('UIScale')
dependencies.VisualConfig.ReducedMotion=false
inventoryNav.MouseEnter:Fire(); assert(navScale.Scale>1)
inventoryNav.InputBegan:Fire({UserInputType=Enum.UserInputType.Touch}); assert(navScale.Scale<1)
inventoryNav.InputEnded:Fire({UserInputType=Enum.UserInputType.Touch}); assert(navScale.Scale>1)
inventoryNav.MouseLeave:Fire(); assert(navScale.Scale==1)
dependencies.VisualConfig.ReducedMotion=true
inventoryNav.MouseEnter:Fire(); assert(navScale.Scale==1,'Reduced motion suppresses scale animation')
inventoryNav.MouseLeave:Fire()
for _,item in ipairs({'Inventory','Index','Shop','Upgrades','Scanner'}) do
 click(gui,item)
 assert(nav:FindFirstChild(item..'Nav'):FindFirstChild('ActiveMark').Visible,'Selected menu matches navigation')
 click(gui,'X'); assert(not nav:FindFirstChild(item..'Nav'):FindFirstChild('ActiveMark').Visible)
end
click(gui,'Shop'); click(gui,'OPEN INVENTORY')
assert(inventoryNav:FindFirstChild('ActiveMark').Visible,'Internal menu links update the selected button')
click(gui,'HOME'); assert(event.sent[#event.sent][1]=='GoHome','Home travel remains functional')
local fixture={inventory={old_toy=5,gold_watch=2},discoveries={old_toy=5,gold_watch=2},
 collectionClaims={},inventoryLocks={},inventoryFavorites={},scanner=true,plot=1}
event.OnClientEvent:Fire(fixture)
click(gui,'Inventory')
local gold=findText(gui,'Gold Watch').Parent
click(gold,'LOCK')
local request=event.sent[#event.sent]
assert(request[1]=='SetInventoryFlag' and request[2]=='gold_watch' and request[3].flag=='Lock' and request[3].enabled==true)
assert(not findText(gui,'CHECKING...','TextButton').Active,'Actions wait for server acknowledgement')
event.OnClientEvent:Fire({inventoryLocks={gold_watch=true}})
event.OnClientEvent:Fire({inventoryResponse={success=true,message='Stack locked.',requestId=request[3].requestId}})
gold=findText(gui,'Gold Watch').Parent
local locked=findText(gold,'LOCKED','TextButton'); assert(not locked.Active)
local count=#event.sent; locked.Activated:Fire(); assert(#event.sent==count)
click(findText(gui,'Old Toy').Parent,'FAVORITE')
request=event.sent[#event.sent]; assert(request[3].flag=='Favorite' and request[3].enabled)
event.OnClientEvent:Fire({inventoryFavorites={old_toy=true}})
event.OnClientEvent:Fire({inventoryResponse={success=true,message='Added to favorites.',requestId=request[3].requestId}})
assert(findText(findText(gui,'Old Toy').Parent,'UNFAVORITE','TextButton'))
click(gui,'SORT / RARITY'); assert(findText(gui,'SORT / VALUE','TextButton'))
click(gui,'SHOW / ALL'); assert(findText(gui,'SHOW / FAVORITES','TextButton'))
assert(not pcall(function() findText(gui,'Gold Watch') end),'Favorites filter hides unmarked stacks')
click(gui,'SHOW / FAVORITES'); click(gui,'SHOW / UNLOCKED'); click(gui,'SHOW / COMMON')
click(gui,'SHOW / UNCOMMON'); click(gui,'SHOW / RARE'); click(gui,'SHOW / LEGENDARY')
event.OnClientEvent:Fire({inventoryFavorites={}})
local modal=gui:FindFirstChild('DuplicateSaleConfirmation',true)
click(gui,'SELL DUPES'); request=event.sent[#event.sent]
assert(request[1]=='QuoteDuplicates')
event.OnClientEvent:Fire({inventoryResponse={success=true,message='Review sale.',requestId=request[3].requestId,quote={token='q1',value=100,count=4}}})
assert(modal.Visible and findText(modal,'CANCEL','TextButton')==GuiService.SelectedObject)
count=#event.sent; click(modal,'CANCEL'); assert(not modal.Visible and #event.sent==count,'Cancel cannot sell anything')
click(gui,'SELL DUPES'); request=event.sent[#event.sent]
event.OnClientEvent:Fire({inventoryResponse={success=true,message='Review sale.',requestId=request[3].requestId,quote={token='q2',value=100,count=4}}})
click(modal,'CONFIRM SALE'); request=event.sent[#event.sent]
assert(request[1]=='SellDuplicates' and request[2]=='q2' and request[3].price==nil and not modal.Visible)
event.OnClientEvent:Fire({inventory={old_toy=1,gold_watch=2}})
event.OnClientEvent:Fire({inventoryResponse={success=true,message='Sold 4 duplicates for $100.',requestId=request[3].requestId}})
assert(findText(gui,'Sold 4 duplicates for $100.'))
player:SetAttribute('DataReady',false)
count=#event.sent; click(gui,'SELL DUPES'); assert(#event.sent==count)
player:SetAttribute('DataReady',true)
click(findText(gui,'Old Toy').Parent,'LOCK')
for _,timer in ipairs(table.clone(delayed)) do if timer.seconds==4 then timer.callback() end end
assert(event.sent[#event.sent][1]=='RequestState','Timed-out mutation requests refresh without repeating the sale')
click(gui,'SELL DUPES'); request=event.sent[#event.sent]
event.OnClientEvent:Fire({inventoryResponse={success=false,message='Nothing to sell.',requestId=request[3].requestId}})
assert(findText(gui,'Nothing to sell.'))
player:SetAttribute('DataReady',false)
boxEvent.OnClientEvent:Fire('Reveal',{id='gold_watch',token='r1',locked=true,name='Gold Watch',rarity='Rare',value=2500,isNew=false})
local reveal=playerGui:FindFirstChild('BoxRevealUI'); local backdrop=reveal:FindFirstChildOfClass('Frame')
local keep=reveal:FindFirstChild('Keep',true); local sell=reveal:FindFirstChild('Sell',true)
assert(backdrop.Visible and not keep.Active and not sell.Active)
assert(not nav.Visible,'Navigation clears during a package reveal')
player:SetAttribute('DataReady',true)
assert(keep.Active and not sell.Active and sell.Text=='LOCKED')
count=#boxEvent.sent; sell.Activated:Fire(); assert(#boxEvent.sent==count)
keep.Activated:Fire(); assert(boxEvent.sent[#boxEvent.sent][1]=='Keep' and boxEvent.sent[#boxEvent.sent][2]=='r1' and not keep.Active)
boxEvent.OnClientEvent:Fire('DecisionFailed',{token='r1',message='Saving paused'})
assert(keep.Active,'Server rejection must release the waiting buttons')
keep.Activated:Fire()
boxEvent.OnClientEvent:Fire('DecisionFailed',{token='older',message='Stale'})
assert(not keep.Active,'Stale response must not change current request UI')
boxEvent.OnClientEvent:Fire('Closed',{token='older'}); assert(backdrop.Visible)
assert(not nav.Visible,'Stale reward acknowledgement cannot restore navigation over a reveal')
boxEvent.OnClientEvent:Fire('Closed',{token='r1'}); assert(not backdrop.Visible)
assert(nav.Visible,'Navigation returns after current reveal closes')
print('PASS: unique HUD, five real icon menu callbacks, Home, selected/hover/tap states, seven device layouts and notice exclusion; inventory safeguards and receipt-aware reveal preserved')
'''
with tempfile.TemporaryDirectory() as directory:
    for name in ('ItemCatalog', 'CollectionMilestones', 'InventoryView', 'RevealStyle', 'HUDLayout'):
        shutil.copyfile(root / 'src/ReplicatedStorage' / (name + '.luau'), Path(directory) / (name + '.luau'))
    driver = Path(directory) / 'ui.luau'
    driver.write_text(prefix + checks)
    subprocess.run([sys.argv[1], str(driver)], check=True)
