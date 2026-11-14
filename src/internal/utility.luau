const InputUtility = {}

--- Types
export type ContextCache = {
	[string]: InputContext,
}

export type ActionCache = {
	[string]: {
		[string]: InputAction,
	},
}

--- Public Methods

function InputUtility.addContexts(contextCache: ContextCache, actionCache: ActionCache, parentInputs: Instance)
	for _, context in parentInputs:QueryDescendants("InputContext") do
		contextCache[context.Name] = context
		InputUtility.addActions(actionCache, context.Name, context:QueryDescendants("InputAction"))
	end
end

function InputUtility.addActions(actionCache: ActionCache, contextName: string, actions: { InputAction })
	local contextActions = actionCache[contextName]
	if not contextActions then
		contextActions = {}
		actionCache[contextName] = contextActions
	end

	for _, action in actions do
		if not contextActions[action.Name] then
			contextActions[action.Name] = action
		end
	end
end

function InputUtility.getContext(contextCache: ContextCache, contextName: string): InputContext?
	return contextCache[contextName]
end

function InputUtility.getContextAction(
	contextCache: ContextCache,
	actionCache: ActionCache,
	contextName: string,
	actionName: string
): InputAction?
	const contextActions = actionCache[contextName]
	if not contextActions then
		return nil
	end

	local action = contextActions[actionName]
	if not action then
		local context = contextCache[contextName]
		if not context then
			return nil
		end

		action = context:FindFirstChild(actionName) :: InputAction
		if action then
			contextActions[actionName] = action
		end
	end

	return action
end

return InputUtility
