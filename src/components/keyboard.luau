const Keyboard = {}
Keyboard.__index = Keyboard

--- Services
const UserInputService = game:GetService("UserInputService")

--- Requires
const Scope = require("../internal/scope")
const Signal = require("../internal/signal")

--- Types
export type Keyboard = setmetatable<{
	_scope: Scope.Scope,
	keyUp: Signal.Identity<Enum.KeyCode, boolean>,
	keyDown: Signal.Identity<Enum.KeyCode, boolean>,
}, typeof(Keyboard)>

--- Constructor

--[=[
	@within Keyboard
	@return Keyboard

	Constructs a new keyboard input controller.

	```lua
	local keyboard = Keyboard.new()
	```
]=]
function Keyboard.new(): Keyboard
	const self = setmetatable({}, Keyboard)
	self._scope = Scope.new()

	self.keyUp = self._scope:construct(Signal)
	self.keyDown = self._scope:construct(Signal)

	self._scope:connect(UserInputService.InputBegan, function(input, processed)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			self.keyDown:Fire(input.KeyCode, processed)
		end
	end)

	self._scope:connect(UserInputService.InputEnded, function(input, processed)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			self.keyUp:Fire(input.KeyCode, processed)
		end
	end)

	return self
end

--- Public Methods

--[=[
	@within Keyboard

	Checks if the given key is currently pressed.

	@param keyCode Enum.KeyCode
	@return boolean

	```lua
	const isWDown = keyboard:isKeyDown(Enum.KeyCode.W)
	if isWDown then
		-- Move forward
	end
	```
]=]
function Keyboard.isKeyDown(self: Keyboard, keyCode: Enum.KeyCode): boolean
	return UserInputService:IsKeyDown(keyCode)
end

--[=[
	@within Keyboard

	Checks if both keys are currently pressed.
	Useful for detecting key combinations.

	@param keyCodeOne Enum.KeyCode
	@param keyCodeTwo Enum.KeyCode
	@return boolean

	```lua
	const shiftA = keyboard:areKeysDown(
		Enum.KeyCode.LeftShift,
		Enum.KeyCode.A
	)
	if shiftA then
		-- Perform an action
	end
	```
]=]
function Keyboard.areKeysDown(self: Keyboard, keyCodeOne: Enum.KeyCode, keyCodeTwo: Enum.KeyCode): boolean
	return self:isKeyDown(keyCodeOne) and self:isKeyDown(keyCodeTwo)
end

--[=[
	@within Keyboard

	Checks if either of the two keys is currently pressed.
	Useful when multiple keys can perform the same operation.

	@param keyCodeOne Enum.KeyCode
	@param keyCodeTwo Enum.KeyCode
	@return boolean

	```lua
	const wOrUp = keyboard:areEitherKeysDown(
		Enum.KeyCode.W,
		Enum.KeyCode.Up
	)

	if wOrUp then
		-- Move forward
	end
	```
]=]
function Keyboard.areEitherKeysDown(self: Keyboard, keyCodeOne: Enum.KeyCode, keyCodeTwo: Enum.KeyCode): boolean
	return self:isKeyDown(keyCodeOne) or self:isKeyDown(keyCodeTwo)
end

--[=[
	@within Keyboard

	Destroys the keyboard input controller.

	Cleans up all resources managed by the instance's internal Scope,
	including its input connections and signals.
]=]
function Keyboard.destroy(self)
	self._scope:destroy()
end

return table.freeze({
	new = Keyboard.new,
})
