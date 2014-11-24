local PREFIX = ':'

function TranslatePerms(value)
	if value == 0 then
		return 'Guest'
	elseif value == 1 then
		return 'User'
	elseif value == 3 then
		return 'Temporary Admin'
	elseif value == 250 then
		return 'Admin'
	elseif value == 253 then
		return 'Super Admin'
	elseif value == 255 then
		return 'Owner'
	end
end

local Commands = {

	-- Character Commands
	{
		-- This is a table of alternate names the command can be run with
		-- It is case insensitive, but should use CamelCase for readability within this script and in-game GUI
		names = {"Kill", "Blox"},
		-- This should be a short description of what the command does and the arguments needed
		-- It is shown within in-game GUI
		description = "Kills the given players.",
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

}

function GenerateDocs(cmds)
	print('<h1>Admin Commands</h1>')
	print('These are the official Red Vice Admin Commands. And the only ones permitted to be used within RV places.')
	print('<br>')
	print('<h2>Command Documentation</h2>')

	for _,v in pairs(Commands)
		print('<br>')
		local Names = v.names[1]
		for _,v in pairs({table.unpack(v.names, 2)}) do
			Names = Names .. ', ' .. v
		end
		print('<h4>' .. Names .. '</h4>')
		print('<b>Syntax: </b>' .. PREFIX .. v.names[1] .. ' INSERT SYNTAX HERE')
		print('<br>')
		print('<b>Description: </b>' .. v.description)
		print('<br>')
		print('<b>Permissions Level: </b>' .. tostring(TranslatePerms(v.permissionsLevel)))
	end
end