
@Strategies = {}

class Strategy
  constructor: ->
  pop:      -> throw new Error "Must be implemented in subclass"
  push: (e) -> throw new Error "Must be implemented in subclass"
  empty:    -> throw new Error "Must be implemented in subclass"
  push_dep: (e) ->
    if not e.in_queue
      e.in_queue = true
      @push e

@DefaultStrategy = "Breadth First Search"

class Strategies[DefaultStrategy] extends Strategy
  constructor: ->
    @queue = new buckets.Queue()
  pop:      -> @queue.dequeue()
  push: (e) -> @queue.enqueue e
  empty:    -> @queue.isEmpty()

class Strategies["Depth First Search"] extends Strategy
  constructor: ->
    @stack = new buckets.Stack()
  pop:      -> @stack.pop()
  push: (e) -> @stack.push e
  empty:    -> @stack.isEmpty()

compare_priority = (a, b) ->
  if a.priority < b.priority
    return -1
  if a.priority > b.priority
    return 1
  return 0

class Strategies["Random Priority"] extends Strategy
  constructor: ->
    @queue = new buckets.PriorityQueue(compare_priority)
  pop:      -> @queue.dequeue()
  push: (e) ->
    e.priority ?= Math.random()
    @queue.enqueue e
  empty:    -> @queue.isEmpty()

