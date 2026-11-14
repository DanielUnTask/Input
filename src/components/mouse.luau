--!strict
const Mouse = {}
Mouse.__index = Mouse

--- Services
const UserInputService = game:GetService("UserInputService")

--- Requires
const Scope = require("../internal/scope")
const Signal = require("../internal/signal")

--- Constants
const RAY_DISTANCE = 1_000

--- Type
export type Mouse = setmetatable<{
	_scope: Scope.Scope,
	leftUp: Signal.Identity<boolean>,
	leftDown: Signal.Identity<boolean>,
	rightUp: Signal.Identity<boolean>,
	rightDown: Signal.Identity<boolean>,
	middleUp: Signal.Identity<boolean>,
	middleDown: Signal.Identity<boolean>,
	scrolled: Signal.Identity<number, boolean>,
	moved: Signal.Identity<Vector2, boolean>,
}, typeof(Mouse)>

--- Constructor

--[=[
	@within Mouse
	@return Mouse

	Constructs a new mouse input controller.

	```lua
	local mouse = Mouse.new()
	```
]=]
function Mouse.new(): Mouse
	const self = (setmetatable({}, Mouse) :: any) :: Mouse
	self._scope = Scope.new()

	self.moved = self._scope:construct(Signal) :: Signal.Identity<Vector2, boolean>
	self.leftDown = self._scope:construct(Signal) :: Signal.Identity<boolean>
	self.leftUp = self._scope:construct(Signal) :: Signal.Identity<boolean>
	self.rightDown = self._scope:construct(Signal) :: Signal.Identity<boolean>
	self.rightUp = self._scope:construct(Signal) :: Signal.Identity<boolean>
	self.middleDown = self._scope:construct(Signal) :: Signal.Identity<boolean>
	self.middleUp = self._scope:construct(Signal) :: Signal.Identity<boolean>
	self.scrolled = self._scope:construct(Signal) :: Signal.Identity<number, boolean>

	self._scope:connect(UserInputService.InputBegan, function(input: InputObject, processed: boolean)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.leftDown:Fire(processed)
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			self.rightDown:Fire(processed)
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
			self.middleDown:Fire(processed)
		end
	end)

	self._scope:connect(UserInputService.InputEnded, function(input: InputObject, processed: boolean)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.leftUp:Fire(processed)
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			self.rightUp:Fire(processed)
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
			self.middleUp:Fire(processed)
		end
	end)

	self._scope:connect(UserInputService.InputChanged, function(input: InputObject, processed: boolean)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local position = input.Position
			self.moved:Fire(Vector2.new(position.X, position.Y), processed)
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			self.scrolled:Fire(input.Position.Z, processed)
		end
	end)

	return self
end

--- Public Methods

--[=[
	@within Mouse

	Checks if the left mouse button is currently pressed.

	@return boolean
]=]
function Mouse.isLeftDown(self: Mouse): boolean
	return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
end

--[=[
	@within Mouse

	Checks if the right mouse button is currently pressed.

	@return boolean
]=]
function Mouse.isRightDown(self: Mouse): boolean
	return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

--[=[
	@within Mouse

	Checks if the middle mouse button is currently pressed.

	@return boolean
]=]
function Mouse.isMiddleDown(self: Mouse): boolean
	return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3)
end

--[=[
	@within Mouse

	Gets the current screen position of the mouse.

	@return Vector2
]=]
function Mouse.getPosition(self: Mouse): Vector2
	return UserInputService:GetMouseLocation()
end

--[=[
	@within Mouse

	Gets the mouse movement delta for the current frame.

	This is primarily intended for use when the mouse is locked.
	When the mouse is not locked, this will generally return a zero Vector2.

	@return Vector2
]=]
function Mouse.getDelta(self: Mouse): Vector2
	return UserInputService:GetMouseDelta()
end

--[=[
	@within Mouse

	Returns the viewport point ray for the mouse at its current position,
	or at the provided override position.

	@param overridePos Vector2?
	@return Ray
]=]
function Mouse.getRay(self: Mouse, overridePos: Vector2?): Ray
	const mousePos = overridePos or UserInputService:GetMouseLocation()
	const viewportMouseRay = workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y)
	return viewportMouseRay
end

--[=[
	@within Mouse

	Performs a raycast from the mouse position into the 3D world.

	The ray extends `distance` studs forward, or 1,000 studs if no distance
	is provided.

	Returns the RaycastResult if something was hit, otherwise nil.

	Use `raycast` when you need to detect objects along the projected ray.
	If only the final world position is needed, use `project` instead.

	@param raycastParams RaycastParams
	@param distance number?
	@param overridePos Vector2?
	@return RaycastResult?

	```lua
	local params = RaycastParams.new()
	local result = mouse:raycast(params)

	if result then
		print(result.Instance)
	else
		print("Mouse raycast did not hit anything")
	end
	```
]=]
function Mouse.raycast(
	self: Mouse,
	raycastParams: RaycastParams,
	distance: number?,
	overridePos: Vector2?
): RaycastResult?
	const viewportMouseRay = self:getRay(overridePos)
	const result = workspace:Raycast(
		viewportMouseRay.Origin,
		viewportMouseRay.Direction * (distance or RAY_DISTANCE),
		raycastParams
	)
	return result
end

--[=[
	@within Mouse

	Gets the 3D world position of the mouse when projected forward.

	This returns the end position of the mouse ray at the specified distance,
	without checking for objects along the way.

	Use `project` when you only need a world position and do not need
	to detect objects between the ray origin and its destination.
	It is faster than performing a full raycast operation.

	@param distance number?
	@param overridePos Vector2?
	@return Vector3

	```lua
	local worldPosition = mouse:project(200)
	```
]=]
function Mouse.project(self: Mouse, distance: number?, overridePos: Vector2?): Vector3
	const viewportMouseRay = self:getRay(overridePos)
	return viewportMouseRay.Origin + (viewportMouseRay.Direction.Unit * (distance or RAY_DISTANCE))
end

--[=[
	@within Mouse

	Locks the mouse in its current screen position.

	Call `mouse:unlock()` to restore the default mouse behavior.

	:::caution Must explicitly unlock
	Be sure to call `mouse:unlock()` before cleaning up the mouse.
	The `destroy` method does not unlock the mouse because there is no way
	to guarantee who owns the global mouse lock.
	:::
]=]
function Mouse.lock(self: Mouse)
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
end

--[=[
	@within Mouse

	Locks the mouse to the center of the screen.

	Call `mouse:unlock()` to restore the default mouse behavior.

	:::caution Must explicitly unlock
	See the cautionary note in `lock`.
	:::
]=]
function Mouse.lockCenter(self: Mouse)
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

--[=[
	@within Mouse

	Unlocks the mouse and restores its default behavior.
]=]
function Mouse.unlock(self: Mouse)
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

--[=[
	@within Mouse

	Destroys the mouse controller.

	Cleans up all resources managed by the instance's internal Scope,
	including its input connections and signals.

	@return ()
]=]
function Mouse.destroy(self: Mouse)
	self._scope:destroy()
end

return table.freeze({
	new = Mouse.new,
})
