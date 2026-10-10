"""Run actual server remote handlers with two players and production rule modules.
Does not run Roblox networking, DataStore or the world/delivery controller.
"""
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'src/ServerScriptService/WarehousePrototype.server.luau').read_text()
header = source[:source.index('local function runPlot(plot)')]
start = source.index('\tprofile.Snapshot = function()')
snapshot = source[start:source.index('\tlocal plot = Registry.Assign', start)]
prefix = r'''
local import=require
local modules={
 InventoryState=import('./InventoryState'), InventoryActions=import('./InventoryActions'),
 ItemCatalog=import('./ItemCatalog'), CollectionProgress=import('./CollectionProgress'),
 CollectionMilestones=import('./CollectionMilestones'), ItemRoller=import('./ItemRoller'), PlayerProfiles={}
}
local now,serial=0,0
local os={clock=function() return now end}
local function copy(value)
 if type(value)~='table' then return value end
 local cloned={}; for k,v in pairs(value) do cloned[k]=copy(v) end; return cloned
end
local Players={}; local RS={}; local events={}
function RS:FindFirstChild(name) for _,e in ipairs(events) do if e.Name==name then return e end end end
function RS:WaitForChild(name) return name end
local Instance={new=function(class)
 assert(class=='RemoteEvent')
 local value={sent={},OnServerEvent={Connect=function(self,fn) self.handler=fn end}}
 function value:FireClient(player,...) table.insert(self.sent,{player=player,args=copy({...})}) end
 table.insert(events,value); return value
end}
local plots={}; modules.PlotRegistry={Get=function(player) return plots[player] end}
local script={Parent={WaitForChild=function(_,name) return name end}}
local function require(name) assert(modules[name],name); return modules[name] end
local game={GetService=function(_,name)
 if name=='Players' then return Players elseif name=='ReplicatedStorage' then return RS
 elseif name=='TweenService' then return {} elseif name=='HttpService' then
 return {GenerateGUID=function() serial+=1; return 'receipt-'..serial end} end
 error(name)
end}
local Random={new=function() return {} end}
'''
checks = r'''
local function player(id)
 local cash={Value=0}
 local p={UserId=id,Parent=Players,ready=true,leaderstats={Cash=cash}}
 function p:GetAttribute(name) return name=='DataReady' and self.ready end
 function p:FindFirstChild(name) return self[name] end
 function p.leaderstats:FindFirstChild(name) return self[name] end
 return p,cash
end
local owner,cash=player(1); local visitor,visitorCash=player(2)
sessions[owner]=Inventory.New(); sessions[visitor]=Inventory.New()
local data=sessions[owner]; data.collectionClaims={}; sessions[visitor].collectionClaims={}
data.inventory={old_toy=5,gold_watch=2}
data.discoveries={gold_watch=2}
sessions[visitor].inventory.old_toy=8
plots[owner]={Slot=1,ScannerUnlocked=true}; plots[visitor]={Slot=2,ScannerUnlocked=false}
local function command(player,action,id,payload)
 now+=0.2; stateEvent.OnServerEvent.handler(player,action,id,payload)
 local last=stateEvent.sent[#stateEvent.sent]; assert(last.player==player)
 return last.args[1].inventoryResponse
end
local response=command(owner,'SetInventoryFlag','gold_watch',{flag='Lock',enabled=true,requestId='lock'})
assert(response.success and response.requestId=='lock' and data.inventoryLocks.gold_watch)
response=command(owner,'SellInventory','gold_watch',{price=999999,requestId='locked-sell'})
assert(not response.success and cash.Value==0 and data.inventory.gold_watch==2)
local quote=command(owner,'QuoteDuplicates',nil,{requestId='quote'}).quote
assert(quote.count==4 and quote.value==100)
response=command(visitor,'SellDuplicates',quote.token,{requestId='steal'})
assert(not response.success and visitorCash.Value==0 and sessions[visitor].inventory.old_toy==8)
response=command(owner,'SellDuplicates',quote.token,{requestId='sale',price=1e12,quantities={gold_watch=2}})
assert(response.success and cash.Value==100 and data.inventory.old_toy==1 and data.inventory.gold_watch==2)
assert(not command(owner,'SellDuplicates',quote.token,{requestId='replay'}).success and cash.Value==100)
response=command(owner,'SellInventory','old_toy',{requestId='one',quantity=999,value=999999})
assert(response.success and response.cashDelta==25 and cash.Value==125 and data.inventory.old_toy==0)
owner.ready=false
response=command(owner,'SetInventoryFlag','gold_watch',{flag='Lock',enabled=false,requestId='paused'})
assert(not response.success and response.requestId=='paused' and data.inventoryLocks.gold_watch)
assert(not command(owner,'SellInventory',{}, {requestId={}}).success)
data.pending='old_toy'; data.rewardToken='reward-a'
boxEvent.OnServerEvent.handler(owner,'Keep','reward-b')
assert(data.pending=='old_toy' and data.inventory.old_toy==0,'Forged receipt cannot claim an unrevealed reward')
boxEvent.OnServerEvent.handler(owner,'Keep','reward-a')
assert(data.pending=='old_toy' and data.inventory.old_toy==0)
local denied=boxEvent.sent[#boxEvent.sent].args
assert(denied[1]=='DecisionFailed' and denied[2].token=='reward-a','Paused choice must acknowledge failure for UI recovery')
owner.ready=true
boxEvent.OnServerEvent.handler(owner,'Keep','reward-a')
assert(data.pending==nil and data.rewardToken==nil and data.inventory.old_toy==1 and cash.Value==125)
data.pending='gold_watch'; data.rewardToken='reward-c'
boxEvent.OnServerEvent.handler(owner,'Sell','reward-a')
assert(data.pending=='gold_watch' and cash.Value==125,'Old choice cannot consume a later reward')
boxEvent.OnServerEvent.handler(owner,'Sell','reward-c')
assert(data.pending=='gold_watch' and data.inventory.gold_watch==2 and cash.Value==125,'Lock protects reward Sell as well')
boxEvent.OnServerEvent.handler(owner,'Keep','reward-c')
assert(data.pending==nil and data.inventory.gold_watch==3)
local profile={}; local player=owner
SNAPSHOT
local saved=profile.Snapshot()
assert(saved.inventoryLocks.gold_watch and saved.inventoryFavorites and saved.cash==125 and saved.scanner)
assert(saved.rewardToken==nil and saved.saleQuote==nil,'Session receipts must not enter the saved format')
print('PASS: actual remote handlers, per-player receipts, authoritative prices/counts, locks, paused acknowledgements, stale reward choices and profile snapshot fields')
'''.replace('SNAPSHOT', snapshot)
with tempfile.TemporaryDirectory() as directory:
    for name, folder in [('InventoryState', 'ServerScriptService'), ('InventoryActions', 'ServerScriptService'),
                         ('ItemRoller', 'ServerScriptService'),
                         ('CollectionProgress', 'ServerScriptService'), ('ItemCatalog', 'ReplicatedStorage'),
                         ('CollectionMilestones', 'ReplicatedStorage')]:
        shutil.copyfile(root / 'src' / folder / (name + '.luau'), Path(directory) / (name + '.luau'))
    driver = Path(directory) / 'commands.luau'
    driver.write_text(prefix + header + checks)
    subprocess.run([sys.argv[1], str(driver)], check=True)
