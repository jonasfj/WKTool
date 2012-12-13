# Weighted Kripke structure
  

# A WKS
class @WKS
  constructor: ->
    @states = 0
    @props = {}
    @next = {}
    @prev = {}
    @names = {}

  # Add a state 
  addState: (name) =>
    state = @states++
    @props[state] = []
    @next[state] = []
    @prev[state] = []
    @names[state] = name
    return state

  # Add a transition source to target with weight
  addTransition: (source, weight, target) =>
    hasNext = false
    for {weight: w, target: t} in @next when w is weight and t is target
      hasNext = true
    hasPrev = false
    for {weight: w, source: s} in @prev when w is weight and s is source
      hasPrev = true
    @next[source].push {weight, target}         if not hasNext
    @prev[target].push {weight, source}         if not hasPrev

  # Add an atomic label to a state
  addProp: (state, prop) =>
    @props[state].push(prop)                    if prop not in @props[state]

