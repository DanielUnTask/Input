# InputServer

A server-side input controller that manages player input contexts and actions.

It provides utilities for registering player input templates, initializing input data for players, retrieving contexts and actions, reading action states, and managing their enabled states.

## Initialization

### `InputServer.registerPlayerInput(container: Folder)`

Registers the template used to create each player's input container.

The provided folder is cloned for every player when their input system is initialized.

This method must be called before `start()`. Only one template can be registered.

```lua
InputServer:registerPlayerInput(
    game.ServerStorage.PlayerInputs
)
```

**Parameters:**
- `container` — The folder used as the player input template.

**Errors:**
- Throws if the server has already started.
- Throws if a template has already been registered.

### `InputServer.start()`

Starts the server-side input system.

Initializes the input system for all players currently in the server and connects to `Players.PlayerAdded` and `Players.PlayerRemoving` to handle future players.

A player input template must be registered beforehand.

```lua
InputServer:registerPlayerInput(
    game.ServerStorage.PlayerInputs
)

InputServer:start()
```

**Errors:**
- Throws if the server has already started.
- Throws if no player input template has been registered.

## Contexts and Actions

### `InputServer.getContextAsync(player: Player, contextName: string): InputContext?`

Returns an input context belonging to the specified player.

Returns `nil` if the player has not been initialized. Throws if the player is initialized but the context does not exist.

```lua
local context = InputServer:getContextAsync(
    player,
    "Gameplay"
)
```

**Parameters:**
- `player` — The player owning the context.
- `contextName` — The name of the context to retrieve.

**Returns:**
- `InputContext?` — The requested context, or `nil` if the player is unavailable.

### `InputServer.getActionAsync(player: Player, contextName: string, actionName: string): InputAction?`

Returns an action from the specified player's input context.

Returns `nil` if the player has not been initialized. Throws if the player is initialized but the action does not exist.

```lua
local jumpAction = InputServer:getActionAsync(
    player,
    "Gameplay",
    "Jump"
)
```

**Parameters:**
- `player` — The player owning the action.
- `contextName` — The name of the context containing the action.
- `actionName` — The name of the action to retrieve.

**Returns:**
- `InputAction?` — The requested action, or `nil` if the player is unavailable.

## Reading Action State

### `InputServer.readActionAsync<T>(player: Player, contextName: string, actionName: string, fallbackValue: T): ActionValue<T>`

Returns the current state of an input action belonging to a player.

If the player or action is unavailable, the provided fallback value is returned instead.

```lua
local isJumping = InputServer:readActionAsync(
    player,
    "Gameplay",
    "Jump",
    false
)
```

**Parameters:**
- `player` — The player owning the action.
- `contextName` — The name of the context containing the action.
- `actionName` — The name of the action to read.
- `fallbackValue` — The value returned if the action is unavailable.

**Returns:**
- `T` — The current action state or the fallback value.

## Enabling and Disabling

### `InputServer.setContextEnabledAsync(player: Player, contextName: string, state: boolean)`

Enables or disables an input context for the specified player.

Does nothing if the player or context cannot be found.

```lua
InputServer:setContextEnabledAsync(
    player,
    "Gameplay",
    false
)
```

**Parameters:**
- `player` — The player owning the context.
- `contextName` — The name of the context to update.
- `state` — Whether the context should be enabled.

### `InputServer.setActionEnabledAsync(player: Player, contextName: string, actionName: string, state: boolean)`

Enables or disables an action within a player's input context.

Does nothing if the player or action cannot be found.

```lua
InputServer:setActionEnabledAsync(
    player,
    "Gameplay",
    "Jump",
    false
)
```

**Parameters:**
- `player` — The player owning the action.
- `contextName` — The name of the context containing the action.
- `actionName` — The name of the action to update.
- `state` — Whether the action should be enabled.

### `InputServer.setGroupActionEnabledAsync(player: Player, contextName: string, actions: {string}, states: {boolean})`

Updates the enabled state of multiple actions within a player's context.

Each action is assigned the state at the corresponding index in the `states` array.

Does nothing if the player has not been initialized.

```lua
InputServer:setGroupActionEnabledAsync(
    player,
    "Gameplay",
    { "Jump", "Sprint", "Crouch" },
    { true, false, true }
)
```

**Parameters:**
- `player` — The player owning the actions.
- `contextName` — The name of the context containing the actions.
- `actions` — An array of action names to update.
- `states` — An array of enabled states corresponding to each action.

## Internal Methods

The following methods are used internally to manage player lifecycle events.

| Method | Description |
|---|---|
| `_playerAdded(player: Player)` | Initializes a player's input container, contexts, and actions. |
| `_removePlayer(player: Player)` | Removes a player's input data from the internal caches. |

## Types

The module exports the following types:

| Type | Description |
|---|---|
| `InputServer` | The type of the InputServer module. |
| `ActionValue<T>` | Represents the value returned by `readActionAsync`. |

## Notes

- `InputServer` is intended to run on the server.
- A player input template must be registered before calling `start()`.
- Each player receives an independent clone of the registered template.
- Player contexts and actions are cached separately.
- `getContextAsync` and `getActionAsync` return `nil` if the player has not been initialized.
- These methods throw an error if the player exists in the cache but the requested context or action does not.
- `readActionAsync` provides a fallback value when the requested action cannot be retrieved.
- The enabled-state methods silently do nothing when their targets are unavailable.
- Methods ending in `Async` do not necessarily yield. They are named this way to distinguish operations that depend on initialized player input data.