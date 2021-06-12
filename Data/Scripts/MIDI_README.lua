--[[

	MIDI Audio - README
	by Nicholas Foreman (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)

	Version 1.9.0
	Created August 22, 2020
	Last Updated May 17, 2021

	Table of Contents:
		1. Summary
		2. Bundle Components
			a. MIDI Audio Dependencies
			b. MIDI Audio
		3. Importing MIDI

	1. Summary

		This MIDI Audio CC allows game creators to import MIDI tracks into Core using a conversion to a Lua table and playing each note on a frame-to-frame basis.

	2. Bundle Components

		There are two primary components of this MIDI Audio bundle:
		• MIDI Audio Dependencies
		• MIDI Audio

		a. MIDI Audio Dependencies:

			This template handles the instantiation of the MIDI Audios on both the server and client and also handles communication between the two environments.
			!!! There should only be one copy of this template in the project.

		b. MIDI Audio

			This is a physical representation of a MIDI Audio. Each copy of this in the project is its own seperate component that can be customized.
			This is how you change what imported MIDI track you want to use.

	3. Importing MIDI

		1. Create a script; call it the name of the audio you are importing
		2. Convert the MIDI file to JSON using the following website:
			https://tonejs.github.io/Midi/
		3. Paste the converted MIDI -> JSON into the new script you created in step 1
		4. Add the script to the AudioTable custom property of the MIDI Audio you want it in

--]]