-- Static variables
-- The prefix used before each command
PREFIX = "/"
-- Group Id for Hostile
HOSTILE_GROUP_ID = 388389
-- Preset Syntax Definitions
SINGLE_PLAYER_SYNTAX = "Player"
TARGET_SINGLE_PLAYER_SYNTAX = "Player1 Player2"
MULTI_PLAYER_SYNTAX = "Player1, Player2, ..."
TARGET_MULTI_PLAYER_SYNTAX = "Player1, Player2, ... Player3"
-- Preset Permissions Level Definitions
OWNER = 255
ADMIN = 250
USER = 1
GUEST = 0
-- Various services used
local Players = game:GetService("Players")
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
		syntax = MULTI_PLAYER_SYNTAX,
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
		names = {"teleport", "tp", "tele"},
		syntax = TARGET_MULTI_PLAYER_SYNTAX,
		description = "Teleports the given players to the target player.",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			local targetPlayer, _ = getPlayerQuery(speaker, message, true)
			if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character.HumanoidRootPart then
				return
			end
			for i = 1, #playerQuery do
				if playerQuery[i] and playerQuery[i] ~= targetPlayer then
					if playerQuery[i].Character and playerQuery[i].HumanoidRootPart then
						playerQuery[i].Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
					end
				end
			end
		end
	}
}
-- Functions
-- Thanks to bohdan, this was ripped straight from ROBLOX CoreGUI with minor changes
function stringTrim(str)
    return string.gsub(string.match(str, "^%s*(.-)%s*$"), "\n", "")
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
	local queries = isSingular and {message} or string.explode(message, ",")
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
			elseif string.sub(string.lower(queries[i], 1, 5)) == "team-" then
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
			results = table.merge(results, bin)
		end
	end
	if isSingular then
		results = results[1]
	end
	return results, stringTrim(message)
end
function getPermissionsLevel(Player)
	-- TODO: Establish the Player's permissionsLevel here.
	-- TEMPORARY: Returns the rank within Hostile for that user.
	-- We may add special exceptions here in the future for honorary members.
	return Player:GetRankInGroup(HOSTILE_GROUP_ID)
end
function parseString(speaker, message)
	-- Get speaker's permissionsLevel (should be an integer >= 0)
	local permissionsLevel = getPermissionsLevel(speaker)
	-- Loop through each command executed: "/Kill PLAYER1 /Kill PLAYER2" -> Kill PLAYER1 -> Kill PLAYER2
	for match in string.gmatch(message, "[^" .. PREFIX .. "]+") do
		(function()
			for command_index = 1, #Commands do
				if permissionsLevel >= Commands[command_index].permissionsLevel then
					for name_index = 1, #Commands[command_index].names do
						local suffix = string.match(match, "^" .. Commands[command_index].names[name_index] .. "(.*)$")
						if suffix then
							pcall(Commands[command_index].execute, speaker, suffix)
						end
					end
				end
			end
		end)()
	end
end
function playerAdded(newPlayer)
	-- Received incoming players
	-- Connects .Chatted event
	newPlayer.Chatted:connect(function(message)
		parseString(newPlayer, message)
	end)
end
-- Events
Players.PlayerAdded:connect(playerAdded)
-- Utility Code
for i, v in pairs(Players:GetPlayers()) do
	playerAdded(v)
end
print("Hositle Admin Commands Loaded")