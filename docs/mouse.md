## Credits
Originally created by **[Stephen Leitnick (Sleitnick)](https://github.com/Sleitnick/RbxUtil/tree/main/modules/input)**.

For more information, see the **[RbxUtil Doc](https://sleitnick.github.io/RbxUtil/api/Mouse)**.

This version includes minor modifications and adaptations to the original implementation, including API naming conventions, resource management and code structure.
All original credits belong to the original author.

# Mouse

A client-side input controller for capturing mouse input through `UserInputService`.

The `Mouse` module provides signals for mouse button activity, movement, and scrolling, along with methods for querying the current mouse state, retrieving its screen position, projecting a ray into the 3D world, and controlling the mouse lock.

## Usage

```lua
local Mouse = require(path.to.Mouse)

local mouse = Mouse.new()

mouse.leftDown:Connect(function(processed)
    print("Left button pressed", processed)
end)

mouse.moved:Connect(function(position, processed)
    print("Mouse position:", position, processed)
end)

mouse.scrolled:Connect(function(amount, processed)
    print("Scroll amount:", amount, processed)
end)

-- When the controller is no longer needed:
mouse:destroy()
```

## Signals

All signals are created and owned by the instance's internal `Scope`. They are cleaned up when `mouse:destroy()` is called.

| Signal | Arguments | Description |
|---|---|---|
| `leftDown` | `processed: boolean` | Fires when the left mouse button is pressed. |
| `leftUp` | `processed: boolean` | Fires when the left mouse button is released. |
| `rightDown` | `processed: boolean` | Fires when the right mouse button is pressed. |
| `rightUp` | `processed: boolean` | Fires when the right mouse button is released. |
| `middleDown` | `processed: boolean` | Fires when the middle mouse button is pressed. |
| `middleUp` | `processed: boolean` | Fires when the middle mouse button is released. |
| `moved` | `position: Vector2, processed: boolean` | Fires when the mouse moves. The position is taken from the input object's `Position`. |
| `scrolled` | `amount: number, processed: boolean` | Fires when the mouse wheel changes. The amount is taken from `input.Position.Z`. |

The `processed` argument indicates whether Roblox's input system marked the input as processed.

## Public API

The module returns a frozen table containing `new`. Instances expose the following methods through the `Mouse` metatable.

### Construction and cleanup

- `Mouse.new(): Mouse` — creates a mouse controller and connects it to `UserInputService` input events.
- `mouse:destroy()` — destroys the instance's internal `Scope`, disconnecting its input listeners and cleaning up its owned signals.

### Button state

- `mouse:isLeftDown(): boolean` — checks whether the left mouse button is currently pressed.
- `mouse:isRightDown(): boolean` — checks whether the right mouse button is currently pressed.
- `mouse:isMiddleDown(): boolean` — checks whether the middle mouse button is currently pressed.

These methods query `UserInputService:IsMouseButtonPressed`; they do not depend on the button signals.

### Position and movement

- `mouse:getPosition(): Vector2` — returns the mouse's screen position using `UserInputService:GetMouseLocation()`.
- `mouse:getDelta(): Vector2` — returns the mouse movement delta using `UserInputService:GetMouseDelta()`.

### Rays and world projection

- `mouse:getRay(overridePos: Vector2?): Ray` — creates a viewport ray from the current mouse position, or from `overridePos` when supplied.
- `mouse:raycast(raycastParams: RaycastParams, distance: number?, overridePos: Vector2?): RaycastResult?` — raycasts from the mouse ray. The default distance is `1,000` studs.
- `mouse:project(distance: number?, overridePos: Vector2?): Vector3` — calculates the world-space point at the requested distance along the mouse ray. The default distance is `1,000` studs.

Use `raycast` when you need to know whether the ray intersects an object and want the resulting `RaycastResult`. Use `project` when you only need the point along the ray and do not need to detect objects between the origin and that point.

Example:

```lua
local params = RaycastParams.new()
local result = mouse:raycast(params, 200)

if result then
    print("Hit:", result.Instance)
else
    local worldPosition = mouse:project(200)
    print("Projected position:", worldPosition)
end
```

### Mouse locking

- `mouse:lock()` — locks the mouse at its current screen position.
- `mouse:lockCenter()` — locks the mouse to the center of the screen.
- `mouse:unlock()` — restores the default mouse behavior.

**Important:** Unlock the mouse explicitly when you are finished with it. Destroying the `Mouse` instance does not call `unlock()`, because the instance cannot assume ownership of the global mouse lock.

## Internal structure

The implementation uses:

- `UserInputService` to observe mouse input and query mouse state.
- `Signal` to expose mouse events.
- `Scope` to own the signals and input connections and clean them up together.

The ray distance used by `raycast` and `project` when no distance is provided is `1_000` studs.

## Type annotation note

The runtime signal arguments are:

- `moved`: `Vector2, boolean`
- `scrolled`: `number, boolean`
- Button signals: `boolean`

Make sure the exported `Mouse` type reflects these argument lists. In the provided implementation, `moved` and `scrolled` are currently annotated as `Signal.Identity<boolean>`, which does not describe the values actually passed to `Fire()`.
"""