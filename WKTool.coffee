#! /usr/bin/env coffee

# Parse command line arguments
[program, cwd, algorithm, engine, filename, query] = process.argv
algorithm = algorithm[2..]
engine    = engine[2..]

# Validate arguments
if not query? or algorithm not in ['global', 'local'] or engine not in ['naive', 'symbolic']
  console.log "usage: WKTool.coffee [--global|--local] [--naive|--symbolic] [FILE] [query]"
  process.exit(1)

{WCTL:            global.WCTL}            = require 'WCTL'
{WKS:             global.WKS}             = require 'WKS'
WCTLParser                                = require 'WCTLParser'
{NaiveEngine:     global.NaiveEngine}     = require 'NaiveEngine'
WKSParser                                 = require 'WKSParser'
{SymbolicEngine:  global.SymbolicEngine}  = require 'SymbolicEngine'

fs = require 'fs'

data = fs.readFileSync(filename, 'utf-8')

if engine is 'naive'
  engine = NaiveEngine
  cval   = true
else
  engine = SymbolicEngine
  cval   = 0

wks = WKSParser.parse(data)

initial_state = 0
console.log "Initial state: #{wks.names[initial_state]}"

run = ->
  phi = WCTLParser.parse(query)
  checker = new engine(wks, phi)
  return checker[algorithm](initial_state) is cval

start = process.hrtime()
try
  for i in [0...10]
    result = run()
catch error
  console.log "Error: #{error.message}"
  process.exit(2)
time = process.hrtime(start)

if result
  console.log "#{wks.names[initial_state]} satisfies #{query}"
else
  console.log "#{wks.names[initial_state]} does not satisfy #{query}"
console.log "Executed in #{time[0] / 10} s and #{(time[1] / 1000000) / 10} ms"

