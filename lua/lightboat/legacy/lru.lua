--- LRUCache: A class implementing a Least Recently Used (LRU) cache.
--- Maintains a fixed capacity and evicts the least recently used items when the capacity is exceeded.
--- Only methods not starting with "_" are public interface.
--- @class LRUCache

local LRUCache = {}
LRUCache.__index = LRUCache

-- Internal node class for doubly linked list
--- @class LRUCache.Node
--- @field key any
--- @field prev? LRUCache.Node
--- @field next? LRUCache.Node

--- Create a new LRUCache.
--- @param capacity number The maximum number of items the cache can hold.
--- @return LRUCache
function LRUCache.new(capacity)
  assert(capacity > 0, 'Capacity must be greater than 0')
  local self = setmetatable({}, LRUCache)
  self.capacity = capacity
  self.size = 0
  self.kv_map = {} -- key -> { value = ... }
  self.node_map = {} -- key -> node
  self.list = { head = nil, tail = nil }
  self.gmt_last_vis = {}
  self.current_ts = 0
  return self
end

--- Check if the cache is full.
--- @return boolean True if the cache is full, false otherwise.
function LRUCache:full() return self.size == self.capacity end

--- Check if the cache contains a key.
--- @param key any The key to check.
--- @return boolean True if the key exists in cache.
function LRUCache:contains(key) return self.kv_map[key] ~= nil end

--- Get the value associated with a key.
--- Moves the key to the head (most recently used).
--- @param key any
--- @return any|nil The value, or nil if not present.
function LRUCache:get(key)
  if not self.kv_map[key] then return nil end
  self:_touch(key)
  return self.kv_map[key].value
end

--- Set the value for a key.
--- If the cache is full, evicts the least recently used item.
--- @param key any
--- @param value any
--- @return any, any The evicted key and value, or nil, nil if no eviction.
function LRUCache:set(key, value)
  local deleted_key, deleted_value
  if self.kv_map[key] then
    self.kv_map[key].value = value
    self:_touch(key)
  else
    if self.size == self.capacity then
      deleted_key, deleted_value = self:_evict()
    end
    self.kv_map[key] = { value = value }
    local node = { key = key }
    self.node_map[key] = node
    self:_add_to_head(node)
    self.size = self.size + 1
    self.current_ts = self.current_ts + 1
    self.gmt_last_vis[key] = self.current_ts
  end
  return deleted_key, deleted_value
end

--- Remove a key from the cache.
--- @param key any
--- @return any|nil The deleted value, or nil if not present.
function LRUCache:del(key)
  if not self.kv_map[key] then return end
  local node = self.node_map[key]
  self:_remove_node(node)
  local deleted_value = self.kv_map[key].value
  self.kv_map[key] = nil
  self.node_map[key] = nil
  self.gmt_last_vis[key] = nil
  self.size = self.size - 1
  return deleted_value
end

--- Clear the cache.
function LRUCache:clear()
  self.kv_map = {}
  self.node_map = {}
  self.list = { head = nil, tail = nil }
  self.gmt_last_vis = {}
  self.size = 0
  self.current_ts = 0
end

--- Set the capacity of the cache. May evict items if reducing size.
--- @param capacity number
--- @return table[] List of {key=, value=} evicted pairs.
function LRUCache:set_capacity(capacity)
  assert(capacity > 0, 'Capacity must be greater than 0')
  self.capacity = capacity
  local res = {}
  while self.size > self.capacity do
    local key, value = self:_evict()
    table.insert(res, { key = key, value = value })
  end
  return res
end

--- Get the last visit timestamp of a key.
--- @param key any
--- @return number
function LRUCache:last_vis(key)
  assert(self:contains(key))
  return self.gmt_last_vis[key]
end

-- ========== Internal (private) methods ==========

function LRUCache:_touch(key)
  local node = self.node_map[key]
  self:_move_to_head(node)
  self.current_ts = self.current_ts + 1
  self.gmt_last_vis[key] = self.current_ts
end

function LRUCache:_add_to_head(node)
  node.prev = nil
  node.next = self.list.head
  if self.list.head then self.list.head.prev = node end
  self.list.head = node
  if not self.list.tail then self.list.tail = node end
end

function LRUCache:_remove_node(node)
  if node.prev then
    node.prev.next = node.next
  else
    self.list.head = node.next
  end
  if node.next then
    node.next.prev = node.prev
  else
    self.list.tail = node.prev
  end
  node.prev = nil
  node.next = nil
end

function LRUCache:_move_to_head(node)
  self:_remove_node(node)
  self:_add_to_head(node)
end

function LRUCache:_evict()
  local node = self.list.tail
  assert(LRUCache:full() and node, 'You can only evict when cache is full')
  self:_remove_node(node)
  local key = node.key
  local value = self.kv_map[key].value
  self.kv_map[key] = nil
  self.node_map[key] = nil
  self.gmt_last_vis[key] = nil
  self.size = self.size - 1
  return key, value
end

return LRUCache
