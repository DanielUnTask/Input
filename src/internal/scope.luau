--!strict

const Scope = {}
Scope.__index = Scope

-- Constants
const GENERIC_OBJECT_CLEANUP_METHODS = {
	"Destroy",
	"Disconnect",
	"destroy",
	"disconnect",
	"DESTROY",
	"DISCONNECT",
}

const CLEANUP_METHODS = table.freeze({
	["thread"] = function(thread: thread)
		if coroutine.status(thread) == "suspended" then
			task.cancel(thread)
		end
	end,

	["function"] = function(fn: () -> ())
		fn()
	end,

	["Instance"] = function(inst: Instance)
		inst:Destroy()
	end,

	["RBXScriptConnection"] = function(connection: RBXScriptConnection)
		if connection.Connected then
			connection:Disconnect()
		end
	end,

	["table"] = function(object: { [string]: any })
		for _, methodName in GENERIC_OBJECT_CLEANUP_METHODS do
			const method = object[methodName] :: ((...any) -> ())?
			if typeof(method) == "function" then
				method(object)
				break
			end
		end
	end,
}) :: { [any]: (any) -> () }

-- Private Methods
const function genericCleanup(object: any)
	local action = CLEANUP_METHODS[typeof(object)]

	if action then
		action(object)
	end
end

local function assertAvailable(self: Scope, methodName: string)
	assert(not self._cleaning, `Cannot call Scope:{methodName}() while cleaning`)
	assert(not self._destroyed, `Cannot call Scope:{methodName}() after destruction`)
end

-- Types
type Constructable<T, A...> = { new: (A...) -> T } | (A...) -> T
export type Scope = setmetatable<{
	tasks: { any },
	_destroyed: boolean,
	_cleaning: boolean,
}, typeof(Scope)>

-- Constructor

function Scope.new(): Scope
	return setmetatable({
		tasks = {},
		_destroyed = false,
		_cleaning = false,
	}, Scope)
end

-- Methods

function Scope.add<T>(self: Scope, object: T): T
	assertAvailable(self, "add")

	table.insert(self.tasks, object)
	return object
end

function Scope.construct<T, A...>(self: Scope, class: Constructable<T, A...>, ...: A...): T
	assertAvailable(self, "construct")

	local object = nil
	local t = type(class)
	if t == "table" then
		object = (class :: any).new(...)
	elseif t == "function" then
		object = (class :: any)(...)
	end

	return self:add(object)
end

function Scope.connect(self: Scope, signal: RBXScriptSignal, callback: (...any) -> ()): RBXScriptConnection
	assertAvailable(self, "connect")
	return self.add(self, signal:Connect(callback))
end

function Scope.cleanup(self: Scope)
	if self._cleaning or self._destroyed then
		return
	end

	self._cleaning = true

	for index = #self.tasks, 1, -1 do
		const object = self.tasks[index]
		const success, message = pcall(genericCleanup, object)
		if not success then
			warn(`[Scope]: {message}`)
		end
	end

	table.clear(self.tasks)
	self._cleaning = false
end

function Scope.destroy(self: Scope)
	if self._destroyed or self._cleaning then
		return
	end

	self:cleanup()
	self._destroyed = true
end

return table.freeze({
	new = Scope.new,
})
