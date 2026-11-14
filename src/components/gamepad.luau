--!strict
const Gamepad = {}
Gamepad.__index = Gamepad

--- Services
const RunService = game:GetService("RunService")
const GuiService = game:GetService("GuiService")
const HapticService = game:GetService("HapticService")
const UserInputService = game:GetService("UserInputService")

--- Requires
const Scope = require("../internal/scope")
const Signal = require("../internal/signal")

--- Private
const function applyDeadzone(value: number, threshold: number): number
	if math.abs(value) < threshold then
		return 0
	end
	return ((math.abs(value) - threshold) / (1 - threshold)) * math.sign(value)
end

const function getActiveGamepad(): Enum.UserInputType?
	local activeGamepad = nil
	local navGamepads = UserInputService:GetNavigationGamepads()
	if #navGamepads > 1 then
		for _, navGamepad in navGamepads do
			if activeGamepad == nil or navGamepad.Value < activeGamepad.Value then
				activeGamepad = navGamepad
			end
		end
	else
		local connectedGamepads = UserInputService:GetConnectedGamepads()
		for _, connectedGamepad in connectedGamepads do
			if activeGamepad == nil or connectedGamepad.Value < activeGamepad.Value then
				activeGamepad = connectedGamepad
			end
		end
	end
	if activeGamepad and not UserInputService:GetGamepadConnected(activeGamepad) then
		activeGamepad = nil
	end
	return activeGamepad
end

const function heartbeatDelay(duration: number, callback: () -> ()): RBXScriptConnection
	const start = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function()
		const elapsed = os.clock() - start
		if elapsed >= duration then
			connection:Disconnect()
			callback()
		end
	end)
	return connection
end

--- Types
export type Gamepad = setmetatable<{
	_scope: Scope.Scope,
	_gamepadScope: Scope.Scope,
	_gamepad: Enum.UserInputType?,
	defaultDeadzone: number,
	_setMotorIds: { [Enum.VibrationMotor]: number },
	state: { [Enum.KeyCode]: InputObject },
	supportsVibration: boolean,
	buttonDown: Signal.Identity<Enum.KeyCode, boolean>,
	buttonUp: Signal.Identity<Enum.KeyCode, boolean>,
	connected: Signal.Identity<>,
	disconnected: Signal.Identity<>,
	gamepadChanged: Signal.Identity<Enum.UserInputType?>,
}, typeof(Gamepad)>

--- Constructor

--[=[
	@param gamepad Enum.UserInputType?
	@return Gamepad

	Creates a new Gamepad instance.

	If no gamepad is provided, the instance automatically tracks
	the currently active gamepad, updating whenever the active
	gamepad changes.

	Provide a specific UserInputType only when the instance
	needs to remain bound to a particular gamepad.

	```lua
	-- Automatically tracks the active gamepad.
	local gamepad = Gamepad.new()

	-- Binds to a specific gamepad.
	local gamepad = Gamepad.new(Enum.UserInputType.Gamepad1)
	```
]=]
function Gamepad.new(gamepad: Enum.UserInputType?): Gamepad
	const self: Gamepad = (setmetatable({}, Gamepad) :: any) :: Gamepad

	self._scope = Scope.new() :: Scope.Scope
	self._gamepadScope = self._scope:construct(Scope :: any) :: Scope.Scope
	self.buttonDown = self._scope:construct(Signal) :: Signal.Identity<Enum.KeyCode, boolean>
	self.buttonUp = self._scope:construct(Signal) :: Signal.Identity<Enum.KeyCode, boolean>
	self.connected = self._scope:construct(Signal) :: Signal.Identity
	self.disconnected = self._scope:construct(Signal) :: Signal.Identity
	self.gamepadChanged = self._scope:construct(Signal) :: Signal.Identity<Enum.UserInputType?>
	self.defaultDeadzone = 0.05
	self.supportsVibration = false
	self.state = {}

	self:_setupGamepad(gamepad)
	self:_setupMotors()

	return self
end

--- Private Methods
function Gamepad._setupMotors(self: Gamepad)
	self._setMotorIds = {}
	for _, motor in Enum.VibrationMotor:GetEnumItems() do
		self._setMotorIds[motor] = 0
	end
end

function Gamepad._setupActiveGamepad(self: Gamepad, gamepad: Enum.UserInputType?)
	local lastGamepad = self._gamepad
	if gamepad == lastGamepad then
		return
	end

	self._gamepadScope:cleanup()
	table.clear(self.state)
	self.supportsVibration = if gamepad then HapticService:IsVibrationSupported(gamepad) else false

	self._gamepad = gamepad

	-- Stop if disconnected:
	if not gamepad then
		self.disconnected:Fire()
		self.gamepadChanged:Fire(nil)
		return
	end

	for _, inputObject in UserInputService:GetGamepadState(gamepad) do
		self.state[inputObject.KeyCode] = inputObject
	end

	self._gamepadScope:add(self, "StopMotors")

	self._gamepadScope:connect(UserInputService.InputBegan, function(input, processed)
		if input.UserInputType == gamepad then
			self.buttonDown:Fire(input.KeyCode, processed)
		end
	end)

	self._gamepadScope:connect(UserInputService.InputEnded, function(input, processed)
		if input.UserInputType == gamepad then
			self.buttonUp:Fire(input.KeyCode, processed)
		end
	end)

	if lastGamepad == nil then
		self.connected:Fire()
	end
	self.gamepadChanged:Fire(gamepad)
end

function Gamepad._setupGamepad(self: Gamepad, forcedGamepad: Enum.UserInputType?)
	if forcedGamepad then
		-- Forced gamepad:
		self._scope:connect(UserInputService.GamepadConnected, function(gp)
			if gp == forcedGamepad then
				self:_setupActiveGamepad(forcedGamepad)
			end
		end)

		self._scope:connect(UserInputService.GamepadDisconnected, function(gp)
			if gp == forcedGamepad then
				self:_setupActiveGamepad(nil)
			end
		end)

		if UserInputService:GetGamepadConnected(forcedGamepad) then
			self:_setupActiveGamepad(forcedGamepad)
		end
	else
		-- Dynamic gamepad:
		local function CheckToSetupActive()
			local active = getActiveGamepad()
			if active ~= self._gamepad then
				self:_setupActiveGamepad(active)
			end
		end

		self._scope:connect(UserInputService.GamepadConnected, CheckToSetupActive)
		self._scope:connect(UserInputService.GamepadDisconnected, CheckToSetupActive)
		self:_setupActiveGamepad(getActiveGamepad())
	end
end

--- Public Methods

--[=[
	@param thumbstick Enum.KeyCode
	@param deadzoneThreshold number?
	@return Vector2

	Gets the position of the given thumbstick, applying a
	deadzone to both its X and Y components.

	The supported thumbsticks are Enum.KeyCode.Thumbstick1
	and Enum.KeyCode.Thumbstick2.

	If deadzoneThreshold is omitted, defaultDeadzone is used.

	```lua
	local position = gamepad:getThumbstick(Enum.KeyCode.Thumbstick1)
	print(position)
	```
]=]
function Gamepad.getThumbstick(self: Gamepad, thumbstick: Enum.KeyCode, deadzoneThreshold: number?): Vector2
	local pos = self.state[thumbstick].Position
	local deadzone = deadzoneThreshold or self.defaultDeadzone
	return Vector2.new(applyDeadzone(pos.X, deadzone), applyDeadzone(pos.Y, deadzone))
end

--[=[
	@param trigger Enum.KeyCode
	@param deadzoneThreshold number?
	@return number

	Gets the analog position of the given trigger.

	Trigger inputs are analog and usually correspond to
	Enum.KeyCode.ButtonL2 and Enum.KeyCode.ButtonR2.

	The returned value is in the range [0, 1], after applying
	the deadzone.

	If deadzoneThreshold is omitted, defaultDeadzone is used.

	```lua
	local amount = gamepad:getTrigger(Enum.KeyCode.ButtonR2)
	print(amount)
	```
]=]
function Gamepad.getTrigger(self: Gamepad, trigger: Enum.KeyCode, deadzoneThreshold: number?): number
	return applyDeadzone(self.state[trigger].Position.Z, deadzoneThreshold or self.defaultDeadzone)
end

--[=[
	@param gamepadButton Enum.KeyCode
	@return boolean

	Returns true if the given gamepad button is currently pressed.

	This includes regular buttons, thumbstick buttons and
	directional pad inputs.

	```lua
	if gamepad:isButtonDown(Enum.KeyCode.ButtonA) then
		print("Button A is pressed")
	end
	```
]=]
function Gamepad.isButtonDown(self: Gamepad, gamepadButton: Enum.KeyCode): boolean
	return UserInputService:IsGamepadButtonDown(self._gamepad :: any, gamepadButton)
end

--[=[
	@param motor Enum.VibrationMotor
	@return boolean

	Returns true if the given vibration motor is supported
	by the currently associated gamepad.

	```lua
	if gamepad:isMotorSupported(Enum.VibrationMotor.Large) then
		print("Large motor is supported")
	end
	```
]=]
function Gamepad.isMotorSupported(self: Gamepad, motor: Enum.VibrationMotor): boolean
	return HapticService:IsMotorSupported(self._gamepad :: any, motor)
end

--[=[
	@param motor Enum.VibrationMotor
	@param intensity number
	@return number

	Sets the intensity of the given vibration motor.

	The intensity is expected to be in the range [0, 1].

	Returns an internal identifier used to determine whether
	a previously scheduled motor pulse is still valid.

	Calling this method overrides any previously scheduled
	pulse for the same motor.

	```lua
	gamepad:setMotor(Enum.VibrationMotor.Large, 0.5)
	```
]=]
function Gamepad.setMotor(self: Gamepad, motor: Enum.VibrationMotor, intensity: number): number
	self._setMotorIds[motor] += 1
	local id = self._setMotorIds[motor]
	HapticService:SetMotor(self._gamepad :: any, motor, intensity)
	return id
end

--[=[
	@param motor Enum.VibrationMotor
	@param intensity number
	@param duration number

	Activates the given vibration motor for a specified duration.

	When the duration expires, the motor is stopped only if
	no subsequent motor operation has overridden the pulse.

	Calling setMotor, pulseMotor or stopMotor on the same motor
	will override the previously scheduled pulse.

	```lua
	-- Pulses the large motor at 90% intensity for 0.2 seconds.
	gamepad:pulseMotor(Enum.VibrationMotor.Large, 0.9, 0.2)
	```
]=]
function Gamepad.pulseMotor(self: Gamepad, motor: Enum.VibrationMotor, intensity: number, duration: number)
	const id = self:setMotor(motor, intensity)

	const heartbeat = heartbeatDelay(duration, function()
		if self._setMotorIds[motor] ~= id then
			return
		end
		self:stopMotor(motor)
	end)

	self._gamepadScope:add(heartbeat)
end

--[=[
	@param motor Enum.VibrationMotor

	Stops the given vibration motor.
	This is equivalent to setting its intensity to zero.

	```lua
	gamepad:stopMotor(Enum.VibrationMotor.Large)
	```
]=]
function Gamepad.stopMotor(self: Gamepad, motor: Enum.VibrationMotor)
	self:setMotor(motor, 0)
end

--[=[
	Stops all vibration motors supported by the currently
	associated gamepad.

	```lua
	gamepad:stopMotors()
	```
]=]
function Gamepad.stopMotors(self: Gamepad)
	for _, motor in Enum.VibrationMotor:GetEnumItems() do
		if self:isMotorSupported(motor) then
			self:stopMotor(motor)
		end
	end
end

--[=[
	@return boolean

	Returns true if the currently associated gamepad is
	connected.

	Returns false if no gamepad is associated.

	```lua
	if gamepad:isConnected() then
		print("Gamepad connected")
	end
	```
]=]
function Gamepad.isConnected(self: Gamepad): boolean
	return if self._gamepad then UserInputService:GetGamepadConnected(self._gamepad) else false
end

--[=[
	@return Enum.UserInputType?

	Returns the UserInputType of the currently associated gamepad.
	Returns nil if no gamepad is associated.

	```lua
	local inputType = gamepad:getUserInputType()
	```
]=]
function Gamepad.getUserInputType(self: Gamepad): Enum.UserInputType?
	return self._gamepad
end

--[=[
	@param enabled boolean

	Sets GuiService.AutoSelectGuiEnabled.

	This determines whether the Select button automatically
	selects a GUI object.

	This does not enable or disable gamepad GUI navigation.

	```lua
	gamepad:setAutoSelectGui(false)
	```
]=]
function Gamepad.setAutoSelectGui(self: Gamepad, enabled: boolean)
	GuiService.AutoSelectGuiEnabled = enabled
end

--[=[
	@return boolean

	Returns the current value of GuiService.AutoSelectGuiEnabled.

	```lua
	const enabled = gamepad:isAutoSelectGuiEnabled()
	```
]=]
function Gamepad.isAutoSelectGuiEnabled(self: Gamepad): boolean
	return GuiService.AutoSelectGuiEnabled
end

--[=[
	Destroys the Gamepad instance and cleans up all resources
	managed by its internal Scope.

	The instance should no longer be used after destruction.

	```lua
	gamepad:destroy()
	```
]=]
function Gamepad.destroy(self: Gamepad)
	self._scope:destroy()
end

return table.freeze({
	new = Gamepad.new,
})
