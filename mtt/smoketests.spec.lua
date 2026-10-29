-- mtt tests, only loaded if the "mtt" mod is present and enabled

mtt.register("registered nodes", function(callback)
	assert(core.registered_nodes["pipeworks:pipe_110000_empty"])
	assert(core.registered_nodes["pipeworks:pipe_110000_loaded"])
	assert(core.registered_nodes["pipeworks:tube_1"])
	assert(core.registered_nodes["pipeworks:trashcan"])
	if pipeworks.enable_autocrafter then
		assert(core.registered_nodes["pipeworks:autocrafter"])
	end
	callback()
end)

mtt.register("pipe alias", function(callback)
	assert(core.registered_aliases["pipeworks:pipe"] == "pipeworks:pipe_110000_empty")
	callback()
end)

mtt.register("tube api", function(callback)
	assert(type(pipeworks.register_tube) == "function")
	assert(type(pipeworks.scan_for_tube_objects) == "function")
	callback()
end)
