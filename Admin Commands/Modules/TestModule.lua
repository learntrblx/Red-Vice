local Module = {}

Module.IsEnabled = true

Module.Commands = {

	{
		names = {"Print"},
		description = "Prints the message to the server console",
		permissionsLevel = 250,
		execute = function(speaker, message)
			print(message)
		end
	},

}

return Module