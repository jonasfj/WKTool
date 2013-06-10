
@Strategies = {}

class Strategy
  constructor: ->
  pop:      -> throw new Error "Must be implemented in subclass"
  push: (e) -> throw new Error "Must be implemented in subclass"
  empty:    -> throw new Error "Must be implemented in subclass"
  size:     -> throw new Error "Must be implemented in subclass"
  push_dep: (e) ->
    if not e.in_queue
      e.in_queue = true
      @push e

@DefaultStrategy = "Depth First Search"

class @Strategies["Breadth First Search"] extends Strategy
  constructor: ->
    @queue = new buckets.Queue()
  pop:      -> @queue.dequeue()
  push: (e) -> @queue.enqueue e
  empty:    -> @queue.isEmpty()
  size:     -> @queue.size()

class @Strategies["Depth First Search"] extends Strategy
  constructor: ->
    @stack = new buckets.Stack()
  pop:      -> @stack.pop()
  push: (e) -> @stack.push e
  empty:    -> @stack.isEmpty()
  size:     -> @stack.size()

compare_priority_max = (a, b) ->
  if a.priority < b.priority
    return -1
  if a.priority > b.priority
    return 1
  return 0

compare_priority_min = (a, b) ->
  if a.priority < b.priority
    return 1
  if a.priority > b.priority
    return -1
  return 0


class @Strategies["Random Priority"] extends Strategy
  constructor: ->
    @queue = new buckets.PriorityQueue(compare_priority_max)
  pop:      -> @queue.dequeue()
  push: (e) ->
    e.priority ?= Math.random()
    @queue.enqueue e
  empty:    -> @queue.isEmpty()
  size:     -> @queue.size()

class @Strategies["Breadth First, Prioritized Propagation"] extends Strategy
  constructor: ->
    @queue = new buckets.PriorityQueue(compare_priority_min)
    @count = 0
  pop:      -> @queue.dequeue()
  push: (e) ->
    e.priority ?= @count++
    @queue.enqueue e
  empty:    -> @queue.isEmpty()
  size:     -> @queue.size()

class @Strategies["Breadth First, Propagation Imediate"] extends Strategy
  constructor: ->
    @list = new buckets.LinkedList()
  pop:      ->
    retval = @list.first()
    @list.removeElementAtIndex(0)
    return retval
  push: (e) -> @list.add e, @list.size()
  push_dep: (e) ->
    if not e.in_queue
      e.in_queue = true
      @list.add e, 0
  empty:    -> @list.size() == 0
  size:     -> @list.size()