#! /usr/bin/env coffee

# Parse command line arguments
[program, cwd, algorithm, engine, filename, query] = process.argv
algorithm = algorithm[2..]
engine    = engine[2..]

# Validate arguments
if not query? or algorithm not in ['global', 'local'] or engine not in ['naive', 'symbolic']
  console.log "usage: WKTool.coffee [--global|--local] [--naive|--symbolic] [FILE.dot|FILE.wccs] [query]"
  process.exit(1)

{WCTL:            global.WCTL}            = require './WCTL'
{WKS:             global.WKS}             = require './WKS'
WCTLParser                                = require './WCTLParser'
{NaiveEngine:     global.NaiveEngine}     = require './NaiveEngine'
WKSParser                                 = require './WKSParser'
{SymbolicEngine:  global.SymbolicEngine}  = require './SymbolicEngine'
{WCCS:            global.WCCS}            = require './WCCS'
WCCSParser                                = require './WCCSParser'

fs = require 'fs'

data = fs.readFileSync(filename, 'utf-8')

if engine is 'naive'
  engine = NaiveEngine
  cval   = true
else
  engine = SymbolicEngine
  cval   = 0

wks = null
if /.*\.dot$/.test filename
  wks = WKSParser.parse(data)
else if /.*\.wccs$/.test filename
  wks = WCCSParser.parse(data)
else
  console.log "Can only handle .wccs and .dot files!"
  process.exit(1)

wks.resolve()

console.log "Initial state: #{wks.initState().stringify()}"

run = ->
  phi = WCTLParser.parse(query)
  checker = new engine(phi, wks.initState())
  return checker[algorithm]() is cval

start = process.hrtime()
try
  result = run()
catch error
  console.log "Error: #{error.message}"
  process.exit(2)
time = process.hrtime(start)

if result
  console.log "#{wks.initState().stringify()} satisfies #{query}"
else
  console.log "#{wks.initState().stringify()} does not satisfy #{query}"
console.log "Executed in #{time[0]} s and #{(time[1] / 1000000)} ms"

