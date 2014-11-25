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

	{
		names = {"wait", "w"},
		description = "Waits for the number of given seconds",
		isAsync = true,
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

}

function GenerateDocs(cmds)
	print('<h1>Admin Commands</h1>')
	print('These are the official Red Vice Admin Commands. And the only ones permitted to be used within RV places.')
	print('<br>')
	print('<h2>Command Documentation</h2>')

	for _,v in pairs(Commands)
		print(' ')
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
		print('<br>')
		print('<b>IsAsync: </b><i>' .. tostring(v.isAsync)) .. '</i>'
	end
end