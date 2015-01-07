---CONFIGURATION---

local CTF_MODE = false --Will automatically become true if a flag is inserted

---VARIABLE DEC---

local Players = game:GetService('Players')
local ServerStorage = game:GetService('ServerStorage')
local Workspace = game:GetService('Workspace')

---FUNCTION DEC---

function TableMerge(Table1, Table2)
	for _,v in pairs(Table2) do
		Table1[#Table1 + 1] = v
	end
	return Table1
end

function FindFlagStands(obj)
	local Flags = {}
	for _,v in pairs(obj:GetChildren()) do
		if v:IsA('FlagStand') then
			Flags[#Flags + 1] = v
		end
		TableMerge(Flags, FindFlagStands(v))
	end
	return Flags
end

function PlayerDied(Player, Humanoid)
	local Stats = Player:FindFirstChild('leaderstats')
	if Stats and Stats:FindFirstChild('Wipeouts') then
		Stats.Wipeouts.Value = Stats.Wipeouts.Value + 1
		local Tag = Humanoid:FindFirstChild('creator')
		if Tag and Tag.Value.Parent and Tag.Value:FindFirstChild('leaderstats') and Tag.Value.leaderstats:FindFirstChild('KOs') then
			local Killer = Tag.Value
			if Killer == Player then
				Killer.leaderstats.KOs.Value = Killer.leaderstats.KOs.Value - 1
			else
				Killer.leaderstats.KOs.Value = Killer.leaderstats.KOs.Value + 1
			end
		end
	end
end

---MAIN BODY---

local Stands = FindFlagStands(Workspace)
for _,v in pairs(Stands) do
	v.FlagCaptured:connect(function(Player)
		if Player:FindFirstChild('leaderstats') and Player.leaderstats:FindFirstChild('Captures') then
			Player.leaderstats.Captures.Value = Player.leaderstats.Captures.Value + 1
		end
	end)
end
if #Stands > 0 then
	CTF_MODE = true
end

Players.PlayerAdded:connect(function(Player)
	local LeaderStats = Instance.new('IntValue', Player)
	LeaderStats.Name = 'leaderstats'
	if CTF_MODE then
		local Caps = Instance.new('IntValue', LeaderStats)
		Caps.Name = 'Captures'
	else
		local Kills = Instance.new('IntValue', LeaderStats)
		Kills.Name = 'KOs'
		local Wipeouts = Instance.new('IntValue', LeaderStats)
		Wipeouts.Name = 'Wipeouts'

		Player.CharacterAdded:wait()
		wait()
		local Humanoid = Player.Character.Humanoid
		Humanoid.Died:connect(function() PlayerDied(Player, Humanoid) end)
		Player.CharacterAdded:connect(function(Character)
			Character:WaitForChild('Humanoid').Died:connect(function()
				PlayerDied(Player, Character.Humanoid)
			end)
		end)
	end
end)