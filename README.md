# InputSystem

## [WALLY]("https://wally.run/package/danieluntask/input?version=0.0.1")

A modular input management system for Roblox, designed to provide a unified way to handle player input across different devices.

InputSystem separates client-side and server-side responsibilities, allowing developers to manage input contexts, actions, and bindings while supporting multiple input methods.

## Features

- **Multi-device support** — Handles mouse, keyboard, touch, and gamepad input.
- **Context management** — Organizes input actions into independent contexts.
- **Action management** — Enables, disables, and reads the state of individual actions.
- **Event-driven API** — Provides signals and callbacks for responding to input events.
- **Player-specific input** — Each player receives an independent input configuration.
- **Resource management** — Uses an internal `Scope` system to manage connections and resources.
- **Type safety** — Built with Luau strict type checking.

## Documentation

Explore the documentation for each module:

### Main Modules

| Module | Description |
|---|---|
| [InputClient](docs/input-client.md) | Client-side input management, including contexts, actions, bindings, and input events. |
| [InputServer](docs/input-server.md) | Server-side input initialization and management for individual players. |

### Input Components

| Component | Description |
|---|---|
| [Mouse](docs/mouse.md) | Mouse input handling, including buttons, movement, position, and raycasting. |
| [Touch](docs/touch.md) | Touch input handling, including taps, gestures, swipes, and touch events. |
| [Keyboard](docs/keyboard.md) | Keyboard input handling and key state detection. |
| [Gamepad](docs/gamepad.md) | Gamepad input handling and controller events. |

## Usage

InputSystem provides separate entry points for client and server environments.

### Server

Register the player input template before starting the server module.

```luau
const InputServer = require(path.To.InputServer)

InputServer:registerPlayerInput(
    game.ServerStorage.PlayerInputs
)

InputServer:start()
```

### Client

Start the client module to load the local player's input contexts and actions.

```luau
const InputClient = require(path.To.InputClient)

InputClient:start()
```

Once initialized, you can retrieve contexts and actions, read their states, and connect to their events.

```luau
const jumpAction = InputClient:getActionAsync(
    "Gameplay",
    "Jump"
)

InputClient:onPress("Gameplay", "Jump", function()
    print("Jump pressed")
end)
```

For more information, see the [InputClient documentation](docs/input-client.md) and [InputServer documentation](docs/input-server.md).