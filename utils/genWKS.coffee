#!/usr/bin/env coffee

{WCTL:            global.WCTL}            = require './WCTL'
{WKS:             global.WKS}             = require './WKS'
WCTLParser                                = require './WCTLParser'
{NaiveEngine:     global.NaiveEngine}     = require './NaiveEngine'
WKSParser                                 = require './WKSParser'
{SymbolicEngine:  global.SymbolicEngine}  = require './SymbolicEngine'

engine = SymbolicEngine
cval   = 0
queries =
  "E a U[60] b":   true
  "A a U[200] b":  false

fs = require 'fs'

ran = (min = 0; max = 1) -> min + Math.round(Math.random() * (max - min))

models = 0
while models < 1000
  data = ""
  out = (d) -> data += d + "\n"

  state = (name, props) ->
    out "\t#{name} [label = \"#{name} {#{props.join(', ')}}\"];"
  transition = (source, weight, target) ->
    out "\t#{source} -> #{target} [label = \"#{weight}\"];"

  out "digraph {"

  # states
  states = ran(800, 1200)
  for i in [1..states]
    if i isnt 1 and ran(0, 20) is 1   #one in five has b
      state "s#{i}", ['a', 'b']
    else
      state "s#{i}", ['a']

  transitions = 0
  for i in [1..states]
    targets = []
    for q in [1...ran(1, 10)]
      weight = ran(0, 10)
      if weight >= 9
        weight = 0
      source = i
      target = ran(1, states - 1)
      if target >= i
        target += 1
      if target in targets
        continue
      targets.push target
      transitions += 1
      transition "s#{source}", weight, "s#{target}"

  out "}"
  # Parse data
  wks = WKSParser.parse(data)
  initial_state = 0
  good = true
  for query, expected of queries
    phi = WCTLParser.parse(query)
    checker = new engine(wks, phi)
    result = checker.local(initial_state) is cval
    if not result is expected
      console.log "Failed: " + query
      good = false
      break
  if good
    models += 1
    filename = "big-models/m-#{models}-#{states}-#{transitions}.dot"
    console.log "Created: #{filename}"
    fs.writeFileSync(filename, data, 'utf-8')
