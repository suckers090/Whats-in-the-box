-- Client-only audio and brief visual feedback; no remote sends or economy decisions.
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local config = require(script.Parent:WaitForChild("VisualConfig"))
local module = {}
local activeSounds = 0
local lastSound = {}
function module.Play(cue, parent)
	local id = config.SoundIds[cue]
	if not config.AudioEnabled or (type(id) ~= "string" and type(id) ~= "number") then return end
	id = tostring(id)
	if not id:match("^%d+$") or tonumber(id) == 0 or activeSounds >= 8 then return end
	local now = os.clock()
	if now - (lastSound[cue] or -math.huge) < 0.08 then return end
	lastSound[cue] = now
	local sound = Instance.new("Sound")
	sound.Name = "WITB_" .. cue; sound.SoundId = "rbxassetid://" .. id
	sound.Volume = config.SoundVolume; sound.RollOffMaxDistance = 45
	sound.Parent = parent or SoundService
	activeSounds += 1
	sound.Destroying:Once(function() activeSounds -= 1 end)
	sound.Ended:Once(function() sound:Destroy() end)
	Debris:AddItem(sound, 8)
	sound:Play()
end
function module.Pulse(label, color)
	if not config.EffectsEnabled or config.ReducedMotion then return end
	label.TextColor3 = color
	TweenService:Create(label, TweenInfo.new(0.45), {TextColor3 = Color3.fromRGB(235, 241, 249)}):Play()
end
function module.Burst(parent, color, strong)
	if not config.EffectsEnabled or config.ReducedMotion then return end
	-- Bounded GUI particles: no assets, perpetual emitters, or world particle replication.
	for index = 1, strong and 12 or 5 do
		local particle = Instance.new("Frame")
		particle.Name = "RevealSpark"; particle.AnchorPoint = Vector2.new(0.5, 0.5)
		particle.Position = UDim2.fromScale(0.5, 0.47)
		particle.Size = UDim2.fromOffset(strong and 5 or 3, strong and 5 or 3)
		particle.BorderSizePixel = 0; particle.BackgroundColor3 = color
		particle.ZIndex = 8; particle.Parent = parent
		local angle = index * math.pi * 2 / (strong and 12 or 5)
		TweenService:Create(particle, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0.5 + math.cos(angle) * 0.44, 0.47 + math.sin(angle) * 0.38),
			BackgroundTransparency = 1, Rotation = index * 35,
		}):Play()
		Debris:AddItem(particle, 0.7)
	end
end
return module
