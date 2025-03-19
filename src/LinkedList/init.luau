--!strict

local iif = require(script.Parent.Lib.iif)
local Types = require(script.Parent.Lib.Types)
local Node = require(script.Node)

type Node = Node.Node

type LinkedListClass = {
	__index: LinkedListClass,
	new: () -> LinkedList,
	exists: (self: LinkedList, node: Node) -> boolean,
	isEmpty: (self: LinkedList) -> boolean,
	getHead: (self: LinkedList) -> Node?,
	insertBefore: (self: LinkedList, node: Node, check: (node: Node) -> boolean) -> (),
	findTransition: (
		self: LinkedList,
		check: (node: Node) -> boolean
	) -> { before: Node?, after: Node?, insert: (node: Node) -> Node },
	node: (self: LinkedList, data: Node) -> Node,
}

type LinkedListInstance = {
	root: Node,
}

export type LinkedList = typeof(setmetatable({} :: LinkedListInstance, {} :: LinkedListClass))

local LinkedList = {} :: LinkedListClass
LinkedList.__index = LinkedList

function LinkedList.new()
	return setmetatable({
		root = Node.new(nil, nil, true),
	}, LinkedList)
end

function LinkedList:exists(node: Node?): boolean
	if node == nil or node == self.root then
		return false
	end

	return true
end

function LinkedList:isEmpty()
	return self.root.next == nil
end

function LinkedList:getHead()
	return self.root.next
end

function LinkedList:insertBefore(node: Node, check: (node: Node) -> boolean)
	local last = self.root
	local here = self.root.next

	while here ~= nil do
		if check(here) then
			node.prev = here.prev
			node.next = here

			if here.prev then
				here.prev.next = node
			end

			here.prev = node

			return
		end

		last = here
		here = here.next
	end

	last.next = node
	node.prev = last
	node.next = nil
end

function LinkedList:findTransition(check: (node: Node) -> boolean)
	local prev = self.root
	local here = self.root.next

	while here ~= nil do
		if check(here) then
			break
		end

		prev = here
		here = here.next
	end

	return {
		before = iif(prev == self.root, nil, prev),
		after = here,

		insert = function(node)
			node.prev = prev
			node.next = here
			prev.next = node

			if here ~= nil then
				here.prev = node
			end

			return node
		end,
	}
end

return LinkedList
