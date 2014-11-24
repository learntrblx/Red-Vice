local Module = {}

Module.IsEnabled = true

Module.Commands = {

	{
		names = {"Print"},
		description = "Prints the message to the server console",
		permissionsLevel = ADMIN,
		execute = function(speaker, message)
			print(message)
		end
	},

}

return Module