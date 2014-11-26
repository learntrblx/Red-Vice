-- Red Vice Admin Commands

-- You'll probably want to change the following before using these commands:

-- The prefix used before each command
PREFIX = ":"

-- Group Id
GROUP_ID = 978919

-- Preset Permissions Level Definitions
OWNER = 255
SUPER = 253
ADMIN = 250
TEMP = 3
USER = 1
GUEST = 0

-- Preset admins, outside of the group, in the format ['NAME'] = LEVEL,
local AdminList = 	{
						['CoffeeFlux'] = ADMIN,
						['Osyris'] = ADMIN,
					}
-- Preset bans
local bannedUsers = {'Scripth', 'Superburke1'}

-- Do not change below here, unless you know what you're doing.

print('Loading RV Admin Commands')

function getPermissionsLevel(Player)
	-- Returns the permissionsLevel of the given Player Instance.
	if Player.userId == game.CreatorId then
		return 255
	end
	return AdminList[Player.Name] or math.max(Player:GetRankInGroup(GROUP_ID), 0)
end

function GetMass(object)
	local mass=0
	pcall(function()
		if object:IsA("BasePart") then mass = mass + object:GetMass() end
		for _,child in pairs(object:GetChildren()) do mass = mass + GetMass(child) end
	end)
	return mass
end

local Debug = true

-- Various services used
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local Debris = game:GetService("Debris")
local ServerStorage = game:GetService("ServerStorage")
local GroupService = game:GetService("GroupService")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService = game:GetService("TeleportService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local HttpEnabled, _ = pcall(function() HttpService:GetAsync("") end)

-- Variables
local toolStorage = ServerStorage
local bannedUsersDS = DataStoreService:GetDataStore("RV_bannedUsersDS")
local LockPerms = 0 --minimum rank needed to join, modified by slock and sunlock
local LoopKilled = {}
local LoopHealed = {}
local ShadowsInitial = Lighting.GlobalShadows
local Faces = {}
local Logs = {}

-- Set math.randomseed
math.randomseed(tick())

-- event is a RemoteEvent located in ReplicatedStorage
-- We use this to send out notifications to clients
-- It is possible another script has already made it
local event = ReplicatedStorage:FindFirstChild("AdminEvent")
if not event or not event:IsA("RemoteEvent") then
	event = Instance.new("RemoteEvent", ReplicatedStorage)
	event.Name = "AdminEvent"
end

-- Store all Commands in here. Use the "Kill" command as a template
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
		permissionsLevel = TEMP,
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
		permissionsLevel = TEMP,
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
		names = {"Explode"},
		description = "Causes the given players to explode violently.",
		permissionsLevel = TEMP,
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
		names = {"ForceField", "FF"},
		description = "Gives the given players a forcefield.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and not playerQuery[i].Character:FindFirstChild("ForceField") then
					Instance.new("ForceField", playerQuery[i].Character)
				end
			end
		end
	},
	{
		names = {"UnForceField", "UnFF"},
		description = "Removes any forcefields from the given players.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character then
					for _, child in pairs(playerQuery[i].Character:GetChildren()) do
						if child:IsA("ForceField") then
							child:Remove()
						end
					end
				end
			end
		end
	},
	{
		names = {"Fling", "Throw"},
		description = "Flings the given players in a random direction.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Torso") and playerQuery[i].Character:FindFirstChild("Humanoid") then
					local BodyForce = Instance.new("BodyForce", playerQuery[i].Character.Torso)
					BodyForce.force = Vector3.new(math.random(22220, 39996), 39996, math.random(22220, 39996))
					playerQuery[i].Character.Humanoid.Sit = true
					Debris:AddItem(BodyForce, 0.1)
				end
			end
		end
	},
	{
		names = {"Freeze"},
		description = "Freezes the given player's character",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Torso") and playerQuery[i].Character:FindFirstChild("Humanoid") then
					playerQuery[i].Character.Torso.Anchored = true
				end
			end
		end
	},
	{
		names = {"UnFreeze", "Thaw"},
		description = "Freezes the given player's character",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Torso") and playerQuery[i].Character:FindFirstChild("Humanoid") then
					playerQuery[i].Character.Torso.Anchored = false
				end
			end
		end
	},
	{
		names = {"Invisible", "Invis"},
		description = "Hides the given player's character",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				local Char = playerQuery[i].Character
				if Char and Char:FindFirstChild("Torso") and Char:FindFirstChild("Humanoid") then
					for _,v in pairs(Char:GetChildren()) do
						if v:IsA("BasePart") then
							v.Transparency = 1
						elseif v:IsA('Hat') then
							v.Handle.Transparency = 1
						end
					end
					if not Faces[playerQuery[i]] then
						Faces[playerQuery[i].Name] = Char.Head.face.Texture
					end
					Char.Head.face.Texture = ''
				end
			end
		end
	},
	{
		names = {"Visible"},
		description = "Shows the given player's character",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				local Char = playerQuery[i].Character
				if Char and Char:FindFirstChild("Torso") and Char:FindFirstChild("Humanoid") then
					for _,v in pairs(Char:GetChildren()) do
						if v:IsA("BasePart") and v.Name ~= 'HumanoidRootPart' then
							v.Transparency = 0
						elseif v:IsA("Hat") then
							v.Handle.Transparency = 0
						end
					end
					Char.Head.face.Texture = Faces[playerQuery[i].Name] 
					if Char.Head.Anchored == false then
						Faces[playerQuery[i].Name] = nil
					end
				end
			end
		end
	},
	{
		names = {"Lock"},
		description = "Locks the given player's character",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Torso") and playerQuery[i].Character:FindFirstChild("Humanoid") then
					for _,v in pairs(playerQuery[i].Character:GetChildren()) do
						if v:IsA("BasePart") then
							v.Locked = true
						elseif v:IsA("Hat") then
							v.Handle.Locked = true
						end
					end
				end
			end
		end
	},
	{
		names = {"UnLock"},
		description = "Unlocks the given player's character",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Torso") and playerQuery[i].Character:FindFirstChild("Humanoid") then
					for _,v in pairs(playerQuery[i].Character:GetChildren()) do
						if v:IsA("BasePart") then
							v.Locked = false
						elseif v:IsA("Hat") then
							v.Handle.Locked = false
						end
					end
				end
			end
		end
	},
	{
		names = {"Punish"},
		description = "Hides the given player's character",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Torso") and playerQuery[i].Character:FindFirstChild("Humanoid") then
					for _,v in pairs(playerQuery[i].Character:GetChildren()) do
						if v:IsA("BasePart") and v.Name ~= 'HumanoidRootPart' then
							v.Transparency = 1
							v.Anchored = true
							v.CanCollide = false
						elseif v:IsA('Hat') then
							v.Handle.Transparency = 1
							v.Handle.Anchored = true
						end
					end
					if not Faces[playerQuery[i].Name] then
						Faces[playerQuery[i].Name] = Char.Head.face.Texture
					end
					Char.Head.face.Texture = ''
				end
			end
		end
	},
	{
		names = {"UnPunish", "Pardon"},
		description = "Hides the given player's character",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Torso") and playerQuery[i].Character:FindFirstChild("Humanoid") then
					for _,v in pairs(playerQuery[i].Character:GetChildren()) do
						if v:IsA("BasePart") and v.Name ~= 'HumanoidRootPart' then
							v.Transparency = 0
							v.Anchored = false
							v.CanCollide = true
						elseif v:IsA("Hat") then
							v.Handle.Transparency = 0
							v.Handle.Anchored = true
						end
					end
					Char.Head.face.Texture = Faces[playerQuery[i].Name]
					Faces[playerQuery[i].Name] = nil
				end
			end
		end
	},
	{
		names = {"Jump"},
		description = "Causes the given player's character to jump",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Torso") and playerQuery[i].Character:FindFirstChild("Humanoid") then
					playerQuery[i].Character.Humanoid.Jump = true
				end
			end
		end
	},
	{
		names = {"RemoveLimbs"},
		description = "Removes the given player's limbs",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Torso") and playerQuery[i].Character:FindFirstChild("Humanoid") then
					Character = playerQuery[i].Character
					Character["Left Leg"]:Destroy()
					Character["Right Leg"]:Destroy()
					Character["Left Arm"]:Destroy()
					Character["Right Arm"]:Destroy()
				end
			end
		end
	},
	{
		names = {"RemoveArms"},
		description = "Removes the given player's arms",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Torso") and playerQuery[i].Character:FindFirstChild("Humanoid") then
					Character = playerQuery[i].Character
					Character["Left Arm"]:Destroy()
					Character["Right Arm"]:Destroy()
				end
			end
		end
	},
	{
		names = {"RemoveLegs"},
		description = "Removes the given player's legs",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Torso") and playerQuery[i].Character:FindFirstChild("Humanoid") then
					Character = playerQuery[i].Character
					Character["Left Leg"]:Destroy()
					Character["Right Leg"]:Destroy()
				end
			end
		end
	},
	{
		names = {"Character", "Char"},
		description = "Changes the character(s) to resemble the given userId",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for _,v in pairs(playerQuery) do
				v.CharacterAppearance = "http://www.roblox.com/Asset/CharacterFetch.ashx?userId=" .. message 
				v:LoadCharacter()
			end
		end
	},
	{
		names = {"UnCharacter", "UnChar", "FixCharacter", "FixChar"},
		description = "Changes the character(s) to resemble their true appearence",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for _,v in pairs(playerQuery) do
				v.CharacterAppearance = "http://www.roblox.com/Asset/CharacterFetch.ashx?userId=" .. v.userId
				v:LoadCharacter()
			end
		end
	},
	{
		names = {"NoGravity", "NoGrav"},
		description = "Counteracts the gravitational force almost completely",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Torso") then
					local BodyForce = playerQuery[i].Character.Torso:FindFirstChild("NoGrav")
					if not BodyForce then
						BodyForce = Instance.new("BodyForce", playerQuery[i].Character.Torso)
						BodyForce.Name = "NoGrav"
					end
					BodyForce.force = Vector3.new(0, GetMass(playerQuery[i].Character) * 196.2/1.01, 0)
				end
			end
		end
	},
	{
		names = {"LowGravity", "LowGrav", "HalfGravity", "HalfGrav"},
		description = "Counteracts half of the gravitational force",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Torso") then
					local BodyForce = playerQuery[i].Character.Torso:FindFirstChild("NoGrav")
					if not BodyForce then
						BodyForce = Instance.new("BodyForce", playerQuery[i].Character.Torso)
						BodyForce.Name = "NoGrav"
					end
					BodyForce.force = Vector3.new(0, GetMass(playerQuery[i].Character) * 196.2/2, 0)
				end
			end
		end
	},
	{
		names = {"SetGravity", "SetGrav"},
		description = "Counteracts some of the gravitational force",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Torso") then
					local BodyForce = playerQuery[i].Character.Torso:FindFirstChild("NoGrav")
					if not BodyForce then
						BodyForce = Instance.new("BodyForce", playerQuery[i].Character.Torso)
						BodyForce.Name = "NoGrav"
					end
					BodyForce.force = Vector3.new(0, GetMass(playerQuery[i].Character) * 196.2 * (100-tonumber(message)) / 100, 0)
				end
			end
		end
	},
	{
		names = {"Gravity", "Grav"},
		description = "Restores the gravitational force to normal",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Torso") and playerQuery[i].Character.Torso:FindFirstChild("NoGrav") then
					playerQuery[i].Character.Torso:FindFirstChild("NoGrav"):Destroy()
				end
			end
		end
	},
	{
		names = {"Hat"},
		description = "Inserts the given hat onto the given players",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for _,v in pairs(playerQuery) do
				if v.Character and v.Character:FindFirstChild("Head") then
					local Hat = InsertService:LoadAsset(tonumber(message)):GetChildren()[1]
					Hat.Parent = v.Character
				end
			end
		end
	},

	-- Humanoid Commands
	{
		names = {"Heal"},
		description = "Sets the given players' Health to their Health + amount",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			local targetHealth = tonumber(message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Humanoid") then
					playerQuery[i].Character.Humanoid.Health = playerQuery[i].Character.Humanoid.Health + targetHealth
				end
			end
		end
	},
	{
		names = {"Damage", "Hurt", "Dmg"},
		description = "Damages the players specified by the damage given number.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Humanoid") then
					playerQuery[i].Character.Humanoid:TakeDamage(tonumber(message))
				end
			end
		end
	},
	{
		names = {"Invincible", "God"},
		description = "Gives the given players unlimited MaxHealth.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Humanoid") then
					playerQuery[i].Character.Humanoid.MaxHealth = math.huge
				end
			end
		end
	},
	{
		names = {"UnInvincible", "UnGod"},
		description = "Gives the given players 100 MaxHealth.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Humanoid") then
					playerQuery[i].Character.Humanoid.MaxHealth = 100
				end
			end
		end
	},
	{
		names = {"Sit"},
		description = "Makes the given players sit.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Humanoid") then
					playerQuery[i].Character.Humanoid.Sit = true
				end
			end
		end
	},
	{
		names = {"UnSit"},
		description = "Makes the given players stand.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Humanoid") then
					playerQuery[i].Character.Humanoid.Sit = false
				end
			end
		end
	},
	{
		names = {"PlatformStand"},
		description = "Makes the given players PlatformStand.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Humanoid") then
					playerQuery[i].Character.Humanoid.PlatformStand = true
				end
			end
		end
	},
	{
		names = {"UnPlatformStand"},
		description = "Makes the given players not PlatformStand.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Humanoid") then
					playerQuery[i].Character.Humanoid.PlatformStand = false
				end
			end
		end
	},
	{
		names = {"Walkspeed", "Speed"},
		description = "Sets the given players' WalkSpeed to the given number.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			local speed = tonumber(message)
			if not speed then
				return
			end
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Humanoid") then
					playerQuery[i].Character.Humanoid.WalkSpeed = speed
				end
			end
		end
	},
	{
		names = {"Health", "SetHealth"},
		description = "Sets the player's health to the value given, or to 100",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Torso") and playerQuery[i].Character:FindFirstChild("Humanoid") then
					playerQuery[i].Character.Humanoid.Health = tonumber(message) or 100
				end
			end
		end
	},
	{
		names = {"MaxHealth", "SetMaxHealth"},
		description = "Sets the player's maxhealth to the value given, or to 100",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Torso") and playerQuery[i].Character:FindFirstChild("Humanoid") then
					playerQuery[i].Character.Humanoid.MaxHealth = tonumber(message) or 100
				end
			end
		end
	},
	{
		names = {"Name", "ChangeName"},
		description = "Changes the player's name to the message",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				local Char = playerQuery[i].Character
				if Char and Char:FindFirstChild("Head") and Char:FindFirstChild("Torso") and Char:FindFirstChild("Humanoid") then
					--TODO: implement this stupid command
				end
			end
		end
	},
	{
		names = {"UnName", "RemoveName"},
		description = "Change the player's name back to the default",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				local Char = playerQuery[i].Character
				if Char and Char:FindFirstChild("Torso") and Char:FindFirstChild("Humanoid") then
					--TODO: also implement this one
				end
			end
		end
	},
	{
		names = {"LoopKill"},
		description = "Continually kills a player",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Humanoid") then
					if not LoopKilled[playerQuery[i].Name] then
						LoopKilled[playerQuery[i].Name] = playerQuery[i]
					end
				end
			end
		end
	},
	{
		names = {"UnLoopKill"},
		description = "Ends a loopkill",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Humanoid") then
					if LoopKilled[playerQuery[i].Name] then
						LoopKilled[playerQuery[i].Name] = nil
					end
				end
			end
		end
	},
	{
		names = {"LoopHeal"},
		description = "Continually heals a player",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Humanoid") then
					if not LoopHealed[playerQuery[i].Name] then
						LoopHealed[playerQuery[i].Name] = playerQuery[i]
					end
				end
			end
		end
	},
	{
		names = {"UnLoopHeal"},
		description = "Ends a loopheal",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				if playerQuery[i].Character and playerQuery[i].Character:FindFirstChild("Humanoid") then
					if LoopHealed[playerQuery[i].Name] then
						LoopHealed[playerQuery[i].Name] = nil
					end
				end
			end
		end
	},

	-- Player Commands
	{
		names = {"Team", "SetTeam"},
		description = "Sets the given players to the given team.",
		permissionsLevel = TEMP,
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
	},
	{
		names = {"Respawn", "LoadCharacter", "RS"},
		description = "Respawns the given players.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for i = 1, #playerQuery do
				playerQuery[i]:LoadCharacter()
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
			for _, player in pairs(playerQuery) do
				if getPermissionsLevel(player) < permissionsLevel then
					player:Kick()
				end
			end
		end
	},
	{
		names = {"Ban", "ServerBan"},
		description = "Bans the given player from the current game.",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			local player, message = getPlayerQuery(speaker, message, true)
			local permissionsLevel = getPermissionsLevel(speaker)
			if getPermissionsLevel(player) < permissionsLevel then
				bannedUsers[#bannedUsers + 1] = player.Name
				player:Kick()
			end
		end
	},
	{
		names = {"UnBan", "UnServerBan"},
		description = "UnBans the given player from the current game.",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			local playerName = stringTrim(message)
			for i = 1, #bannedUsers do
				if tostring(bannedUsers[i]) == tostring(playerName) then
					table.remove(bannedUsers, i)
				end
			end
		end
	},
	{
		names = {"DSBan", "DataStoreBan", "GlobalBan", "DPBan", "PermBan"},
		description = "Bans the given player from the current game and stores this in the DataStore.",
		permissionsLevel = SUPER,
		execute = function(speaker, message)
			local player, message = getPlayerQuery(speaker, message, true)
			local permissionsLevel = getPermissionsLevel(speaker)
			if getPermissionsLevel(player) < permissionsLevel then
				bannedUsersDS:SetAsync(tostring(player.userId), true)
				player:Kick()
			end
		end
	},
	{
		names = {"UnDSBan", "UnDataStoreBan", "UnGlobalBan", "UnDPBan", "UnPermBan"},
		description = "UnBans the given player from the current game and removes this from the DataStore.",
		permissionsLevel = SUPER,
		execute = function(speaker, message)
			local userId
			if HttpEnabled then -- Usernames!
				userId = getUserIdByUsername(message)
			end
			if not userId then
				userId = tonumber(message)
			end
			bannedUsersDS:SetAsync(userId, false)
		end
	},
	{
		names = {"Place"},
		description = "Transports the players to the game specified by the PlaceId",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			local placeId = tonumber(stringTrim(message))
			for _, player in pairs(playerQuery) do
				TeleportService:Teleport(placeId, player)
			end
		end
	},
	{
		names = {"Follow"},
		description = "Transports the players to the server that the player with the specified UserId is in",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			local Response = {TeleportService:GetPlayerPlaceInstanceAsync(tonumber(message))}
			for _, player in pairs(playerQuery) do
				TeleportService:TeleportToPlaceInstance(Response[3], Response[4], player)
			end
		end
	},
	{
		names = {"Change", "ChangeStat"},
		description = "Change the player's stat to the value",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			local Break = stringExplode(message, ",")
			for _,v in pairs(playerQuery) do
				if v:FindFirstChild("leaderstats") then
					local Stat = search(v.leaderstats:GetChildren(), Break[1])
					if Stat then
						Stat.Value = Break[2]
					end
				end
			end
		end
	},
	{
		names = {"Resetstats"},
		description = "Change the player's stats all to 0",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for _,v in pairs(playerQuery) do
				if v:FindFirstChild("leaderstats") then
					for _,v in pairs(v.leaderstats:GetChildren()) do
						v.Value = 0
					end
				end
			end
		end
	},

	-- GUI Info Commands
	{
		names = {"Rank", "Role"},
		description = "Checks the rank of the given player in the given GroupId or Red Vice (if no GroupId is given).",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message, true)
			local rank = playerQuery:GetRankInGroup(tonumber(message) or GROUP_ID)
			local role = playerQuery:GetRoleInGroup(tonumber(message) or GROUP_ID)
			event:FireClient(speaker, 'Hint', '[' .. rank .. '] ' .. role)
		end
	},
	{
		names = {"CountPlayers", "PlayerCount"},
		description = "Displays to the user the total playercount of the server",
		permissionsLevel = GUEST,
		execute = function(speaker, message)
			event:FireClient(speaker, 'Hint', "There are " .. Players.NumPlayers .. " players in the server.")
		end
	},
	{
		names = {'Hint', 'H'},
		description = 'Sends all players a hint with the given text', 
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			event:FireAllClients('Hint', message)
		end
	},
	{
		names = {'Message', 'M'},
		description = 'Sends all players a message with the given text',
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			event:FireAllClients('Message', {speaker.Name, message})
		end
	},
	{
		names = {'PrivateMessage', 'PM'},
		description = 'Send a message to the specified users',
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for _,v in pairs(playerQuery) do
				event:FireClient(v, {speaker.Name, message})
			end
		end
	},
	{
		names = {'ListTools', 'Tools'},
		description = 'Show a list of all the tools in the toolStorage',
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			event:FireClient(speaker, toolStorage:GetChildren())
		end
	},
	{
		names = {'ListBans', 'BanList', 'Bans'},
		description = 'Show a list of all the users banned in the server',
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			event:FireClient(speaker, bannedUsers)
		end
	},
	{
		names = {'ListAdmins', 'AdminList', 'Admins'},
		description = 'Show a list of manual admins and admins in the server',
		permissionsLevel = USER,
		execute = function(speaker, message)
			local ReturnTable = {}
			for i,v in pairs(AdminList) do
				ReturnTable[#ReturnTable + 1] = '[' .. v .. '] ' .. i
			end
			for _,v in pairs(Players:GetPlayers()) do
				if getPermissionsLevel(v) > (tonumber(message) or TEMP) then
					ReturnTable[#ReturnTable + 1] = '[' .. getPermissionsLevel(v) .. '] ' .. v.Name
				end
			end
			if ReturnTable then
				event:FireClient(speaker, {'UnorderedList', ReturnTable})
			end
		end
	},
	{
		names = {'ListLogs', 'ShowLogs', 'Logs'},
		description = 'Show a list of every actiont taken this server, and by who',
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			local ReturnTable = {}
			for _,v in pairs(Logs) do
				ReturnTable[#ReturnTable] = '[' .. v[1] .. '] ' .. v[2]
			end
			if ReturnTable then
				event:FireClient(speaker, {'UnorderedList', ReturnTable})
			end
		end
	},

	-- Tool Commands
	{
		names = {"Give", "GiveTool"},
		description = "Gives the specified players the specified tools.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			local tools = {}
			if string.lower(message) == "all" then
				tools = toolStorage:GetChildren()
			elseif string.lower(message) == "random" then
				tools = {toolStorage[math.random(1, #toolStorage:GetChildren())]}
			else
				for _, str in pairs(stringExplode(message, ",")) do
					local tool = search(toolStorage:GetChildren(), str)
					if tool and (tool:IsA("Tool") or tool:IsA("HopperBin")) then
						tools[#tools + 1] = tool
					end
				end
			end
			for _, tool in pairs(tools) do
				for _, player in pairs(playerQuery) do
					tool:Clone().Parent = player.Backpack
				end
			end
		end
	},
	{
		names = {"RemoveTools"},
		description = "Removes the all tools from the players' Backpack.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for _, player in pairs(playerQuery) do
				if player.Character and player.Character:FindFirstChild("Humanoid") then
					player.Character.Humanoid:UnequipTools()
				end
				player.Backpack:ClearAllChildren()
			end
		end
	},
	{
		names = {"StarterGive", "Starter", "StarterAdd"},
		description = "Gives the specified players the specified tools every time they spawn.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			local tools = {}
			if string.lower(message) == "all" then
				tools = toolStorage:GetChildren()
			elseif string.lower(message) == "random" then
				tools = {toolStorage[math.random(1, #toolStorage:GetChildren())]}
			else
				for _, str in pairs(stringExplode(message, ",")) do
					local tool = search(toolStorage:GetChildren(), str)
					if tool and (tool:IsA("Tool") or tool:IsA("HopperBin")) then
						tools[#tools + 1] = tool
					end
				end
			end
			for _, tool in pairs(tools) do
				for _, player in pairs(playerQuery) do
					tool:Clone().Parent = player.StarterGear
				end
			end
		end
	},
	{
		names = {"RemoveStarter", "RemoveStarterTools"},
		description = "Removes all tools from the players' StarterGear.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			for _, player in pairs(playerQuery) do
				player.StarterGear:ClearAllChildren()
			end
		end
	},
	{
		names = {"Sword", "GiveSword"},
		description = "Gives a LinkedSword to the given players.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(speaker, message)
			local Sword = InsertService:LoadAsset(47433):GetChildren()[1]
			for i = 1, #playerQuery do
				Sword:Clone().Parent = playerQuery[i].Character
			end
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
	},

	-- Lighting Commands
	{
		names = {"TimeOfDay", "Time", "TOD"},
		description = "Sets the TimeOfDay to the given number.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			Lighting.TimeOfDay = stringTrim(message)
		end
	},
	{
		names = {"FogEnd", "Fog"},
		description = "Sets the FogEnd to the given number.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			Lighting.FogEnd = tonumber(message)
		end
	},
	{
		names = {"FogStart"},
		description = "Sets the FogStart to the given number.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			Lighting.FogStart = tonumber(message)
		end
	},
	{
		names = {"FogColor"},
		description = "Sets the FogStart to the given values.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			message = stringExplode(message, ",")
			Lighting.FogColor = Color3.new(tonumber(message[1])/255, tonumber(message[2])/255, tonumber(message[3])/255)
		end
	},
	{
		names = {"Ambient"},
		description = "Sets the Ambient to the given values.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			message = stringExplode(message, ",")
			Lighting.Ambient = Color3.new(tonumber(message[1])/255, tonumber(message[2])/255, tonumber(message[3])/255)
		end
	},
	{
		names = {"Brightness"},
		description = "Sets the Brightness to the given number.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			Lighting.Brightness = tonumber(message)
		end
	},
	{
		names = {"Shadows", "GlobalShadows", "DynamicLighting"},
		description = "Sets Shadows to either true or false.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local bool = boolCheck(message)
			if bool == nil then
				return
			end
			Lighting.GlobalShadows = bool
		end
	},
	{
		names = {"Outlines"},
		description = "Sets Outlines to either true or false.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			local bool = boolCheck(message)
			if bool == nil then
				return
			end
			Lighting.Outlines = bool
		end
	},
	{
		names = {"Fix"},
		description = "Fixes the lighting settings.",
		permissionsLevel = TEMP,
		execute = function(speaker, message)
			Lighting.Ambient = Color3.new(0, 0, 0)
			Lighting.Brightness = 1
			Lighting.GlobalShadows = ShadowsInitial
			Lighting.Outlines = false
			Lighting.TimeOfDay = "14"
			Lighting.FogColor = Color3.new(191/255, 191/255, 191/255)
			Lighting.FogEnd = 100000
			Lighting.FogStart = 0
		end
	},

	-- Utility Commands
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
		names = {"ServerLock", "SLock"},
		description = "Locks the server, so that anyone trying to join with a lower perm level than the speaker is kicked",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			local SpeakerPerms = getPermissionsLevel(speaker)
			if not message then
				LockPerms = ADMIN --TODO: change this default
			else
				message = tonumber(message)
				if message > SpeakerPerms then
					LockPerms = SpeakerPerms
					event:FireClient(speaker, 'Hint', 'Attempt to lock higher than your own rank, locking instead to your rank')
				else
					LockPerms = message
				end
			end
		end
	},
	{
		names = {"ServerUnlock", "SUnlock"},
		description = "Unlocks the server so that anyone can join",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			LockPerms = 0
		end
	},
	{
		names = {'Admin'},
		description = 'Sets to user to the specified admin level, defaulting at TEMP',
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			print(message)
			local playerQuery, message = getPlayerQuery(message)
			local Perms
			if message then
				if tonumber(message) < getPermissionsLevel(speaker) then
					Perms = tonumber(message)
				else
					Perms = getPermissionsLevel(speaker) - 1
					event:FireClient('Hint', 'Attempting to admin someone to your rank or above, instead giving them the rank below you')
				end
			else
				Perms = TEMP
			end
			for _,v in pairs(playerQuery) do
				if v.userId ~= speaker.userId then
					AdminList[v.Name] = Perms
				end
			end
		end
	},
	{
		names = {'UnAdmin', 'RemoveAdmin'},
		description = 'Removes admin privilidges, does not work if the person has their rank from the group',
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			local playerQuery, message = getPlayerQuery(message)
			local SpeakerPerms = getPermissionsLevel(speaker)
			for _,v in pairs(playerQuery) do
				if SpeakerPerms > getPermissionsLevel(v) then
					AdminList[v.Name] = nil
				end
			end
		end
	},
	{
		names = {"Shutdown"},
		description = "Removes everyone from the server and locks it, ending the server",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			event:FireAllClients('Message', {'SERVER', 'Shutting down this server...'})
			wait(5)
			LockPerms = 255
			for _,v in pairs(game.Players:GetPlayers()) do
				v:Kick()
			end
		end
	},
}

-- Utility Functions

function stringTrim(str)
	return string.match(str, "^%s*(.-)%s*$")
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

function tableFind(table, value)
	for _, v in pairs(table) do
		if v == value then
			return v
		end
	end
end

function boolCheck(str)
	if str == "true" or str == "on" then
		return true
	elseif str == "false" or str == "off" then
		return false
	end
end

function getUserIdByUsername(username)
	return tonumber(HttpService:GetAsync("http://rproxy.tk/rapi/GetIdByUsername/" .. username))
end

-- Primary Functions

function search(objects, str)
	local results = {}
	for i = 1, #objects do
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
				for _, player in pairs(Players:GetPlayers()) do
					if player ~= speaker then
						bin[#bin + 1] = player
					end
				end
			elseif string.sub(string.lower(queries[i]), 1, 5) == "team-" and not isSingular then
				local team = search(Teams:GetChildren(), string.sub(queries[i], 6))
				if team then
					for _, player in pairs(Players:GetPlayers()) do
						if player.TeamColor == team.TeamColor and player.Neutral == false then
							bin[#bin + 1] = player
						end
					end
				end
			elseif string.sub(string.lower(queries[i]), 1, 6) == "random" then
				if (string.sub(string.lower(queries[i]), 1, 7) == "randomx") and (#queries[i] > 7) and (not isSingular) then
					local tempBin = {}
					for i=1, tonumber(string.sub(queries[i], 8)), 1 do
						local unfinished = true
						while unfinished do
							local player = Players:GetPlayers()[math.random(1, Players.NumPlayers)]
							if not tempBin[player.Name] then
								tempBin[player.Name] = player
								unfinished = false
							end
						end
					end
					for _, player in pairs(tempBin) do
						bin[#bin + 1] = player
					end
				else
					bin = {Players:GetPlayers()[math.random(1, Players.NumPlayers)]}
				end
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
	-- Get speaker"s permissionsLevel (should be an integer 0 - 255)
	local permissionsLevel = getPermissionsLevel(speaker)
	-- Make sure the beginning is the prefix
	if string.lower(string.sub(stringTrim(message), 1, #PREFIX)) ~= string.lower(PREFIX) then
		return
	end
	-- Loop through each command executed: ":Kill PLAYER1 :Kill PLAYER2" -> "Kill PLAYER1" -> "Kill PLAYER2"
	for match in string.gmatch(message, "[^" .. PREFIX .. "]+") do
		(function()
			match = stringTrim(match)
			for command_index = 1, #Commands do
				for name_index = 1, #Commands[command_index].names do
					if string.lower(string.sub(match, 1, #Commands[command_index].names[name_index])) == string.lower(Commands[command_index].names[name_index]) then
						if permissionsLevel >= Commands[command_index].permissionsLevel then
							local suffix = stringTrim(string.sub(match, #Commands[command_index].names[name_index] + 1)) or ""
							if Commands[command_index].isAsync == true then
								coroutine.wrap(function()
									if Debug then
										Commands[command_index].execute(speaker, suffix)
									else
										pcall(Commands[command_index].execute, speaker, suffix)
									end
								end)()
							else
								if Debug then
									Commands[command_index].execute(speaker, suffix)
								else
									pcall(Commands[command_index].execute, speaker, suffix)
								end
							end
							Logs[#Logs + 1] = {speaker.Name, command_index}
						end
						return
					end
				end
			end
		end)()
	end
end

function playerAdded(newPlayer)
	if tableFind(bannedUsers, newPlayer.Name) or bannedUsersDS:GetAsync(tostring(newPlayer.userId)) == true or getPermissionsLevel(newPlayer) < LockPerms then
		newPlayer:Kick()
		return
	end
	newPlayer.Chatted:connect(function(message)
		parseString(newPlayer, message)
	end)
end

-- Merge in all child ModuleScripts
for _,v in pairs(script.Parent.Modules:GetChildren()) do
	if v:IsA('ModuleScript') then
		Commands = tableMerge(Commands, require(v).Commands)
	end
end

Players.PlayerAdded:connect(playerAdded)
for _, player in pairs(Players:GetPlayers()) do
	playerAdded(player)
end

print("Red Vice Admin Commands Loaded")

--For the loop commands
--Potentially make this a new thread so that if it errors it doesn't kill the commands? idk
while wait(1) do
	for i,v in pairs(LoopKilled) do
		if v and v.Character and v.Character:FindFirstChild("Humanoid") then
			v.Character.Humanoid.Health = 0
		else
			local Player = game.Players:FindFirstChild(i)
			if Player then
				LoopKilled[i] = Player
			end
		end
	end
	for i,v in pairs(LoopHealed) do
		if v and v.Character and v.Character:FindFirstChild("Humanoid") then
			v.Character.Humanoid.Health = v.Character.Humanoid.MaxHealth
		else
			local Player = game.Players:FindFirstChild(i)
			if Player then
				LoopHealed[i] = Player
			end
		end
	end
end