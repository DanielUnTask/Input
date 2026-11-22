--!strict
const InputClient = {}

--- Services
const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

--- Requires
const Mouse = require("./components/mouse")
const Touch = require("./components/touch")
const Gamepad = require("./components/gamepad")
const Keyboard = require("./components/keyboard")
const PreferredInput = require("./components/preferredInput")

const Scope = require("./internal/scope")
const Utility = require("./internal/utility")

--- Constants
const cache: {
	contexts: Utility.ContextCache,
	actions: Utility.ActionCache,
} = {
	contexts = {},
	actions = {},
}

--- Variables
local started = false
local localPlayer = Players.LocalPlayer -- nil in server

--- Types
export type Touch = Touch.Touch
export type Mouse = Mouse.Mouse
export type Gamepad = Gamepad.Gamepad
export type Keyboard = Keyboard.Keyboard
export type PreferredInput = PreferredInput.PreferredInput

export type InputClient = typeof(InputClient)
export type ActionValue<T = nil> = T

--- Public Methods
InputClient.Mouse = Mouse
InputClient.Touch = Touch
InputClient.Gamepad = Gamepad
InputClient.Keyboard = Keyboard
InputClient.PreferredInput = PreferredInput

--[=[
    Initializes the input client and loads the player's input contexts and actions.

    This method must be called before accessing input contexts or actions.
    Can only be called once.

    @within InputClient
]=]
function InputClient.start(self: InputClient)
	assert(not started, "[InputClient]: already started.")

	const playerInputs = localPlayer:WaitForChild("PlayerInputs")
	assert(playerInputs, `[InputClient]: Player inputs are not initialized.`)
	Utility.addContexts(cache.contexts, cache.actions, playerInputs)
end

--[=[
    Returns the input context with the given name.

    @param contextName string -- The name of the context to retrieve.
    @return InputContext -- The requested input context.

    @error Throws if the context does not exist.

    @within InputClient
]=]
function InputClient.getContextAsync(self: InputClient, contextName: string): InputContext?
	const context = Utility.getContext(cache.contexts, contextName)
	return assert(context, `[InputClient]: Context {contextName} not found.`)
end

--[=[
    Returns an action from the specified input context.

    @param contextName string -- The name of the context containing the action.
    @param actionName string -- The name of the action to retrieve.
    @return InputAction -- The requested input action.

    @error Throws if the action does not exist.

    @within InputClient
]=]
function InputClient.getActionAsync(self: InputClient, contextName: string, actionName: string): InputAction?
	const action = Utility.getContextAction(cache.contexts, cache.actions, contextName, actionName)
	return assert(action, `[InputClient]: Action {actionName} not found in context {contextName}`)
end

--[=[
    Returns a binding from the specified input action.

    @param contextName string -- The name of the context containing the action.
    @param actionName string -- The name of the action containing the binding.
    @param bindingName string -- The name of the binding to retrieve.
    @return InputBinding? -- The requested binding, or nil if it does not exist.

    @within InputClient
]=]
function InputClient.getBindingnAsync(
	self: InputClient,
	contextName: string,
	actionName: string,
	bindingName: string
): InputBinding?
	const action = self:getActionAsync(contextName, actionName)
	return action and (action:FindFirstChild(bindingName) :: InputBinding?) or nil
end

--[=[
    Returns the current state of an input action.

    If the action cannot be retrieved, the provided fallback value is returned instead.

    @generic T
    @param contextName string -- The name of the context containing the action.
    @param actionName string -- The name of the action to read.
    @param fallbackValue T -- The value returned if the action is unavailable.
    @return T -- The action state or the fallback value.

    @within InputClient
]=]
function InputClient.readActionAsync<T>(
	self: InputClient,
	contextName: string,
	actionName: string,
	fallbackValue: T
): ActionValue<T>
	const ok, action = pcall(self.getActionAsync, self, contextName, actionName)
	if not ok or not action then
		return fallbackValue
	end
	return action:GetState()
end

--[=[
    Enables or disables the specified input context.

    Does nothing if the context cannot be found.

    @param contextName string -- The name of the context to update.
    @param state boolean -- Whether the context should be enabled.

    @within InputClient
]=]
function InputClient.setContextEnabledAsync(self: InputClient, contextName: string, state: boolean)
	const _, context = pcall(self.getContextAsync, self, contextName)
	if context then
		context.Enabled = state
	end
end

--[=[
    Enables or disables an action within the specified input context.

    Does nothing if the action cannot be found.

    @param contextName string -- The name of the context containing the action.
    @param actionName string -- The name of the action to update.
    @param state boolean -- Whether the action should be enabled.

    @within InputClient
]=]
function InputClient.setActionEnabledAsync(self: InputClient, contextName: string, actionName: string, state: boolean)
	const _, action = pcall(self.getActionAsync, self, contextName, actionName)
	if action then
		action.Enabled = state
	end
end

--[=[
    Updates the enabled state of multiple actions within the same context.

    Each action is assigned the state at the corresponding index in the states array.

    @param contextName string -- The name of the context containing the actions.
    @param actions {string} -- The names of the actions to update.
    @param states {boolean} -- The enabled states corresponding to each action.

    @within InputClient
]=]
function InputClient.setGroupActionEnabledAsync(
	self: InputClient,
	contextName: string,
	actions: { string },
	states: { boolean }
)
	for index, actionName in ipairs(actions) do
		self:setActionEnabledAsync(contextName, actionName, states[index])
	end
end

--[=[
    Connects a callback to an action's Pressed event.

    The callback is invoked whenever the action is pressed.

    @param contextName string -- The name of the context containing the action.
    @param actionName string -- The name of the action to observe.
    @param callback () -> () -- The function called when the action is pressed.
    @return RBXScriptConnection? -- The event connection, or nil if the action is unavailable.

    @within InputClient
]=]
function InputClient.onPress(
	self: InputClient,
	contextName: string,
	actionName: string,
	callback: () -> ()
): RBXScriptConnection?
	const action: InputAction? = self:getActionAsync(contextName, actionName)
	return action and action.Pressed:Connect(callback)
end

--[=[
    Connects a callback to an action's Released event.
    The callback is invoked whenever the action is released.

    @param contextName string -- The name of the context containing the action.
    @param actionName string -- The name of the action to observe.
    @param callback () -> () -- The function called when the action is released.
    @return RBXScriptConnection? -- The event connection, or nil if the action is unavailable.

    @within InputClient
]=]
function InputClient.onRelease(
	self: InputClient,
	contextName: string,
	actionName: string,
	callback: () -> ()
): RBXScriptConnection?
	const action: InputAction? = self:getActionAsync(contextName, actionName)
	return action and action.Released:Connect(callback)
end

--[=[
    Connects a callback to an action's StateChanged event.
    The callback receives the new state whenever the action's state changes.

    @generic T
    @param contextName string -- The name of the context containing the action.
    @param actionName string -- The name of the action to observe.
    @param callback (state: T) -> () -- The function called with the new action state.
    @return RBXScriptConnection? -- The event connection, or nil if the action is unavailable.

    @within InputClient
]=]
function InputClient.onStateChanged<T>(
	self: InputClient,
	contextName: string,
	actionName: string,
	callback: (state: T) -> ()
): RBXScriptConnection?
	const action: InputAction? = self:getActionAsync(contextName, actionName)
	return action and action.StateChanged:Connect(callback)
end

--[=[
    Observes an action and manages resources across its pressed and released states.

    The callback is executed when the action is pressed. It can optionally return
    a cleanup function, which is executed when the action is released.

    The returned function disconnects the observer and releases its connections.

    @param contextName string -- The name of the context containing the action.
    @param actionName string -- The name of the action to observe.
    @param callback () -> (() -> ())? -- The function called on press, optionally returning a cleanup function.
    @return () -> () -- A function that stops observing the action.

    @within InputClient
]=]
function InputClient.observerAction(
	self: InputClient,
	contextName: string,
	actionName: string,
	callback: () -> (() -> ())?
): () -> ()
	const scope = Scope.new()
	local cleanup: (() -> ())?

	const function pressCallback()
		const useCleanup = callback()
		if typeof(useCleanup) == "function" then
			cleanup = useCleanup
		end
	end

	const function releaseCallback()
		if typeof(cleanup) == "function" then
			cleanup()
		end
	end

	scope:add(self:onPress(contextName, actionName, pressCallback))
	scope:add(self:onRelease(contextName, actionName, releaseCallback))

	return function()
		scope:destroy()
	end
end

return if RunService:IsClient() then InputClient :: InputClient else {} :: InputClient
