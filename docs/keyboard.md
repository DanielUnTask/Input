## Credits
Originally created by **[Stephen Leitnick (Sleitnick)](https://github.com/Sleitnick/RbxUtil/tree/main/modules/input)**.

For more information, see the **[RbxUtil Doc](https://sleitnick.github.io/RbxUtil/api/Keyboard)**.

This version includes minor modifications and adaptations to the original implementation, including API naming conventions, resource management and code structure.
All original credits belong to the original author.

# Keyboard

The `Keyboard` class is part of the Input package. It provides a client-side interface for observing keyboard input and checking whether keys are currently pressed.

```lua
const Keyboard = require(packages.Input).Keyboard
const keyboard = Keyboard.new()
```

Each `Keyboard` instance creates signals for key presses and releases. Its input connections and signals are managed by an internal `Scope` and are cleaned up when the instance is destroyed.

## Usage

```lua
const Keyboard = require(packages.Input).Keyboard
const keyboard = Keyboard.new()

keyboard.keyDown:Connect(function(keyCode, processed)
    print("Key pressed:", keyCode, processed)
end)

keyboard.keyUp:Connect(function(keyCode, processed)
    print("Key released:", keyCode, processed)
end)

if keyboard:isKeyDown(Enum.KeyCode.W) then
    print("Moving forward")
end

-- When the controller is no longer needed:
keyboard:destroy()
```

## Signals

All signals are created and owned by the instance's internal `Scope`. They are cleaned up when `keyboard:destroy()` is called.

| Signal | Arguments | Description |
|---|---|---|
| `keyDown` | `keyCode: Enum.KeyCode, processed: boolean` | Fires when a keyboard key is pressed. |
| `keyUp` | `keyCode: Enum.KeyCode, processed: boolean` | Fires when a keyboard key is released. |

The `processed` argument indicates whether Roblox's input system marked the input as processed.

## Public API

The module returns a frozen table containing `new`. Instances expose the following methods through the `Keyboard` metatable.

### Construction and cleanup

- `Keyboard.new(): Keyboard` — creates a keyboard input controller and connects it to `UserInputService` input events.
- `keyboard:destroy()` — destroys the instance's internal `Scope`, disconnecting its input listeners and cleaning up its owned signals.

### Key state

- `keyboard:isKeyDown(keyCode: Enum.KeyCode): boolean` — checks whether the specified key is currently pressed.
- `keyboard:areKeysDown(keyCodeOne: Enum.KeyCode, keyCodeTwo: Enum.KeyCode): boolean` — checks whether both specified keys are currently pressed. Useful for key combinations.
- `keyboard:areEitherKeysDown(keyCodeOne: Enum.KeyCode, keyCodeTwo: Enum.KeyCode): boolean` — checks whether at least one of the specified keys is currently pressed. Useful when multiple keys trigger the same action.

Example:

```lua
const isShiftA = keyboard:areKeysDown(
    Enum.KeyCode.LeftShift,
    Enum.KeyCode.A
)

const isMovingForward = keyboard:areEitherKeysDown(
    Enum.KeyCode.W,
    Enum.KeyCode.Up
)
```

## Internal structure

The implementation uses:

- `UserInputService` to observe keyboard input and query the current state of keys.
- `Signal` to expose key press and release events.
- `Scope` to own the signals and input connections and clean them up together.

Only inputs whose `UserInputType` is `Enum.UserInputType.Keyboard` are forwarded to the `keyDown` and `keyUp` signals.