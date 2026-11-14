--!strict
const InputServer = {}

--- Services
const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

--- Requires
const Utility = require("./internal/utility")

--- Constants
const ready: { [Player]: boolean } = {}
const cache: {
	contexts: { [Player]: Utility.ContextCache },
	actions: { [Player]: Utility.ActionCache },
} = {
	contexts = {},
	actions = {},
}

--- Variables
local started = false
local playerInputTemplate: Folder? = nil

--- Types
export type InputServer = typeof(InputServer)
export type ActionValue<T = nil> = T

--- Private Methods

--[=[
    Initializes the input system for a player.

    Creates the player's input container from the registered template,
    caches its contexts and actions, and parents it to the player.

    Does nothing if the player is already initialized or is no longer
    a descendant of Players.

    @param player Player -- The player to initialize.
    @private
    @within InputServer
]=]
function InputServer._playerAdded(player: Player)
	if ready[player] or player.Parent ~= Players then
		return
	end

	ready[player] = true
	cache.actions[player] = {}
	cache.contexts[player] = {}

	const playerInputs = (playerInputTemplate :: Folder):Clone()
	playerInputs.Name = "PlayerInputs"

	Utility.addContexts(cache.contexts[player], cache.actions[player], playerInputs)

	playerInputs.Parent = player
end

--[=[
    Removes a player's input data from the internal caches.

    Does nothing if the player has not been initialized.

    @param player Player -- The player whose input data should be removed.
    @private
    @within InputServer
]=]
function InputServer._removePlayer(player: Player)
	if not ready[player] then
		return
	end

	ready[player] = nil
	cache.contexts[player] = nil
	cache.actions[player] = nil
end

--- Public Methods

--[=[
    Starts the server-side input system.

    Initializes the input system for all players currently in the server
    and connects to PlayerAdded and PlayerRemoving to handle future players.

    Requires a player input template to be registered beforehand.

    @error Throws if the server has already started.
    @error Throws if no player input template has been registered.

    @within InputServer
]=]
function InputServer.start(self: InputServer)
	assert(not started, "[InputServer]: already started.")
	assert(playerInputTemplate, "[InputServer]: Player input template is not registered.")

	for _, player in Players:GetPlayers() do
		task.spawn(self._playerAdded, player)
	end

	Players.PlayerAdded:Connect(self._playerAdded)
	Players.PlayerRemoving:Connect(self._removePlayer)
end

--[=[
    Registers the template used to create each player's input container.

    The provided folder is cloned for every player when their input system
    is initialized.

    Must be called before starting the input server.
    Only one template can be registered.

    @param container Folder -- The folder used as the player input template.

    @error Throws if the server has already started.
    @error Throws if a template has already been registered.

    @within InputServer
]=]
function InputServer.registerPlayerInput(self: InputServer, container: Folder)
	assert(not started, "[InputServer]: Cannot register player inputs after startup.")
	assert(not playerInputTemplate, "[InputServer]: Player input is already registered.")
	playerInputTemplate = container
end

--[=[
    Returns an input context belonging to the specified player.

    Returns nil if the player has not been initialized.
    Throws if the player is initialized but the context does not exist.

    @param player Player -- The player owning the context.
    @param contextName string -- The name of the context to retrieve.
    @return InputContext? -- The requested context, or nil if the player is unavailable.

    @within InputServer
]=]
function InputServer.getContextAsync(self: InputServer, player: Player, contextName: string): InputContext?
	const raw = cache.contexts[player]
	if not raw then
		return nil
	end

	const context = Utility.getContext(raw, contextName)
	return assert(context, `[InputServer]: {player.Name} - Context {contextName} not found`)
end

--[=[
    Returns an action from the specified player's input context.

    Returns nil if the player has not been initialized.
    Throws if the player is initialized but the action does not exist.

    @param player Player -- The player owning the action.
    @param contextName string -- The name of the context containing the action.
    @param actionName string -- The name of the action to retrieve.
    @return InputAction? -- The requested action, or nil if the player is unavailable.

    @within InputServer
]=]
function InputServer.getActionAsync(
	self: InputServer,
	player: Player,
	contextName: string,
	actionName: string
): InputAction?
	const rawContexts = cache.contexts[player]
	const rawActions = cache.actions[player]
	if not rawContexts or not rawActions then
		return nil
	end

	const action = Utility.getContextAction(rawContexts, rawActions, contextName, actionName)
	return assert(action, `[InputServer]: {player.Name} - Action {actionName} not found in context {contextName}`)
end

--[=[
    Returns the current state of an input action belonging to a player.

    If the player or action is unavailable, the provided fallback value
    is returned instead.

    @generic T
    @param player Player -- The player owning the action.
    @param contextName string -- The name of the context containing the action.
    @param actionName string -- The name of the action to read.
    @param fallbackValue T -- The value returned if the action is unavailable.
    @return T -- The current action state or the fallback value.

    @within InputServer
]=]
function InputServer.readActionAsync<T>(
	self: InputServer,
	player: Player,
	contextName: string,
	actionName: string,
	fallbackValue: T
): ActionValue<T>
	const ok, action = pcall(self.getActionAsync, self, player, contextName, actionName)
	if not ok or not action then
		return fallbackValue
	end
	return action:GetState()
end

--[=[
    Enables or disables an input context for the specified player.

    Does nothing if the player or context cannot be found.

    @param player Player -- The player owning the context.
    @param contextName string -- The name of the context to update.
    @param state boolean -- Whether the context should be enabled.

    @within InputServer
]=]
function InputServer.setContextEnabledAsync(self: InputServer, player: Player, contextName: string, state: boolean)
	const _, context = pcall(self.getContextAsync, self, player, contextName)
	if context then
		context.Enabled = state
	end
end

--[=[
    Enables or disables an action within a player's input context.

    Does nothing if the player or action cannot be found.

    @param player Player -- The player owning the action.
    @param contextName string -- The name of the context containing the action.
    @param actionName string -- The name of the action to update.
    @param state boolean -- Whether the action should be enabled.

    @within InputServer
]=]
function InputServer.setActionEnabledAsync(
	self: InputServer,
	player: Player,
	contextName: string,
	actionName: string,
	state: boolean
)
	const _, action = pcall(self.getActionAsync, self, player, contextName, actionName)
	if action then
		action.Enabled = state
	end
end

--[=[
    Updates the enabled state of multiple actions within a player's context.

    Each action is assigned the state at the corresponding index in the states array.
    Does nothing if the player has not been initialized.

    @param player Player -- The player owning the actions.
    @param contextName string -- The name of the context containing the actions.
    @param actions {string} -- The names of the actions to update.
    @param states {boolean} -- The enabled states corresponding to each action.

    @within InputServer
]=]
function InputServer.setGroupActionEnabledAsync(
	self: InputServer,
	player: Player,
	contextName: string,
	actions: { string },
	states: { boolean }
)
	if not ready[player] then
		return
	end
	for index, actionName in ipairs(actions) do
		self:setActionEnabledAsync(player, contextName, actionName, states[index])
	end
end

return if RunService:IsServer() then InputServer :: InputServer else {} :: InputServer
