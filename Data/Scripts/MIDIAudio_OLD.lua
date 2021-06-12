-- MIDIAudio.lua
-- MIDI implementation into Core
-- Created by Nicholas Foreman (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)
-- Credit to Waffle for the "dontCrash" function for JSON parser; that was a life saver

local JSON = require(script:GetCustomProperty("JSON"))

local function playNote(self, note, instrument)
	if(not instrument) then
		instrument = "acoustic grand piano"
	end

	local parentFolder = self.notesFolder:FindChildByName(instrument)
	if(not parentFolder) then
		parentFolder = self.notesFolder:FindChildByName("acoustic grand piano")
	end
	if(not parentFolder) then return end

	local audio = parentFolder:FindChildByName(note.note)
	if(not audio) then return end

	local _, sustainExists = audio:GetSmartProperty("Sustain")
	local _, velocityExists = audio:GetSmartProperty("Velocity")

	if(sustainExists) then
		audio:SetSmartProperty("Sustain", note.duration)
	end
	if(velocityExists) then
		audio:SetSmartProperty("Velocity", math.floor(note.velocity * self.velocityRange))
	end

	audio.volume = self.volume

	audio:Play()
end

local function updateSong(self)
	self.elapsedTime = time() - self.startTime

	local tracksComplete = 0
	for index, track in pairs(self.tracks) do
		local lastNoteIndex = track.lastNoteIndex
		local nextNote = track.notes[lastNoteIndex + 1]
		local previousNote = track.notes[lastNoteIndex]

		if(nextNote and (self.elapsedTime > nextNote.time)) then
			self.tracks[index].lastNoteIndex = lastNoteIndex + 1
			playNote(self, nextNote, track.instrument)
		elseif(not nextNote) then
			if(not previousNote) then
				tracksComplete = tracksComplete + 1
			elseif(previousNote and (self.elapsedTime > (previousNote.time + previousNote.duration))) then
				tracksComplete = tracksComplete + 1
			end
		end
	end

	if(tracksComplete < #self.tracks) then return end

	for _, track in pairs(self.tracks) do
		track.lastNoteIndex = 0
	end

	if(self.repeatOnEnd) then
		self:Play()
	else
		self:Stop()
	end
end

local Module = {}
Module.__index = Module

function Module.New(songJSON, notesFolder)
	assert(type(songJSON == "string"), "JSON must be a string")
	assert(notesFolder:IsA("Folder"), "Notes must be a Folder")

	local self = {}
	self._object = true
	self._task = nil

	self.notesFolder = notesFolder

	self.repeatOnEnd = false
	self.volume = 1
	self.velocityRange = 100

	self.isPlaying = false
	self.isLoaded = false

	self.startTime = 0
	self.elapsedTime = 0

	-- These do nothing
	self.isSpatializationEnabled = false
	self.isAttenuationEnabled = false
	self.isOcclusionEnabled = false

	-- These do something, just wanted to differentiate from above
	local decodedJSON = JSON.Decode(songJSON)
	assert(type(decodedJSON) == "table", "Failed to decode JSON")

	self.raw = songJSON
	self.table = decodedJSON
	self.imported_tracks = decodedJSON.tracks

	self.tracks = {}
	for _, track in pairs(self.imported_tracks) do
		local newTrack = {}
		newTrack.lastNoteIndex = 0
		newTrack.notes = {}
		newTrack.instrument = track.instrument
		if(type(newTrack.instrument) == "table") then
			newTrack.instrument = track.instrument.name
		end

		for _, note in pairs(track.notes) do
			table.insert(newTrack.notes, {note = note.name, time = note.time, duration = note.duration, velocity = note.velocity})
		end

		table.insert(self.tracks, newTrack)
	end

	self.isLoaded = true

	return setmetatable(self, Module)
end

function Module:Play()
	assert(self._object, "Play must be called from an instance of MIDIAudio")

	self:Stop()
	self.startTime = time()

	self._task = Task.Spawn(function()
		updateSong(self)
	end)
	self._task.repeatCount = -1
	self._task.repeatInterval = -1
end

function Module:Stop()
	assert(self._object, "Stop must be called from an instance of MIDIAudio")
	if(not self._task) then return end

	self._task:Cancel()
	self._task = nil
	self.elapsedTime = 0
end

function Module:Pause()
	assert(self._object, "Pause must be called from an instance of MIDIAudio")

	local elapsedTime = self.elapsedTime
	self:Stop()
	self.elapsedTime = elapsedTime
end

function Module:Resume()
	assert(self._object, "Resume must be called from an instance of MIDIAudio")

	local elapsedTime = self.elapsedTime
	self:Stop()
	self.elapsedTime = elapsedTime

	self.startTime = time() - self.elapsedTime
	self._task = Task.Spawn(function()
		updateSong(self)
	end)
	self._task.repeatCount = -1
	self._task.repeatInterval = -1
end

-- This doesn't do anything for now
function Module:SetWorldPosition(vector3)
	assert(self._object, "SetWorldPosition must be called from an instance of MIDIAudio")
	assert(vector3:IsA("Vector3"), "A Vector3 must be passed through MIDIAudio:SetWorldPosition(Vector3)")
end

return Module