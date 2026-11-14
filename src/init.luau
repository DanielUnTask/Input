--- Requires
const InputClient = require("@self/Client")
const InputServer = require("@self/Server")

--- Types
export type Touch = InputClient.Touch
export type Mouse = InputClient.Mouse
export type Gamepad = InputClient.Gamepad
export type Keyboard = InputClient.Keyboard
export type PreferredInput = InputClient.PreferredInput

export type ActionValue<T = nil> = T
export type InputClient = InputClient.InputClient
export type InputServer = InputServer.InputServer

return table.freeze({
	InputClient = InputClient,
	InputServer = InputServer,
})
