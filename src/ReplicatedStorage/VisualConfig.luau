-- Presentation only. These toggles/asset slots never modify prices or saved data.
return {
	WorldEnabled = true,
	LightingEnabled = true,
	EffectsEnabled = true,
	ReducedMotion = false,
	AudioEnabled = true,
	-- Assign numeric Roblox audio asset IDs you own or have permission to use.
	-- Empty slots stay silent and create no Sounds or asset requests.
	SoundIds = {Button = "", Cash = "", BoxOpen = "", RareReveal = "",
		Scanner = "", Upgrade = "", Door = ""},
	SoundVolume = 0.3,
}
