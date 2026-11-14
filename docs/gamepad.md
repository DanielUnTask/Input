## Credits
Originally created by **[Stephen Leitnick (Sleitnick)](https://github.com/Sleitnick/RbxUtil/tree/main/modules/input)**.

For more information, see the **[RbxUtil Doc](https://sleitnick.github.io/RbxUtil/api/Gamepad)**.

This version includes minor modifications and adaptations to the original implementation, including API naming conventions, resource management and code structure.
All original credits belong to the original author.

# Gamepad

`Gamepad` is a client-side class that provides an abstraction over Roblox gamepad input.
It handles gamepad connections, button events, analog input, vibration motors and GUI navigation settings.
The instance can either automatically track the currently active gamepad or remain bound to a specific `Enum.UserInputType`.

## Installation

```lua
const Gamepad = require(packages.Input).Gamepad
const gamepad = Gamepad.new()
```

By default, the instance automatically tracks the active gamepad. This is the recommended approach for most use cases.

## Properties

### `defaultDeadzone`

**Type:** `number`

**Default:** `0.05`

Defines the default deadzone threshold used by `getThumbstick` and `getTrigger`.

A deadzone prevents small analog input values from being registered. This is particularly useful for avoiding unwanted movement caused by controller stick drift.

Both methods allow overriding this value through their `deadzoneThreshold` parameter.

### `supportsVibration`

**Type:** `boolean`

**Read-only.**

Indicates whether the currently associated gamepad supports haptic vibration.

This property is automatically updated whenever the active gamepad changes.

### `state`

**Type:** `{ [Enum.KeyCode]: InputObject }`

Contains the current `InputObject` references associated with the gamepad's inputs.

Each entry is indexed by its corresponding `Enum.KeyCode`.

```lua
const leftThumbstick = gamepad.state[Enum.KeyCode.Thumbstick1]
print(leftThumbstick.Position)
```

**Important:** Do not cache references from this table.

The contents are cleared and populated again whenever the associated gamepad changes. Always retrieve the required `InputObject` directly from `state` when needed.

For ordinary input reading, prefer `getThumbstick` and `getTrigger`.

## Signals

All signals are managed by the instance's internal `Scope`.

### `buttonDown`

**Type:** `Signal.Identity<Enum.KeyCode, boolean>`

Fires whenever a button belonging to the associated gamepad is pressed.

Provides:
- `button`: The pressed `Enum.KeyCode`.
- `processed`: Whether the input was processed.

### `buttonUp`

**Type:** `Signal.Identity<Enum.KeyCode, boolean>`

Fires whenever a button belonging to the associated gamepad is released.

Provides:
- `button`: The released `Enum.KeyCode`.
- `processed`: Whether the input was processed.

### `connected`

**Type:** `Signal.Identity<>`

Fires when the instance transitions from having no associated gamepad to having a connected gamepad.

This signal does not fire when switching directly between two gamepads.

### `disconnected`

**Type:** `Signal.Identity<>`

Fires when the associated gamepad becomes unavailable.

This signal does not fire when switching directly between two connected gamepads.

### `gamepadChanged`

**Type:** `Signal.Identity<Enum.UserInputType?>`

Fires whenever the associated gamepad changes.

Provides the new `Enum.UserInputType`, or `nil` when no gamepad is associated.

Unlike `connected` and `disconnected`, this signal also detects direct switches between gamepads.

The instance automatically updates its internal state, so no additional instance needs to be created.

## Internal Architecture

### Gamepad Selection

The class supports two operating modes:

**Dynamic Gamepad**

When no `Enum.UserInputType` is provided, the instance automatically determines the active gamepad.

It prioritizes navigation gamepads when multiple navigation devices are available. Otherwise, it falls back to connected gamepads.

**Forced Gamepad**

When a specific `Enum.UserInputType` is provided, the instance only tracks that particular gamepad.

For example:

```lua
const gamepad = Gamepad.new(Enum.UserInputType.Gamepad1)
```

### Deadzone Processing

Analog values are processed through a deadzone function.

Values below the configured threshold are treated as zero. Values outside the deadzone are remapped to preserve the remaining analog range.

The original sign of the input is preserved.

### Vibration Management

Each vibration motor maintains an internal identifier.

Whenever a motor receives a new operation, its identifier is incremented. Scheduled pulses use this identifier to determine whether they are still valid.

This prevents an older pulse from stopping a motor that has subsequently received another operation.

### Resource Management

The class uses two `Scope` instances:

- `_scope`: Manages the instance's general connections and resources.
- `_gamepadScope`: Manages resources associated with the currently active gamepad.

Whenever the associated gamepad changes, `_gamepadScope` is cleaned up before configuring the new gamepad.

Destroying the instance destroys the main scope, which also handles the nested scope and its resources.

## Dependencies

The implementation depends on the following modules and Roblox services.

### Internal Modules

- `Scope`: Resource and connection management.
- `Signal`: Custom signal implementation.

### Roblox Services

- `RunService`: Used to schedule vibration pulse expiration through `Heartbeat`.
- `GuiService`: Controls automatic GUI selection.
- `HapticService`: Handles vibration support and motor operations.
- `UserInputService`: Handles gamepad connections, button events and input state.

## Usage Example

```lua
const Gamepad = require(packages.Input).Gamepad

const gamepad = Gamepad.new()

gamepad.connected:Connect(function()
    print("Gamepad connected")
end)

gamepad.disconnected:Connect(function()
    print("Gamepad disconnected")
end)

gamepad.gamepadChanged:Connect(function(inputType)
    print("Active gamepad:", inputType)
end)

gamepad.buttonDown:Connect(function(button, processed)
    if button == Enum.KeyCode.ButtonA then
        print("Button A pressed")
    end
end)

const movement = gamepad:getThumbstick(Enum.KeyCode.Thumbstick1)
const trigger = gamepad:getTrigger(Enum.KeyCode.ButtonR2)
```

## Considerations

- This class is intended for client-side usage.
- Prefer dynamic gamepad selection unless a specific device is required.
- Use `gamepadChanged` to detect every change in the associated gamepad.
- Avoid caching `InputObject` references from `state`.
- Configure `defaultDeadzone` according to the desired analog input sensitivity.
- Check `supportsVibration` when vibration support needs to be displayed or handled explicitly.
- Always call `destroy()` when the instance is no longer needed.
- `isAutoSelectGuiEnabled()` is a static function and does not require an instance.