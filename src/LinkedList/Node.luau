--!strict

type NodeClass = {
	__index: NodeClass,
	new: (prev: Node?, next: Node?, root: boolean?) -> Node,
	remove: (self: Node) -> (),
}

type NodeInstance = {
	prev: Node?,
	next: Node?,
	root: boolean?,
}

export type Node = typeof(setmetatable({} :: NodeInstance, {} :: NodeClass))

local Node = {} :: NodeClass
Node.__index = Node

function Node.new(prev: Node?, next: Node?, root: boolean?): Node
	return setmetatable({
		prev = prev,
		next = next,
		root = root,
	}, Node)
end

function Node:remove()
	if not self.prev then
		return
	end

	self.prev.next = self.next

	if self.next then
		self.next.prev = self.prev
	end

	self.prev = nil
	self.next = nil
end

return Node
