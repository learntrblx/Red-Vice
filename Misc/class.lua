-- Not entirely sure I'll use this for Hostile, but it's definitely useful.
ROOT = {}
ROOT.ClassName = "ROOT"
function ROOT:__tostring()
	return self.ClassName
end
function ROOT:IsA(className)
	return self.ClassName == className
end
function inherit(class)
	setmetatable(class, {
		__add = function(self, other) return self:__add(other) end,
		__sub = function(self, other) return self:__sub(other) end,
		__mul = function(self, other) return self:__mul(other) end,
		__div = function(self, other) return self:__div(other) end,
		__eq = function(self, other) return self:__eq(other) end,
		__lt = function(self, other) return self:__lt(other) end,
		__le = function(self, other) return self:__le(other) end,
		__call = function(self, ...) return self:__call(...) end,
		__concat = function(self, ...) return self:__concat(...) end,
		__tostring = function(self) return self:__tostring() end,
		__index = class.SuperClass
	})
end
return function(className, superClass, isSingleton)
	local self = {}
	self.ClassName = className
	self.SuperClass = superClass or ROOT
	self.new = not isSingleton and function(...)
		local instance = {}
		instance.SuperClass = self
		inherit(instance)
		if self.init ~= nil then
			self.init(instance, ...)
		end
		return instance
	end or nil
	inherit(self)
	return self
end