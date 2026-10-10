-- Server-only authorization; no client-supplied owner, distance or price is accepted.
return function(plot, player, activePlot, object, distance)
	if plot.Owner ~= player or activePlot ~= plot or not object:IsDescendantOf(plot.Model) then return false end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return root ~= nil and root:IsA("BasePart") and humanoid ~= nil and humanoid.Health > 0
		and (root.Position - object.Position).Magnitude <= distance
end
