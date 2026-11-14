--!strict

const Touch = {}
Touch.__index = Touch

--- Services
const UserInputService = game:GetService("UserInputService")

--- Requires
const Scope = require("../internal/scope")
const Signal = require("../internal/signal")

--- Types
export type Touch = setmetatable<{
	_scope: Scope.Scope,
	tap: Signal.Identity<({ Vector2 }, boolean)>,
	pan: Signal.Identity<({ Vector2 }, Vector2, Vector2, Enum.UserInputState, boolean)>,
	pinch: Signal.Identity<({ Vector2 }, number, Vector2, Enum.UserInputState, boolean)>,
	moved: Signal.Identity<(InputObject, boolean)>,
	swipe: Signal.Identity<(Enum.SwipeDirection, number, boolean)>,
	rotate: Signal.Identity<({ Vector2 }, number, number, Enum.UserInputState, boolean)>,
	tapInWorld: Signal.Identity<(Vector2, boolean)>,
	touchEnded: Signal.Identity<(InputObject, boolean)>,
	touchStarted: Signal.Identity<(InputObject, boolean)>,
	longProgress: Signal.Identity<({ Vector2 }, Enum.UserInputState, boolean)>,
}, typeof(Touch)>

--- Constructor

--[=[
	Constructs a new Touch input capturer.

    @prop tap Signal<(touchPositions: {Vector2}, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchTap](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchTap)

    @prop tapInWorld Signal<(position: Vector2, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchTapInWorld](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchTapInWorld)

    @prop moved Signal<(touch: InputObject, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchMoved](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchMoved)

    @prop longPress Signal<(touchPositions: {Vector2}, state: Enum.UserInputState, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchLongPress](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchLongPress)

    @prop pan Signal<(touchPositions: {Vector2}, totalTranslation: Vector2, velocity: Vector2, state: Enum.UserInputState, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchPan](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchPan)

    @prop pinch Signal<(touchPositions: {Vector2}, scale: number, velocity: Vector2, state: Enum.UserInputState, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchPinch](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchPinch)

    @prop rotate Signal<(touchPositions: {Vector2}, rotation: number, velocity: number, state: Enum.UserInputState, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchRotate](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchRotate)

    @prop swipe Signal<(swipeDirection: Enum.SwipeDirection, numberOfTouches: number, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchSwipe](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchSwipe)

	@prop touchEnded Signal<(touch: InputObject, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchEnded](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchEnded)

    @prop touchStarted Signal<(touch: InputObject, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchStarted](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchStarted)
]=]
function Touch.new(): Touch
	const self = setmetatable({}, Touch)
	self._scope = Scope.new()

	self.tap = self._scope:construct(Signal.wrap, UserInputService.TouchTap)
	self.pan = self._scope:construct(Signal.wrap, UserInputService.TouchPan)
	self.pinch = self._scope:construct(Signal.wrap, UserInputService.TouchPinch)
	self.moved = self._scope:construct(Signal.wrap, UserInputService.TouchMoved)
	self.swipe = self._scope:construct(Signal.wrap, UserInputService.TouchSwipe)
	self.rotate = self._scope:construct(Signal.wrap, UserInputService.TouchRotate)
	self.tapInWorld = self._scope:construct(Signal.wrap, UserInputService.TouchTapInWorld)
	self.touchEnded = self._scope:construct(Signal.wrap, UserInputService.TouchEnded)
	self.touchStarted = self._scope:construct(Signal.new, UserInputService.TouchStarted)
	self.longProgress = self._scope:construct(Signal.new, UserInputService.TouchLongPress)

	return (self :: any) :: Touch
end

--- Public Methods

--[=[
	Returns the value of [`UserInputService.TouchEnabled`](https://developer.roblox.com/en-us/api-reference/property/UserInputService/TouchEnabled).
]=]
function Touch.isTouchEnabled(self: Touch): boolean
	return UserInputService.TouchEnabled
end

--[=[
	Destroys the Touch input capturer.
]=]
function Touch.Destroy(self: Touch)
	self._scope:destroy()
end

return table.freeze({
	new = Touch.new,
})
