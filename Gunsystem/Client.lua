---CONFIGURATON---

local GunType = 'Auto' 		--Auto, Semi, Shotgun

local ReloadTime = 3  		-- Reload time in seconds
local ClipSize = 30   		-- Size of a clip
local FireRate = .13  		-- Time between shots in seconds
local Damage = 10     		-- Damage per bullet
local Spread = math.rad(5)	-- Spread in radians
local Range = 999     		-- Range in studs
local Ammo = ClipSize 		-- Amount in starting clip
local ShotsFired = 5		--Only applicable in Shotgun mode

local TeamDamageEnabled = false
local HitSoundEnabled = false

local CursorNormal = "rbxasset://textures\\GunCursor.png"
local CursorReload = "rbxasset://textures\\GunWaitCursor.png"
local HitSoundId = "rbxasset://sounds\\metalgrass2.mp3"

---VARIABLE DECLARATION---

local Players = game:GetService('Players')
local Workspace = game:GetService('Workspace')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Tool = script.Parent
local Handle = Tool.Handle
local Player = Players.LocalPlayer
wait()
local Character = Player.Character
local Torso = Character:WaitForChild('Torso')
local Humanoid = Character:WaitForChild('Humanoid')
local RightArm = Character:WaitForChild('Right Arm')
local LeftArm = Character:WaitForChild('Left Arm')
local LeftShoulder = Torso:WaitForChild('Left Shoulder')
local RightShoulder = Torso:WaitForChild('Right Shoulder')
local Head = Character:WaitForChild('Head')

local RbxUtility = assert(LoadLibrary('RbxUtility'))

local HitSound = RbxUtility.Create('Sound'){
	SoundId = HitSoundId,
	Pitch = 1.5,
	Volume = HitSoundEnabled and 1 or 0,
}

local Laser = RbxUtility.Create('Part'){
	Name = '_B',
	FormFactor = 0,
	Anchored = true,
	CanCollide = false,
	Locked = true,
	Size = Vector3.new(1, 1, 1),
	TopSurface = 0,
	BottomSurface = 0,
}
RbxUtility.Create('SpecialMesh'){
	Parent = Laser,
	MeshType = 'Brick',
	Name = 'Mesh',
	Scale = Vector3.new(.2, .2, 1)
}

local LeftWeld = Torso:WaitForChild('LeftGunWeld')
local RightWeld = Torso:WaitForChild('RightGunWeld')

local Event = ReplicatedStorage:WaitForChild('GunEvent')
local DrawnRays = Workspace:WaitForChild('DrawnGunRays')

local Reloading = false
local Equipped = true
local MouseDown = false
local Firing = false

--FUNCTION DECLARATION---

local FakeDebris = require(Workspace:FindFirstChild('Server.rbxl').FakeDebris)

function TableMerge(Table1, Table2)
	for _,v in pairs(Table2) do
		Table1[#Table1 + 1] = v
	end
	return Table1
end

function AddSpread(Start, End)
	local Axis = CFrame.new(Start, End)
	local Theta = math.random() * math.pi * 2
	local Phi = math.random() * Spread
	local x = math.cos(Theta) * math.sin(Phi)
	local y = math.sin(Theta) * math.sin(Phi)
	local z = math.cos(Phi)
	return -CFrame.new(Start, Axis:toWorldSpace(CFrame.new(x, y, z)).p).lookVector
end

function Raycast(Start, Direction, Ignore)
	return Workspace:FindPartOnRayWithIgnoreList(Ray.new(Start, Direction * Range), Ignore)
end

function DrawLaser(Start, End, Color)
	local Length = (End - Start).magnitude
	local Orientation = CFrame.new(Start, End)

	local Laser1 = Laser:Clone()
	Laser1.CFrame = Orientation * CFrame.new(0, 0, -Length * .75)
	Laser1.Mesh.Scale = Vector3.new(.2, .2, Length * .5)
	Laser1.BrickColor = Color
	Laser1.Parent = DrawnRays
	local Laser2 = Laser1:Clone()
	Laser2.CFrame = Orientation * CFrame.new(0, 0, -Length * .25)
	Laser2.Parent = DrawnRays
	FakeDebris(Laser1, .06)
	FakeDebris(Laser2, .03)
end

function IsValidTarget(Char)
	local Target = Players:GetPlayerFromCharacter(Char)
	return not TeamDamageEnabled and (Target and Target.TeamColor ~= Player.TeamColor) or TeamDamageEnabled
end

function Fire(Mouse, Count)
	local Shots = {}
	local Origin = Handle.Position
	local Aim = Vector3.new(Mouse.Hit.p.x, Mouse.Hit.p.y, Mouse.Hit.p.z) --because mouse does not exist error happened O_O
	local StartPos = (Head.CFrame * CFrame.new(0.5, 0, 0)).p
	for i=1, Count do
		local Final = AddSpread(StartPos, Aim)
		local HitPart, HitPosition = Raycast(StartPos, Final, TableMerge(DrawnRays:GetChildren(), {Character}))
		DrawLaser(Origin, HitPosition, Player.TeamColor)
		if HitPart and HitPart.Parent and IsValidTarget(HitPart.Parent) and HitPart.Parent:FindFirstChild('Humanoid') and HitSoundEnabled then
			HitSound:Play()
		end
		Shots[#Shots + 1] = {Origin, HitPart, HitPosition}
	end
	Event:FireServer('Fire', Shots, Handle.Fire, Damage)
end

function Reload(Mouse)
	Handle.Reload:Play()
	Mouse.Icon = CursorReload
	Tool.Name = '[REL]'
	Reloading = true
	wait(ReloadTime)
	if Equipped then
		Mouse.Icon = CursorNormal
	end
	Reloading = false
	Ammo = ClipSize
	Tool.Name = '[' .. Ammo .. ']'
end

---MAIN BODY---

math.randomseed(os.time())
math.random()

Tool.Equipped:connect(function(Mouse)
	--Weld the arms
	LeftShoulder.Part1 = nil
	RightShoulder.Part1 = nil
	LeftWeld.Part1 = LeftArm
	RightWeld.Part1 = RightArm
	Event:FireServer('WeldArms')

	--Setup the weapon
	if Humanoid.Health <= 0 then return end
	Mouse.Icon = CursorNormal
	HitSound.Parent = Player.PlayerGui
	Equipped = true
	Tool.Name = Reloading and '[REL]' or '[' .. Ammo .. ']'

	--Set up mouse events
	Mouse.KeyDown:connect(function(Key)
		if not Reloading and Key:lower() == 'r' and Ammo ~= ClipSize then
			Reload(Mouse)
		end
	end)
	Mouse.Button1Up:connect(function()
		MouseDown = false
	end)
	Mouse.Button1Down:connect(function()
		MouseDown = true
		--This is where the different modes differentiate
		if GunType == 'Auto' then
			if not Firing then
				while MouseDown and not Reloading and Ammo > 0 do
					Firing = true
					Ammo = Ammo - 1
					Tool.Name = '[' .. Ammo .. ']'
					Fire(Mouse, 1)
					Handle.Fire:Play()
					wait(FireRate)
				end
				Firing = false
			end
		else
			MouseDown = true
			if Ammo > 0 and not Reloading and not Firing then
				Firing = true
				Ammo = Ammo - 1
				Tool.Name = '[' .. Ammo .. ']'
				Handle.Fire:Play()
				if GunType == 'Shotgun' then
					Fire(Mouse, ShotsFired)
				else
					Fire(Mouse, 1)
				end
				wait(FireRate)
				Firing = false
			end
		end
		if Ammo <= 0 and not Firing then
			Reload(Mouse)
		end
	end)
end)

Tool.Unequipped:connect(function()
	--Unweld arms
	LeftShoulder.Part1 = LeftArm
	RightShoulder.Part1 = RightArm
	LeftWeld.Part1 = nil
	RightWeld.Part1 = nil
	Event:FireServer('UnweldArms')
end)

Humanoid.Died:connect(function()
	Tool:Destroy()
end)

Event.OnClientEvent:connect(function(Type, Args)
	if Type == 'PlaySound' then
		Args:Play()
	elseif Type == 'SetTDE' then
		TeamDamageEnabled = Args
	elseif Type == 'DrawLaser' then
		DrawLaser(unpack(Args))
	end
end)