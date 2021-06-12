local Root = script:GetCustomProperty("Root"):WaitForObject()
local Notes = script:GetCustomProperty("Notes"):WaitForObject()
local MIDIAudio = require(script:GetCustomProperty("MIDIAudio"))

local SONG = require(Root:GetCustomProperty("Song"))
local AUTO_PLAY = Root:GetCustomProperty("AutoPlay")
local LOOPED = Root:GetCustomProperty("Looped")
local VOLUME = Root:GetCustomProperty("Volume")

Song = MIDIAudio.New(SONG, Notes)
Song.volume = VOLUME
Song.repeatOnEnd = LOOPED
Song.velocityRange = 100

if(AUTO_PLAY) then
	Song:Play()
end