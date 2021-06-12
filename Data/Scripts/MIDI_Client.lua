--[[

	MIDI Audio - Client
	by Nicholas Foreman (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)

--]]

local MidiApi = require(script:GetCustomProperty("MIDI_API"))

local function GetAudio(rootGroupId)
	for _, loadedAudio in ipairs(MidiApi.LoadedAudio) do
		if loadedAudio.rootGroup.id == rootGroupId then
			return loadedAudio
		end
	end
end

local function OnPlay(rootGroupId)
	local audio = GetAudio(rootGroupId)
	if not audio then
		return
	end

	audio:Play()
end

local function OnStop(rootGroupId)
	local audio = GetAudio(rootGroupId)
	if not audio then
		return
	end

	audio:Stop()
end

local function OnPause(rootGroupId)
	local audio = GetAudio(rootGroupId)
	if not audio then
		return
	end

	audio:Pause()
end

local function OnResume(rootGroupId)
	local audio = GetAudio(rootGroupId)
	if not audio then
		return
	end

	audio:Resume()
end

function Tick()
	MidiApi.UpdateAudio()
end

Events.Connect("MIDI_Play", OnPlay)
Events.Connect("MIDI_Stop", OnStop)
Events.Connect("MIDI_Pause", OnPause)
Events.Connect("MIDI_Resume", OnResume)

MidiApi.Load()

for _, audio in ipairs(MidiApi.LoadedAudio) do
	if audio.autoPlay then
		audio:Play()
	end
end