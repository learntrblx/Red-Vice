-- Animation Module - Osyris 2014
local cframeInterpolator = require(180220631) -- Credit to TreyReynolds and Stravant
local Joint = {}
Joint.__index = Joint
function Joint.new(jointInstance, targetC1)
	local self = setmetatable({}, Joint)
	self.Instance = jointInstance
	self.StartC1 = jointInstance.C1
	self.TargetC1 = targetC1
	local _, Interpolator = cframeInterpolator(jointInstance.C1, targetC1)
	self.Interpolator = Interpolator
	return self
end
local KeyFrame = {}
KeyFrame.__index = KeyFrame
function KeyFrame.new(jointsTable, duration)
	local self = setmetatable({}, KeyFrame)
	self.Joints = jointsTable
	self.Elapsed = 0
	self.Duration = duration
	return self
end
local Animation = {}
Animation.__index = Animation
function Animation.new(keyFrameTable, priority, loops)
	local self = setmetatable({}, Animation)
	self.KeyFrames = {}
	for _, v in pairs(keyFrameTable) do
		self.KeyFrames[#self.KeyFrames + 1] = v
	end
	self.KeyFrames = keyFrameTable
	self.Step = 1
	self.Loops = loops or false
	self.Priority = priority or 0
	return self
end
function Animation:Play()
	self.Playing = true
end
function Animation:Pause()
	self.Playing = false
end
function Animation:Stop()
	self.Playing = false
	self.Step = 0
end
local Animator = {}
Animator.__index = Animator
function Animator.new()
	local self = setmetatable({}, Animator)
	self.AnimationQueue = {}
	self.HighestPriority = 0
	return self
end
function Animator:addAnimation(animationObject)
	local Priority = animationObject.Priority
	if Priority > self.HighestPriority then
		self.HighestPriority = Priority
	end
	Priority = tostring(Priority)
	if not self.AnimationQueue[Priority] then
		self.AnimationQueue[Priority] = {}
	end
	local PrioritySet = self.AnimationQueue[tostring(Priority)]
	PrioritySet[#PrioritySet + 1] = animationObject
end
function Animator:addAnimations(animationObjectTable)
	for _, animationObject in pairs(animationObjectTable) do
		self:addAnimation(animationObject)
	end
end
function Animator:step(dt)
	local bin = {}
	for i = 1, self.HighestPriority do
		local PrioritySet = self.AnimationQueue[tostring(i)]
		if PrioritySet then
			for j = 1, #PrioritySet do
				local animationObject = PrioritySet[j]
				local keyFrameObject = animationObject.KeyFrames[animationObject.Step]
				if animationObject.Playing then
					for k = 1, #keyFrameObject.Joints do
						local jointObject = keyFrameObject.Joints[k]
						if not bin[jointObject.Instance] then
							bin[jointObject.Instance] = true
							if keyFrameObject.Elapsed == 0 and jointObject.Instance.C1 ~= jointObject.StartC1 then
								jointObject.StartC1 = jointObject.Instance.C1
								local _, Interpolator = cframeInterpolator(jointObject.StartC1, jointObject.TargetC1)
								jointObject.Interpolator = Interpolator
							end
							jointObject.Instance.C1 = jointObject.Interpolator(keyFrameObject.Elapsed / keyFrameObject.Duration)
						end
					end
					keyFrameObject.Elapsed = keyFrameObject.Elapsed + (dt or 1/30)
					if keyFrameObject.Elapsed >= keyFrameObject.Duration then
						animationObject.Step = animationObject.Step + 1
						keyFrameObject.Elapsed = 0
					end
					if #animationObject.KeyFrames < animationObject.Step then
						if animationObject.Loops then
							animationObject.Playing = true
						else
							animationObject.Playing = false
							table.remove(PrioritySet, j)
						end
						animationObject.Step = 1
					end
				end
			end
		end
	end
end
return function()
	return Joint, KeyFrame, Animation, Animator
end