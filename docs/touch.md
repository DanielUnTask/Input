## Credits
Originally created by **[Stephen Leitnick (Sleitnick)](https://github.com/Sleitnick/RbxUtil/tree/main/modules/input)**.

For more information, see the **[RbxUtil Doc](https://sleitnick.github.io/RbxUtil/api/Touch)**.

This version includes minor modifications and adaptations to the original implementation, including API naming conventions, resource management and code structure.
All original credits belong to the original author.

# Touch

A touch input class that provides signals for detecting and handling touch interactions through `UserInputService`.

## Constructor

### `Touch.new(): Touch`

Creates a new touch input class.

The class wraps Roblox touch events into signals and manages their connections through an internal `Scope`.

```lua
local touch = Touch.new()
```

## Signals

All signals are connected to their corresponding `UserInputService` events and forward their arguments.

| Signal | Arguments | Description |
|---|---|---|
| `tap` | `touchPositions: {Vector2}`, `processed: boolean` | Fires when the user taps the screen. |
| `tapInWorld` | `position: Vector2`, `processed: boolean` | Fires when the user taps a position in the 3D world. |
| `moved` | `touch: InputObject`, `processed: boolean` | Fires when a touch input changes position. |
| `longProgress` | `touchPositions: {Vector2}`, `state: Enum.UserInputState`, `processed: boolean` | Fires during a long-press gesture. |
| `pan` | `touchPositions: {Vector2}`, `totalTranslation: Vector2`, `velocity: Vector2`, `state: Enum.UserInputState`, `processed: boolean` | Fires when the user performs a pan gesture. |
| `pinch` | `touchPositions: {Vector2}`, `scale: number`, `velocity: Vector2`, `state: Enum.UserInputState`, `processed: boolean` | Fires when the user performs a pinch gesture. |
| `rotate` | `touchPositions: {Vector2}`, `rotation: number`, `velocity: number`, `state: Enum.UserInputState`, `processed: boolean` | Fires when the user performs a rotation gesture. |
| `swipe` | `swipeDirection: Enum.SwipeDirection`, `numberOfTouches: number`, `processed: boolean` | Fires when the user performs a swipe gesture. |
| `touchStarted` | `touch: InputObject`, `processed: boolean` | Fires when a touch input begins. |
| `touchEnded` | `touch: InputObject`, `processed: boolean` | Fires when a touch input ends. |

### Example

```lua
local touch = Touch.new()

touch.tap:Connect(function(positions, processed)
    print("Tap:", positions, processed)
end)

touch.pan:Connect(function(positions, translation, velocity, state, processed)
    print("Pan:", translation, velocity, state)
end)

touch.swipe:Connect(function(direction, touchCount, processed)
    print("Swipe:", direction, touchCount)
end)
```

## Public Methods

### `Touch:isTouchEnabled(): boolean`

Returns whether touch input is enabled on the current device.

This is a proxy for `UserInputService.TouchEnabled`.

```lua
if touch:isTouchEnabled() then
    print("Touch input is available")
end
```

### `Touch:Destroy()`

Destroys the touch input controller and releases all resources managed by its internal `Scope`, including signal connections.

```lua
touch:Destroy()
```

## Internal Structure

- **Scope** — Manages the lifetime of the controller's resources and connections.
- **Signal** — Provides the signals used to expose touch input events.

## Notes

- The controller does not implement gesture recognition itself; it exposes the touch events provided by `UserInputService`.
- The `processed` argument indicates whether the input was already processed by Roblox or another input handler.
- Gesture signals may fire multiple times during a gesture, depending on their associated `Enum.UserInputState`.
- Call `Destroy()` when the controller is no longer needed to release its resources.