# Weighted Kripke structure

class WKSState
  constructor: (@_name, @_props, @_next, @id) ->
  name: -> @_name
  next: (cb) ->
    for {weight, target} in @_next
      cb(weight, target)
  props: -> @_props
  hasProp: (p) -> p in @_props
  stringify: -> @name()
  getThisState: -> @

class @WKS
  constructor: ->
    @states = []
    @nextid = 0
  resolve: ->
  initState: => @states[0]
  getExplicitStateNames: => (s.name() for s in @states)
  getStateByName: (name) =>
    for s in @states when s.name() is name
      return s
  addState: (name) =>
    state = new WKSState(name, [], [], @nextid++)
    @states.push state
    return state
  addTransition: (source, weight, target) =>
    source._next.push {weight, target}
  addProp: (state, prop) =>
    state._props.push prop if prop not in state._props