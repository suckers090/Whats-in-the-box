"""Run actual presentation module with doubles: silent hooks, sound cap/cleanup and burst limits."""
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'src/ReplicatedStorage/Presentation.luau').read_text()
source = source.replace('require(script.Parent:WaitForChild("VisualConfig"))', 'config')
prefix = r'''
local config = {SoundIds={},AudioEnabled=true,EffectsEnabled=true,ReducedMotion=false,SoundVolume=0.3}
local created, cleanup = {}, {}
local function signal() return {Once=function(self,callback) self.callback=callback end} end
local Instance={new=function(class)
 local value={ClassName=class,Destroying=signal(),Ended=signal(),played=false}
 function value:Play() self.played=true end
 function value:Destroy()
  if self.destroyed then return end
  self.destroyed=true; if self.Destroying.callback then self.Destroying.callback() end
 end
 table.insert(created,value); return value
end}
local services = {
 TweenService={Create=function(_,object,info,target)
  return {Play=function() for key,value in pairs(target) do object[key]=value end end}
 end},
 SoundService={},Debris={AddItem=function(_,object,lifetime) table.insert(cleanup,{object,lifetime}) end}
}
local game={GetService=function(_,name) return services[name] end}
local Vector2={new=function(x,y) return {x,y} end}
local UDim2={fromScale=function(x,y) return {x,y} end,fromOffset=function(x,y) return {x,y} end}
local TweenInfo={new=function(...) return {...} end}
local Enum={EasingStyle={Quad='Quad'},EasingDirection={Out='Out'}}
local function load()
'''
checks = r'''
end
local presentation=load()
presentation.Play('Button'); presentation.Play('Unknown')
assert(#created==0,'Empty hooks must not request/create sounds')
config.SoundIds.Button='rbxassetid://123'; presentation.Play('Button')
assert(#created==0,'Invalid configuration must stay silent')
config.SoundIds.Button='123'; config.AudioEnabled=false; presentation.Play('Button')
assert(#created==0,'Mute must prevent sounds')
config.AudioEnabled=true
for index=1,9 do config.SoundIds['cue'..index]='123'; presentation.Play('cue'..index) end
assert(#created==8,'Bound concurrent sounds to eight')
assert(created[1].played and created[1].SoundId=='rbxassetid://123')
assert(cleanup[1][2]==8,'Silent/unloaded audio must still time out')
created[1].Ended.callback()
presentation.Play('cue10') -- missing ID remains silent
config.SoundIds.extra='123'; presentation.Play('extra')
assert(#created==9,'Destroyed sounds must release capacity')
local before=#created
config.EffectsEnabled=false; presentation.Burst({},'gold',true)
assert(#created==before)
config.EffectsEnabled=true; config.ReducedMotion=true; presentation.Burst({},'gold',true)
assert(#created==before)
config.ReducedMotion=false; presentation.Burst({},'gold',true)
assert(#created==before+12,'Strong burst stays at twelve GUI sparks')
for index=before+1,#created do assert(cleanup[index][2]==0.7) end
before=#created; presentation.Burst({},'blue',false)
assert(#created==before+5,'Small burst stays at five GUI sparks')
print('PASS: actual silent/muted audio hooks, concurrency/cleanup and bounded reduced-motion-aware sparks')
'''
with tempfile.TemporaryDirectory() as directory:
    driver=Path(directory)/'presentation.luau'
    driver.write_text(prefix+source+checks)
    subprocess.run([sys.argv[1],str(driver)],check=True)
