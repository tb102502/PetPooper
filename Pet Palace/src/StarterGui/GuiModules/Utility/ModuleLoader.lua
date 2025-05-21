-- ModuleLoader.lua (ModuleScript)
-- Utility for safely loading modules with error handling
-- Place in StarterGui/MainGui/GuiModules/Utility/ModuleLoader.lua

local ModuleLoader = {}

-- Cache loaded modules
local moduleCache = {}

-- Load a module with error handling
function ModuleLoader.LoadModule(modulePath, optional)
	optional = optional or false

	-- Check cache first
	if moduleCache[modulePath] then
		return moduleCache[modulePath]
	end

	-- Try to load the module
	local success, result = pcall(function()
		return require(modulePath)
	end)

	if success then
		moduleCache[modulePath] = result
		print("ModuleLoader: Successfully loaded " .. tostring(modulePath))
		return result
	else
		if optional then
			warn("ModuleLoader: Optional module " .. tostring(modulePath) .. " not found: " .. tostring(result))
			return nil
		else
			error("ModuleLoader: Failed to load required module " .. tostring(modulePath) .. ": " .. tostring(result))
		end
	end
end

-- Load a module asynchronously
function ModuleLoader.LoadModuleAsync(modulePath, callback, optional)
	optional = optional or false

	spawn(function()
		local module = ModuleLoader.LoadModule(modulePath, optional)
		if callback then
			callback(module)
		end
	end)
end

-- Reload a module (useful for development)
function ModuleLoader.ReloadModule(modulePath)
	moduleCache[modulePath] = nil
	return ModuleLoader.LoadModule(modulePath)
end

-- Check if a module is loaded
function ModuleLoader.IsModuleLoaded(modulePath)
	return moduleCache[modulePath] ~= nil
end

-- Get all loaded modules
function ModuleLoader.GetLoadedModules()
	local modules = {}
	for path, module in pairs(moduleCache) do
		table.insert(modules, {path = path, module = module})
	end
	return modules
end

-- Clear module cache
function ModuleLoader.ClearCache()
	moduleCache = {}
	print("ModuleLoader: Cache cleared")
end

return ModuleLoader