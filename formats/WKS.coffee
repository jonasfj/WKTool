# Weighted Kripke structure

class WKSState
  constructor: (@_name, @_props, @_next, @_id) ->
  name: => @_name
  next: => @_next
  props: => @_props
  id:   => @_id
  hasProp: (p) => p in @_props
  stringify: => @name()

class @WKS
  constructor: ->
    @states = []
    @nextid = 0
  initState: => @states[0]
  addState: (name) =>
    state = new WKSState(name, [], [], @nextid++)
    @states.push state
    return state
  addTransition: (source, weight, target) =>
    source._next.push {weight, target}
  addProp: (state, prop) =>
    state._props.push prop if prop not in state._props