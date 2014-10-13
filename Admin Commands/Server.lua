-- The prefix used before each command
local PREFIX = "/"
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
-- Store all Commands in here. Use the "Kill" command as a template.
local Commands = {
	{
		-- This is a table of alternate names the command can be run with.
		-- It is case insensitive, but should use CamelCase for readability within this script and in-game GUI.
		Names = {"Kill", "Blox"},
		Description = "Kills the given player.",
		-- This is the minimum permissions level required to execute this command
		permissionsLevel = 3,
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
}
-- Thanks to bohdan, this was ripped straight from ROBLOX CoreGUI with minor changes
function stringTrim(str, nstr)
	return string.gsub(string.match(str, "^%s*(.-)%s*$"), "\n","\n" .. nstr)
end
function search(objects, str)
	local results = {}
	for i=1, #objects do
		if string.match(string.lower(objects[i].Name), "^%s*(.-)%s*$") == string.match(string.lower(str), "^%s*(.-)%s*$")) then
			return objects[i]
		end
		if string.match(string.lower(objects[i].Name), "^" .. string.lower(str)) then
			results[#results + 1] = objects[i]
		end
	end
	return #results == 1 and results[1] or nil
end
function getPlayerQuery(speaker, message, singular)
	local queries = singular and {message} or string.explode(message,',')
	local results = {}
	local message = ""
	if #queries > 0 then
		local queryMatch = string.match(queries[#queries], "^([^%s]+)%s+(.*)")
		if queryMatch then
			queries[#queries], message = queryMatch
		end
		for i = 1, #queries do
			local bin = {}
			if string.lower(queries[i]) == "me" then
				bin = {speaker}
			elseif string.lower(queries[i]) == "all" and not singular then
				bin = Players:GetPlayers()
			elseif string.lower(queries[i]) == "others" and not singular then
				for i, v in pairs(Players:GetPlayers()) do
					if v ~= speaker then
						bin[#bin+1]=v
					end
				end
			elseif string.sub(string.lower(queries[i], 1, 5)) == "team-" then
				local team = search(Teams:children(),queries[i]:sub(6))
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
			results = table.merge(Results, bin)
		end
	end
	if singular then
		results = results[1]
	end
	return results, message:match("^%s*(.-)%s*$")
end
function getPermissionsLevel(Player)
	-- TODO: Establish the Player's permissionsLevel here.
end
function parseString(speaker, message)
	-- Get speaker's permissionsLevel (should be an integer >= 0)
	local permissionsLevel = getPermissionsLevel(speaker)
	-- Loop through each command executed: "/Kill PLAYER1 /Kill PLAYER2" -> Kill PLAYER1 -> Kill PLAYER2
	for match in string.gmatch(message, "[^" .. PREFIX .. "]+") do
		-- TODO: Parse here
	end
end
function PlayerAdded(newPlayer)
	newPlayer.Chatted:connect(function(message)
		parseString(newPlayer, message)
	end)
end
Players.PlayerAdded:connect(PlayerAdded)
for i, v in pairs(Players:GetPlayers()) do
	PlayerAdded(v)
end