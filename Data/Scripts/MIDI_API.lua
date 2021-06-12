--[[

	MIDI Audio - API
	by Nicholas Foreman (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)

	Global Constants:

		Map<string, Array<string>> API.ALIASES

	Global Variables:

		Array<MidiAudio> API.LoadedAudio

	Global Functions:

		Audio API.GetNoteAudio(MidiAudi audio, table note, string instrumentName)
		nil API.Update(MidiAudio audio)
		nil API.UpdateAudio()
		nil API.Load()

	Class Properties:

		bool MidiAudio.isPlaying [READ-ONLY]
		bool MidiAudio.isLoaded [READ-ONLY]

		number MidiAudio.volume
		bool MidiAudio.looped
		bool MidiAudio.autoPlay

	Class Functions:

		MidiAudio:Play()
		MidiAudio:Stop()
		MidiAudio:Pause()
		MidiAudio:Resume()

--]]

local Module = {}
Module.__index = Module

local JSON = require(script:GetCustomProperty("JSON"))

Module.ALIASES = {
	["Piano"] = {
		"grand acoustic piano",
	},
	["Bass Guitar"] = {
		"pizzicato strings",
	},
	["Nylon Guitar"] = {
		"string ensemble 1",
	},
}

Module.LoadedAudio = {}

local function GetAlias(instrumentName)
	for actualName, aliasTable in pairs(Module.ALIASES) do
		for _, alias in ipairs(aliasTable) do
			if string.lower(instrumentName) == string.lower(alias) then
				return actualName
			end
		end
	end
end

local function PlayNote(audio, note, instrumentName)
	local noteAudio = Module.GetNoteAudio(audio, note, instrumentName)
	if not noteAudio then
		return
	end

	local _, sustainExists = noteAudio:GetSmartProperty("Sustain")
	local _, velocityExists = noteAudio:GetSmartProperty("Velocity")

	if sustainExists then
		noteAudio:SetSmartProperty("Sustain", note.duration)
	end
	if velocityExists then
		noteAudio:SetSmartProperty("Velocity", math.floor(note.velocity * 100))
	end

	noteAudio.volume = audio.volume
	noteAudio:Play()
end

function Module.GetNoteAudio(audio, note, instrumentName)
	local alias = GetAlias(instrumentName)
	if alias then
		instrumentName = alias
	end

	local instrumentGroup
	for _, possibleInstrumentGroup in ipairs(audio.instrumentsGroup:GetChildren()) do
		if string.lower(possibleInstrumentGroup.name) == string.lower(instrumentName) then
			instrumentGroup = possibleInstrumentGroup
			break
		end
	end
	if not instrumentGroup then
		instrumentGroup = audio.instrumentsGroup:FindChildByName("Piano")
	end

	return instrumentGroup:FindChildByName("Major"):FindChildByName(note.note)
end

function Module.Update(audio)
	if not Environment.IsClient() then
		return
	end

	if not audio.isPlaying then
		return
	end

	audio.elapsedTime = time() - audio.startTime

	local tracksComplete = 0
	for index, track in pairs(audio.tracks) do
		local lastNoteIndex = track.lastNoteIndex
		local nextNote = track.notes[lastNoteIndex + 1]
		local previousNote = track.notes[lastNoteIndex]

		if nextNote and (audio.elapsedTime > nextNote.time) then
			audio.tracks[index].lastNoteIndex = lastNoteIndex + 1
			PlayNote(audio, nextNote, track.instrument)
		elseif not nextNote then
			if not previousNote then
				tracksComplete = tracksComplete + 1
			elseif previousNote and (audio.elapsedTime > (previousNote.time + previousNote.duration)) then
				tracksComplete = tracksComplete + 1
			end
		end
	end

	if tracksComplete < #audio.tracks then return end

	for _, track in pairs(audio.tracks) do
		track.lastNoteIndex = 0
	end

	if audio.looped then
		audio:Play()
	else
		audio:Stop()
	end
end

function Module.UpdateAudio()
	if not Environment.IsClient() then
		return
	end

	for _, audio in ipairs(Module.LoadedAudio) do
		Module.Update(audio)
	end
end

function Module.Load()
	local descendants = World.GetRootObject():FindDescendantsByType("Folder")

	for _, descendant in ipairs(descendants) do
		if descendant:GetCustomProperty("IsMidiAudio") then
			Module.New(descendant)
		end
	end
end

function Module.New(rootGroup)
	assert(rootGroup:IsA("Folder"), "The root group must be a Folder (or a group)")

	local self = {}
	self._object = true

	self.isPlaying = false
	self.isLoaded = false

	self.startTime = 0
	self.elapsedTime = 0

	self.rootGroup = rootGroup
	self.instrumentsGroup = rootGroup:GetCustomProperty("InstrumentsGroup"):WaitForObject()

	self.volume = CoreMath.Clamp(rootGroup:GetCustomProperty("Volume") or 0, 0, 100)
	self.looped = rootGroup:GetCustomProperty("Looped")
	self.autoPlay = rootGroup:GetCustomProperty("AutoPlay")

	local audioTable = require(rootGroup:GetCustomProperty("AudioTable"))

	-- These do something, just wanted to differentiate from above
	local decodedJSON = JSON.Decode(audioTable)
	assert(type(decodedJSON) == "table", "Failed to decode JSON")

	self.raw = audioTable
	self.table = decodedJSON
	self.imported_tracks = decodedJSON.tracks

	self.tracks = {}
	for _, track in pairs(self.imported_tracks) do
		local newTrack = {}
		newTrack.lastNoteIndex = 0
		newTrack.notes = {}
		newTrack.instrument = track.instrument
		if type(newTrack.instrument) == "table" then
			newTrack.instrument = track.instrument.name
		end

		for _, note in pairs(track.notes) do
			table.insert(newTrack.notes, {note = note.name, time = note.time, duration = note.duration, velocity = note.velocity})
		end

		table.insert(self.tracks, newTrack)
	end

	self.isLoaded = true

	table.insert(Module.LoadedAudio, self)
	return setmetatable(self, Module)
end

function Module:Play()
	assert(self._object, "Must be a valid audio")

	if Environment.IsServer() then
		return Events.BroadcastToAllPlayers("MIDI_Play", self.rootGroup.id)
	end

	self:Stop()
	self.startTime = time()

	self.isPlaying = true
end

function Module:Stop()
	assert(self._object, "Must be a valid audio")

	if Environment.IsServer() then
		return Events.BroadcastToAllPlayers("MIDI_Stop", self.rootGroup.id)
	end

	self.isPlaying = false

	self.startTime = 0
	self.elapsedTime = 0
end

function Module:Pause()
	assert(self._object, "Must be a valid audio")

	if Environment.IsServer() then
		return Events.BroadcastToAllPlayers("MIDI_Pause", self.rootGroup.id)
	end

	local elapsedTime = self.elapsedTime
	self:Stop()
	self.elapsedTime = elapsedTime
end

function Module:Resume()
	assert(self._object, "Must be a valid audio")

	if Environment.IsServer() then
		return Events.BroadcastToAllPlayers("MIDI_Resume", self.rootGroup.id)
	end

	local elapsedTime = self.elapsedTime
	self:Stop()
	self.elapsedTime = elapsedTime

	self.startTime = time() - self.elapsedTime
	self.isPlaying = true
end

return Module