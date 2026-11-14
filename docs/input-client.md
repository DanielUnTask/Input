# InputClient

A client-side input controller that provides access to input contexts, actions, and bindings.

It also exposes utilities for reading action states, managing enabled states, and observing input events.

## Initialization

### `InputClient.start()`

Initializes the input client by retrieving the local player's `PlayerInputs` folder and loading its contexts and actions into the internal cache.

This method must be called before accessing input contexts or actions.

```lua
InputClient.start()
```

**Errors:**
- Throws if the input client has already been started.
- Throws if the player's input container has not been initialized.

## Input Components

The module exposes the following input components:

| Component | Description |
|---|---|
| [`InputClient.Mouse`](mouse.md) | Provides mouse input handling. |
| [`InputClient.Touch`](touch.md) | Provides touch input handling. |
| [`InputClient.Gamepad`](gamepad.md) | Provides gamepad input handling. |
| [`InputClient.Keyboard`](keyboard.md) | Provides keyboard input handling. |

Each component exposes its own constructor through `new()`.

```lua
local mouse = InputClient.Mouse.new()
local keyboard = InputClient.Keyboard.new()
local touch = InputClient.Touch.new()
local gamepad = InputClient.Gamepad.new()
```

## Contexts and Actions

### `InputClient.getContextAsync(contextName: string): InputContext`

Returns the input context with the specified name.

```lua
local context = InputClient:getContextAsync("Gameplay")
```

**Parameters:**
- `contextName` — The name of the context to retrieve.

**Returns:**
- `InputContext` — The requested input context.

**Errors:**
- Throws if the context does not exist.

### `InputClient.getActionAsync(contextName: string, actionName: string): InputAction`

Returns an action from the specified input context.

```lua
local jumpAction = InputClient:getActionAsync("Gameplay", "Jump")
```

**Parameters:**
- `contextName` — The name of the context containing the action.
- `actionName` — The name of the action to retrieve.

**Returns:**
- `InputAction` — The requested input action.

**Errors:**
- Throws if the action does not exist.

### `InputClient.getBindingnAsync(contextName: string, actionName: string, bindingName: string): InputBinding?`

Returns a binding from the specified input action.

Returns `nil` if the binding does not exist.

```lua
local jumpBinding = InputClient:getBindingnAsync(
    "Gameplay",
    "Jump",
    "Space"
)
```

**Parameters:**
- `contextName` — The name of the context containing the action.
- `actionName` — The name of the action containing the binding.
- `bindingName` — The name of the binding to retrieve.

**Returns:**
- `InputBinding?` — The requested binding, or `nil` if it does not exist.

## Reading Action State

### `InputClient.readActionAsync<T>(contextName: string, actionName: string, fallbackValue: T): ActionValue<T>`

Returns the current state of an input action.

If the action cannot be retrieved, the provided fallback value is returned instead.

```lua
local isJumping = InputClient:readActionAsync(
    "Gameplay",
    "Jump",
    false
)
```

**Parameters:**
- `contextName` — The name of the context containing the action.
- `actionName` — The name of the action to read.
- `fallbackValue` — The value returned if the action is unavailable.

**Returns:**
- `T` — The current action state or the fallback value.

## Enabling and Disabling

### `InputClient.setContextEnabledAsync(contextName: string, state: boolean)`

Enables or disables the specified input context.

Does nothing if the context cannot be found.

```lua
InputClient:setContextEnabledAsync("Gameplay", false)
```

**Parameters:**
- `contextName` — The name of the context to update.
- `state` — Whether the context should be enabled.

### `InputClient.setActionEnabledAsync(contextName: string, actionName: string, state: boolean)`

Enables or disables an action within the specified input context.

Does nothing if the action cannot be found.

```lua
InputClient:setActionEnabledAsync("Gameplay", "Jump", false)
```

**Parameters:**
- `contextName` — The name of the context containing the action.
- `actionName` — The name of the action to update.
- `state` — Whether the action should be enabled.

### `InputClient.setGroupActionEnabledAsync(contextName: string, actions: {string}, states: {boolean})`

Updates the enabled state of multiple actions within the same context.

Each action is assigned the state at the corresponding index in the `states` array.

```lua
InputClient:setGroupActionEnabledAsync(
    "Gameplay",
    { "Jump", "Sprint", "Crouch" },
    { true, false, true }
)
```

**Parameters:**
- `contextName` — The name of the context containing the actions.
- `actions` — An array of action names to update.
- `states` — An array of enabled states corresponding to each action.

## Action Events

### `InputClient.onPress(contextName: string, actionName: string, callback: () -> ()): RBXScriptConnection?`

Connects a callback to an action's `Pressed` event.

The callback is invoked whenever the action is pressed.

```lua
local connection = InputClient:onPress("Gameplay", "Jump", function()
    print("Jump pressed")
end)
```

**Parameters:**
- `contextName` — The name of the context containing the action.
- `actionName` — The name of the action to observe.
- `callback` — The function called when the action is pressed.

**Returns:**
- `RBXScriptConnection?` — The event connection, or `nil` if the action is unavailable.

### `InputClient.onRelease(contextName: string, actionName: string, callback: () -> ()): RBXScriptConnection?`

Connects a callback to an action's `Released` event.

The callback is invoked whenever the action is released.

```lua
local connection = InputClient:onRelease("Gameplay", "Jump", function()
    print("Jump released")
end)
```

**Parameters:**
- `contextName` — The name of the context containing the action.
- `actionName` — The name of the action to observe.
- `callback` — The function called when the action is released.

**Returns:**
- `RBXScriptConnection?` — The event connection, or `nil` if the action is unavailable.

### `InputClient.onStateChanged<T>(contextName: string, actionName: string, callback: (state: T) -> ()): RBXScriptConnection?`

Connects a callback to an action's `StateChanged` event.

The callback receives the new action state whenever it changes.

```lua
local connection = InputClient:onStateChanged(
    "Gameplay",
    "Move",
    function(state)
        print("New state:", state)
    end
)
```

**Parameters:**
- `contextName` — The name of the context containing the action.
- `actionName` — The name of the action to observe.
- `callback` — The function called with the new action state.

**Returns:**
- `RBXScriptConnection?` — The event connection, or `nil` if the action is unavailable.

## Action Observer

### `InputClient.observerAction(contextName: string, actionName: string, callback: () -> (() -> ())?): () -> ()`

Creates an observer that manages callbacks across an action's pressed and released states.

The provided callback is executed when the action is pressed. It can optionally return a cleanup function, which is executed when the action is released.

The returned function disconnects the observer and releases its connections.

```lua
local stopObserving = InputClient:observerAction(
    "Gameplay",
    "Sprint",
    function()
        print("Started sprinting")

        return function()
            print("Stopped sprinting")
        end
    end
)

-- Stop observing the action
stopObserving()
```

**Parameters:**
- `contextName` — The name of the context containing the action.
- `actionName` — The name of the action to observe.
- `callback` — The function called when the action is pressed. Can optionally return a cleanup function executed on release.

**Returns:**
- `() -> ()` — A function that stops observing the action and cleans up its connections.

## Types

The module exports the following types:

| Type | Description |
|---|---|
| `InputClient` | The type of the InputClient module. |
| `ActionValue<T>` | Represents the value returned by `readActionAsync`. |
| `Mouse` | The Mouse component type. |
| `Touch` | The Touch component type. |
| `Gamepad` | The Gamepad component type. |
| `Keyboard` | The Keyboard component type. |
| `PreferredInput` | The PreferredInput component type. |

## Notes

- `InputClient` is intended to run on the client.
- Call `start()` before accessing contexts or actions.
- Contexts and actions are cached internally during initialization.
- Methods ending in `Async` do not necessarily yield. They are named this way to distinguish operations that depend on initialized player input data.
- `readActionAsync` provides a fallback value when the requested action cannot be retrieved.
- `setContextEnabledAsync` and `setActionEnabledAsync` silently do nothing when their targets are unavailable.
- Event methods return their corresponding `RBXScriptConnection`, allowing callers to disconnect listeners manually.
- `observerAction` returns a cleanup function that disconnects both the pressed and released listeners.