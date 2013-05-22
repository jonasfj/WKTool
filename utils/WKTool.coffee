#! /usr/bin/env coffee

# Launch with:
# coffee --nodejs "--max-old-space-size=1000" ./utils/WKTool.coffee --global --symbolic models/LeaderElection20.wkp  0

# Parse command line arguments
[program, cwd, algorithm, engine, filename, qindex] = process.argv
if algorithm?
  algorithm = algorithm[2..]
if engine?
  engine    = engine[2..]
if qindex?
  qindex    = parseInt qindex

# Validate arguments
algs = ['global', 'local-dfs', 'local-bfs']
engs = ['naive', 'symbolic', 'min-max']
if algorithm not in algs or engine not in engs or typeof qindex isnt 'number'
  console.log "usage: WKTool.coffee [--global|--local-dfs|--local-bfs] [--naive|--symbolic|--min-max] [FILE] [QUERY-INDEX]"
  process.exit(1)

{WCTL:            global.WCTL}            = require '../bin/formats/WCTL'
{WKS:             global.WKS}             = require '../bin/formats/WKS'
{buckets:         global.buckets}         = require './buckets.js'
WCTLParser                                = require '../bin/formats/WCTLParser'
{Strategies:      global.Strategies}      = require '../bin/engines/Strategies'
{NaiveEngine:     global.NaiveEngine}     = require '../bin/engines/NaiveEngine'
WKSParser                                 = require '../bin/formats/WKSParser'
{SymbolicEngine:  global.SymbolicEngine}  = require '../bin/engines/SymbolicEngine'
{MinMaxEngine:    global.MinMaxEngine}    = require '../bin/engines/MinMaxEngine'
{WCCS:            global.WCCS}            = require '../bin/formats/WCCS'
WCCSParser                                = require '../bin/formats/WCCSParser'

fs = require 'fs'

data = JSON.parse fs.readFileSync(filename, 'utf-8')

strategy = null
if algorithm is 'local-bfs'
  algorithm = 'local'
  strategy = Strategies["Breadth First Search"]
if algorithm is 'local-dfs'
  algorithm = 'local'
  strategy = Strategies["Depth First Search"]

if engine is 'naive'
  engine = 'Naive'
else if engine is 'symbolic'
  engine = 'Symbolic'
else if engine is 'min-max'
  engine = 'MinMax'
else
  throw new Error "Unknown engine: #{engine}"


if data.model.language is 'WCCS'
  parser = WCCSParser.WCCSParser
else
  parser = WKSParser.WKSParser

# Parse the WKS
wks = parser.parse(data.model.definition)
wks.resolve()


# Find the property
if not data.properties[qindex]?
  console.log "Property with index " + qindex + " doesn't exist!"
  process.exit(1)

prop  = data.properties[qindex]
phi   = WCTLParser.WCTLParser.parse(prop.formula)
state = wks.getStateByName prop.state

verifier  = new global["#{engine}Engine"](phi, state)

start = process.hrtime()
try
  result = verifier[algorithm](false, strategy)
catch error
  console.log "Error: #{error.message}"
  process.exit(2)
time = process.hrtime(start)

output =
  result:   result
  time_s:   time[0]
  time_ns:  time[1]

console.log JSON.stringify(output)
process.exit(0)