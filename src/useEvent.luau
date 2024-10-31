--!strict
--!native
--!optimize 2

local TS = _G[script]
local useHookState = TS.import(script, TS.getModule(script, "@rbxts", "topo-runtime").src).useHookState

type QueueProperties<T = any> = {
	_head: QueueEntry<T> | nil,
	_tail: QueueEntry<T> | nil,
}

type QueueImpl<T = any> = {
	__index: QueueImpl<T>,

	new: () -> Queue<T>,

	pushBack: (self: Queue<T>, value: T) -> (),
	popFront: (self: Queue<T>) -> T | nil,
}

type QueueEntry<T = any> = {
	value: T,
	next: QueueEntry<T> | nil,
}

type Queue<T = any> = typeof(setmetatable({} :: QueueProperties<T>, (nil :: any) :: QueueImpl<T>))

local Queue = {} :: QueueImpl
Queue.__index = Queue

function Queue.new()
	return setmetatable({
		_head = nil,
		_tail = nil,
	}, Queue)
end

function Queue:pushBack(value)
	local entry: QueueEntry<unknown> = {
		value = value,
		next = nil,
	}

	if self._tail ~= nil then
		self._tail.next = entry
	end

	self._tail = entry

	if self._head == nil then
		self._head = entry
	end
end

function Queue:popFront()
	if self._head == nil then
		return nil
	end

	local value = self._head.value
	self._head = self._head.next

	return value
end

local EVENT_CONNECT_METHODS = { "Connect", "on", "connect" }
local CONNECTION_DISCONNECT_METHODS = { "Disconnect", "Destroy", "disconnect", "destroy" }

local function connect(object: any, callback, event)
	local eventObject = object
	local eventType = typeof(event)

	if eventType == "RBXScriptSignal" or eventType == "table" then
		eventObject = event
	elseif type(event) == "string" then
		eventObject = object[event]
	end

	if type(eventObject) == "function" then
		return eventObject(object)
	elseif typeof(eventObject) == "RBXScriptSignal" then
		return eventObject:Connect(callback)
	end

	if type(eventObject) == "table" then
		for _, method in EVENT_CONNECT_METHODS do
			if type(eventObject[method]) ~= "function" then
				continue
			end

			return eventObject[method](eventObject, callback)
		end
	end

	error(
		"Couldn't connect to event as no valid connect methods were found! Ensure the passed event has a 'Connect' or an 'on' method!"
	)
end

local function disconnect(connection: { [any]: any } | nil)
	if connection == nil then
		return
	end

	if type(connection) == "function" then
		connection()

		return
	end

	for _, method in CONNECTION_DISCONNECT_METHODS do
		if type(connection[method]) ~= "function" then
			continue
		end

		connection[method](connection)
		break
	end
end

local function validateConnection(connection: any)
	local connectionType = typeof(connection)
	if connectionType == "function" or connectionType == "RBXScriptConnection" then
		return
	end

	for _, method in CONNECTION_DISCONNECT_METHODS do
		if connectionType ~= "table" or connection[method] == nil then
			continue
		end

		return
	end

	error("Ensure passed event returns a cleanup function, or a table with a 'Disconnect' or a 'Destroy' method!")
end

type UseEventStorage = {
	event: any,
	connection: { [any]: any } | nil,
	queue: Queue | nil,
}

local function useEventCleanupCallback(storage: UseEventStorage)
	disconnect(storage.connection)
	storage.queue = nil
end

--[=[
	@type ConnectionObject {Disconnect: (() -> ())?, Destroy: (() - >())?, disconnect: (() -> ())?, destroy: (() -> ())?} | () -> ()

	A connection object returned by a custom event must be either a table with any of the following methods, or a cleanup function.
]=]

--[=[
	@interface CustomEvent
	.Connect ((...) -> ConnectionObject)?
	.on ((...) -> ConnectionObject)?
	.connect ((...) -> ConnectionObject)?

	A custom event must have any of these 3 methods.
]=]

--[=[
	:::info Topologically-aware function
	This function is only usable if called within the context of [`Loop:begin`](/api/Loop#begin).
	:::

	Collects events that fire during the frame and allows iteration over event arguments.

	```lua
	for _, player in ipairs(Players:GetPlayers()) do
		for i, character in useEvent(player, "CharacterAdded") do
			world:spawn(
				components.Target(),
				components.Model({
					model = character,
				})
			)
		end
	end
	```

	Returns an iterator function that returns an ever-increasing number, starting at 1, followed by any event arguments
	from the specified event.

	Events are returned in the order that they were fired.

	:::caution
	`useEvent` keys storage uniquely identified by **the script and line number** `useEvent` was called from, and the
	first parameter (instance). If the second parameter, `event`, is not equal to the event passed in for this unique
	storage last frame, the old event is disconnected from and the new one is connected in its place.

	Tl;dr: on a given line, you should hard-code a single event to connect to. Do not dynamically change the event with
	a variable. Dynamically changing the first parameter (instance) is fine.

	```lua
	for _, instance in pairs(someTable) do
		for i, arg1, arg2 in useEvent(instance, "Touched") do -- This is ok
		end
	end

	for _, instance in pairs(someTable) do
		local event = getEventSomehow()
		for i, arg1, arg2 in useEvent(instance, event) do -- PANIC! This is NOT OK
		end
	end
	```
	:::

	If `useEvent` ceases to be called on the same line with the same instance and event, the event connection is
	disconnected from automatically.

	You can also pass the actual event object instead of its name as the second parameter:

	```lua
	useEvent(instance, instance.Touched)
	useEvent(instance, instance:GetPropertyChangedSignal("Name"))
	```

	`useEvent` supports custom events as well, so you can pass in an object with a `Connect`, `connect` or an `on` method.
	The object returned by any event must either be a cleanup function, or a table with a `Disconnect` or a `Destroy`
	method so that `useEvent` can later clean the event up when needed.	See [ConnectionObject] for more information.

	@param instance Instance | { [string]: CustomEvent } | CustomEvent -- The instance or the custom event, or a table that has the event you want to connect to
	@param event string | RBXScriptSignal | CustomEvent -- The name of, or the actual event that you want to connect to
]=]
local function useEvent(instance: any, event: any): () -> (number, ...any)
	--assert(instance ~= nil, "Instance is nil")
	--assert(event ~= nil, "Event is nil")

	local storage = useHookState(instance, useEventCleanupCallback) :: UseEventStorage

	if storage.event ~= event then
		if storage.event then
			disconnect(storage.connection)
			warn("useEvent event changed:", storage.event, "->", event)
			table.clear(storage)
		end

		local queue = Queue.new()
		storage.queue = queue
		storage.event = event

		local connection = connect(instance, function(...)
			queue:pushBack(table.pack(...))
		end, event)

		validateConnection(connection)
		storage.connection = connection
	end

	local index = 0
	return function(): any
		index += 1

		local arguments = (storage.queue :: Queue):popFront()

		if arguments then
			return index, unpack(arguments, 1, arguments.n)
		end

		return
	end
end

return useEvent
