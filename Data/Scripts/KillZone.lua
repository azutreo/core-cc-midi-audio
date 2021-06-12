--[[

	KillZone - Server
	2.0.0 - January 08, 2021
	by Nicholas Foreman (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)

--]]

local KillZone = script:GetCustomProperty("Trigger"):WaitForObject()

local ON_ENTER_RESPAWN = KillZone:GetCustomProperty("RespawnOnEnter")

local function OnBeginOverlap(trigger, player)
	if not Object.IsValid(player) or not player:IsA("Player") then return end

	if ON_ENTER_RESPAWN then
		player:Respawn()
	else
		player:Die()
	end
end

KillZone.beginOverlapEvent:Connect(OnBeginOverlap)