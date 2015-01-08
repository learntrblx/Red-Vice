---CONFIGURATON---

local TeamDamageEnabled = false
local AutoCleanHats = true

---VARIABLE DECLARATION---

local Players = game:GetService('Players')
local Workspace = game:GetService('Workspace')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local RbxUtility = assert(LoadLibrary('RbxUtility'))
local FilteringEnabled = Workspace.FilteringEnabled

local Event = ReplicatedStorage:FindFirstChild('GunEvent')
if not Event then
	Event = Instance.new('RemoteEvent', ReplicatedStorage)
	Event.Name = 'GunEvent'
end

--FUNCTION DECLARATION---

local FakeDebris = require(script.FakeDebris)

function IsValidTarget(Char, Color)
	local Target = Players:GetPlayerFromCharacter(Char)
	return not TeamDamageEnabled and (Target and Target.TeamColor ~= Color) or TeamDamageEnabled
end

function FireAllOtherClients(RemoteEvent, Loner, ...)
	for _,v in pairs(Players:GetPlayers()) do
		if v ~= Loner then
			RemoteEvent:FireClient(v, ...)
		end
	end
end

---MAIN BODY---

Players.PlayerAdded:connect(function(Player)
	Player.CharacterAdded:connect(function(Character)
		local Torso = Character:WaitForChild('Torso')

		local Weld = RbxUtility.Create('Weld'){
			Part0 = Torso,
		}
		local LeftWeld = Weld:Clone()
		LeftWeld.Name = 'LeftGunWeld'
		LeftWeld.C1 = CFrame.new(0.8, 0.5, 0.4) * CFrame.Angles(math.rad(270), math.rad(40), 0)
		LeftWeld.Parent = Torso
		local RightWeld = Weld:Clone()
		RightWeld.Name = 'RightGunWeld'
		RightWeld.C1 = CFrame.new(-1.2, 0.5, 0.4) * CFrame.Angles(math.rad(270), math.rad(-5), 0)
		RightWeld.Parent = Torso
	end)
end)

Event.OnServerEvent:connect(function(Player, Type, Args, Sound, Damage)
	repeat wait() until Player.Character
	local Character = Player.Character
	local Torso = Character:WaitForChild('Torso')
	local LeftArm = Character:WaitForChild('Left Arm')
	local RightArm = Character:WaitForChild('Right Arm')
	local LeftShoulder = Torso:WaitForChild('Left Shoulder')
	local RightShoulder = Torso:WaitForChild('Right Shoulder')
	local LeftWeld = Torso:WaitForChild('LeftGunWeld')
	local RightWeld = Torso:WaitForChild('RightGunWeld')

	if Type == 'WeldArms' then
		LeftShoulder.Part1 = nil
		RightShoulder.Part1 = nil
		LeftWeld.Part1 = LeftArm
		RightWeld.Part1 = RightArm
	elseif Type == 'UnweldArms' then
		LeftShoulder.Part1 = LeftArm
		RightShoulder.Part1 = RightArm
		LeftWeld.Part1 = nil
		RightWeld.Part1 = nil

	elseif Type == 'Fire' then
		for _,v in pairs(Args) do
			local Origin = v[1]
			local HitPart = v[2]
			local HitPosition = v[3]
			if FilteringEnabled then
				FireAllOtherClients(Event, Player, 'DrawLaser', {Origin, HitPosition, Player.TeamColor})
				FireAllOtherClients(Event, Player, 'PlaySound', Sound)
			end
			if HitPart and HitPart and HitPart.Parent and IsValidTarget(HitPart.Parent, Player.TeamColor) and HitPart.Parent:FindFirstChild('Humanoid') then
				local Humanoid = HitPart.Parent.Humanoid
				if not Humanoid:FindFirstChild('creator') then
					local KillTag = Instance.new('ObjectValue', Humanoid)
					KillTag.Name = 'creator'
					KillTag.Value = Player
					FakeDebris(KillTag, 0.5)
				end
				Humanoid:TakeDamage(Damage)
			end
		end
	end
end)

if AutoCleanHats then
	Workspace.ChildAdded:connect(function(Child)
		if Child:IsA('Hat') then
			Child:Destroy()
		end
	end)
end