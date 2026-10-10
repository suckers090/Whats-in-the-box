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
Color3.new=function(r,g,b) return triple(r,g,b) end
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
 value.AbsoluteSize={X=620,Y=500}; value.Activated=signal(); value.OnClientEvent=signal()
 value.sent={}; function value:FireServer(...) table.insert(self.sent,{...}) end
 if parent then value.Parent=parent end
 return value
end
theme.Background=triple(13,19,29); theme.Panel=triple(24,32,45); theme.Raised=triple(32,42,56)
theme.Muted=triple(150,165,181); theme.Rarity={Common=theme.Text,Uncommon=theme.Success,Rare=theme.Accent,Legendary=triple(207,128,58)}
local player=node('Player','Owner'); player:SetAttribute('DataReady',true)
local playerGui=node('PlayerGui','PlayerGui',player)
local event=node('RemoteEvent','WarehouseState',RS); local boxEvent=node('RemoteEvent','BoxEvent',RS)
for _,name in ipairs({'UITheme','UIStyle','Presentation','VisualConfig','ItemCatalog','CollectionMilestones','InventoryView','RevealStyle'}) do node('ModuleScript',name,RS) end
local dependencies={UITheme=theme,
 UIStyle={Surface=function(value) if not value:FindFirstChildOfClass('UIStroke') then node('UIStroke','UIStroke',value) end end,Button=function() end},
 Presentation={Play=function() end,Burst=function() end},
 VisualConfig={EffectsEnabled=true,ReducedMotion=true},
 ItemCatalog=import('./ItemCatalog'),CollectionMilestones=import('./CollectionMilestones'),
 InventoryView=import('./InventoryView'),RevealStyle=import('./RevealStyle')}
local function require(value) return dependencies[value.Name] end
local GuiService={SelectedObject=nil}
local input={TouchEnabled=false,InputBegan=signal()}
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
for file in ('WarehouseHUD.client.luau', 'BoxClient.client.luau'):
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
local function click(parent,value) findText(parent,value,'TextButton').Activated:Fire() end
local gui=playerGui:FindFirstChild('WarehouseHUD')
assert(gui)
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
boxEvent.OnClientEvent:Fire('Closed',{token='r1'}); assert(not backdrop.Visible)
print('PASS: real HUD lock/favorite/filter/sort callbacks, quote confirmation/cancel, paused/timeout recovery and receipt-aware reward buttons')
'''
with tempfile.TemporaryDirectory() as directory:
    for name in ('ItemCatalog', 'CollectionMilestones', 'InventoryView', 'RevealStyle'):
        shutil.copyfile(root / 'src/ReplicatedStorage' / (name + '.luau'), Path(directory) / (name + '.luau'))
    driver = Path(directory) / 'ui.luau'
    driver.write_text(prefix + checks)
    subprocess.run([sys.argv[1], str(driver)], check=True)
