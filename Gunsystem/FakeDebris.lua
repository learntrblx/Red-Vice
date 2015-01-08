return function(Object, Time)
	coroutine.resume(coroutine.create(function()
		wait(Time)
		Object:Destroy()
	end))
end