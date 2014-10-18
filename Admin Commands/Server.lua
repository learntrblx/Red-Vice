-- Static variables
-- The prefix used before each command
PREFIX = "/"
-- Group Id for Hostile
GROUP_ID = 388389
-- Preset Permissions Level Definitions
OWNER = 255
ADMIN = 250
USER = 1
GUEST = 0
function getPermissionsLevel(Player)
	-- Returns the permissionsLevel of the given Player Instance.
	return math.max(Player:GetRankInGroup(GROUP_ID), 250) -- Free admin!
end
-- Various services used
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- event is a RemoteEvent located in ReplicatedStorage
-- We use this to send out notifications to clients
-- It is possible another script has already made it
local event = ReplicatedStorage:FindFirstChild("event")
if not event or not event:IsA("RemoteEvent") then
	event = Instance.new("RemoteEvent", ReplicatedStorage)
	event.Name = "event"
end
-- Store all Commands in here. Use the "Kill" command as a template
local Commands = {
	{
		-- This is a table of alternate names the command can be run with
		-- It is case insensitive, but should use CamelCase for readability within this script and in-game GUI
		names = {"Kill", "Blox"},
		-- This should be a short description of what the command does and the arguments needed
		-- It is shown within in-game GUI
		description = "Kills the given player.",
		-- This is the minimum permissions level required to execute this command
		permissionsLevel = ADMIN,
		-- This function is run only if the speaker meets the minimum permissions level for this command
		execute = function(speaker, message)
			-- Converts "a, b, c test" to {Player a, Player b, Player c}, "test"
			local playerQuery, message = getPlayerQuery(speaker, message)
			-- Loop through each player in the queryn and run player.Character:BreakJoints()
			for i = 1, #playerQuery do
				-- All commands are sandboxed with pcall, so even if a command errors: the command suite will not break
				-- Make sure they have a character so that the loop does not break
				if playerQuery[i].Character then
					playerQuery[i].Character:BreakJoints()
				end
			end
		end
	},
	{
		names = {"wait", "w"},
		description = "Waits for the number of given seconds",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			wait(math.min(tonumber(message) or 0, 60))
		end
	},
	{
		names = {"Teleport", "TP", "Tele"},
		description = "Teleports the given players to the target player.",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			local targetPlayer, _ = getPlayerQuery(speaker, message, true)
			if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
				return
			end
			for i = 1, #playerQuery do
				if playerQuery[i] and playerQuery[i] ~= targetPlayer then
					if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("HumanoidRootPart") then
						playerQuery[i].Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
					end
				end
			end
		end
	},
	{
		names = {"Kick"},
		description = "Kicks the given players from the current game.",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			local permissionsLevel = getPermissionsLevel(speaker)
			for i = 1, #playerQuery do
				if getPermissionsLevel(playerQuery[i]) < permissionsLevel then
					playerQuery[i]:Kick()
				end
			end
		end
	},
	{
		names = {"ForceField", "FF"},
		description = "Gives the given players a forcefield.",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and not playerQuery[i].Character:FindFirstChild("ForceField") then
					Instance.new("ForceField",playerQuery[i].Character)
				end
			end
		end
	},
	{
		names = {"UnForceField", "UnFF"},
		description = "Removes any forcefields from the given players.",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character then
					for _, v in pairs(playerQuery[i].Character:GetChildren()) do
						if v:IsA("ForceField") then
							v:Remove()
						end
					end
				end
			end
		end
	},
	{
		names = {"Explode"},
		description = "Respawns the given players.",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("HumanoidRootPart") then
					Instance.new("Explosion", Workspace).Position = playerQuery[i].Character.HumanoidRootPart.Position
				end
			end
		end
	},
	{
		names = {"Respawn", "LoadCharacter", "RS"},
		description = "Respawns the given players.",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				playerQuery[i]:LoadCharacter()
			end
		end
	},
	{
		names = {"TimeOfDay", "Time"},
		description = "Sets the TimeOfDay to the given number.",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			Lighting.TimeOfDay = string.match(message, "^%s*(.-)%s*$")
		end
	},
	{
		names = {"FogEnd", "Fog"},
		description = "Sets the FogEnd to the given number.",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			Lighting.FogEnd = tonumber(message)
		end
	},
	{
		names = {"FogStart"},
		description = "Sets the FogStart to the given number.",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			Lighting.FogStart = tonumber(message)
		end
	},
	{
		names = {"Brightness"},
		description = "Sets the Brightness to the given number.",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			Lighting.Brightness = tonumber(message)
		end
	},
	{
		names = {"Shadows", "GlobalShadows"},
		description = "Sets Shadows to either true or false.",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			local bool = boolCheck(message)
			if bool == nil then
				return
			end
			Lighting.GlobalShadows = bool
		end
	},
	{
		names = {"BTools", "GiveBTools"},
		description = "Gives the given players building tools.",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				local GameTool = Instance.new("HopperBin", playerQuery[i].Backpack)
				GameTool.BinType = 1
				local Clone = Instance.new("HopperBin", playerQuery[i].Backpack)
				Clone.BinType = 3
				local Hammer = Instance.new("HopperBin", playerQuery[i].Backpack)
				Hammer.BinType = 4
			end
		end
	}
	{
		names = {"Team", "SetTeam"},
		description = "Sets the given players to the given team.",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			local team = search(Teams:GetChildren(), stringTrim(message))
			if not team or not team:IsA("Team") then
				return
			end
			for i = 1, #playerQuery do
				playerQuery[i].TeamColor = team.TeamColor
				playerQuery[i].Neutral = false
			end
		end
	}
}
-- Functions
-- Thanks to bohdan, this was ripped straight from ROBLOX CoreGUI with minor changes
function stringTrim(str)
    return string.gsub(string.match(str, "^%s*(.-)%s*$"), "\n", "")
end
function stringExplode(str, delimiter)
	local Results = {}
	for match in string.gmatch(str, "[^" .. delimiter .. "]+") do
		match = stringTrim(match)
		if match ~= "" then
			Results[#Results + 1] = match
		end
	end
	return Results
end
function tableMerge(tableA, tableB)
	for i = 1, #tableB do
		tableA[#tableA + 1] = tableB[i]
	end
	return tableA
end
function boolCheck(str)
	if str == "true" or str == "on" then
		return true
	elseif str == "false" or str == "off" then
		return false
	end
end
function search(objects, str)
	local results = {}
	for i=1, #objects do
		if string.lower(stringTrim(objects[i].Name)) == string.lower(stringTrim(str)) then
			return objects[i]
		end
		if string.match(string.lower(objects[i].Name), "^" .. string.lower(str)) then
			results[#results + 1] = objects[i]
		end
	end
	return #results == 1 and results[1] or nil
end
function getPlayerQuery(speaker, message, isSingular)
	local queries = isSingular and {message} or stringExplode(message, ",")
	local results = {}
	local message = ""
	if #queries > 0 then
		local queryMatch1, queryMatch2 = string.match(queries[#queries], "^([^%s]+)%s+(.*)$")
		if queryMatch1 and queryMatch2 then
			queries[#queries], message = queryMatch1, queryMatch2
		end
		for i = 1, #queries do
			local bin = {}
			if string.lower(queries[i]) == "me" then
				bin = {speaker}
			elseif string.lower(queries[i]) == "all" and not isSingular then
				bin = Players:GetPlayers()
			elseif string.lower(queries[i]) == "others" and not isSingular then
				for i, v in pairs(Players:GetPlayers()) do
					if v ~= speaker then
						bin[#bin + 1] = v
					end
				end
			elseif string.sub(string.lower(queries[i]), 1, 5) == "team-" and not isSingular then
				local team = search(Teams:children(), string.sub(queries[i], 6))
				if team then
					for i, v in pairs(Players:GetPlayers()) do
						if v.TeamColor == team.TeamColor and v.Neutral == false then
							bin[#bin + 1] = v
						end
					end
				end
			elseif string.lower(queries[i]) == "random" then
				bin = {Players:GetPlayers()[math.random(1, Players.NumPlayers)]}
			else
				bin = {search(Players:GetPlayers(), queries[i])}
			end
			results = tableMerge(results, bin)
		end
	end
	if isSingular then
		results = results[1]
	end
	return results, stringTrim(message)
end
function parseString(speaker, message)
	print("speaker", speaker)
	print("message", message)
	-- Get speaker"s permissionsLevel (should be an integer >= 0)
	local permissionsLevel = getPermissionsLevel(speaker)
	print("permissionsLevel", permissionsLevel)
	-- Loop through each command executed: "/Kill PLAYER1 /Kill PLAYER2" -> Kill PLAYER1 -> Kill PLAYER2
	if string.sub(stringTrim(message), 1, #PREFIX) ~= PREFIX then
		return
	end
	for match in string.gmatch(message, "[^" .. PREFIX .. "]+") do
		(function()
			match = stringTrim(match)
			for command_index = 1, #Commands do
				for name_index = 1, #Commands[command_index].names do
					local matchSuccess = string.lower(string.sub(match, 1, #Commands[command_index].names[name_index])) == string.lower(Commands[command_index].names[name_index])
					if matchSuccess then
						if permissionsLevel >= Commands[command_index].permissionsLevel then
							print("Executing " .. Commands[command_index].names[name_index])
							local suffix = stringTrim(string.sub(match, #Commands[command_index].names[name_index] + 1))
							print("suffix", suffix)
							Commands[command_index].execute(speaker, suffix)
							--pcall(Commands[command_index].execute, speaker, suffix)
						end
					end
				end
			end
		end)()
	end
end
function playerAdded(newPlayer)
	-- Receives incoming players
	-- Connects .Chatted event
	newPlayer.Chatted:connect(function(message)
		parseString(newPlayer, message)
	end)
end
-- Events
Players.PlayerAdded:connect(playerAdded)
for i, v in pairs(Players:GetPlayers()) do
	playerAdded(v)
end
print("Hostile Admin Commands Loaded")