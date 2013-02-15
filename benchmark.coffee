#! /usr/bin/env coffee

# Parse command line arguments
[program, cwd, algorithm, engine, folder, expect, query] = process.argv
algorithm = algorithm[2..]
engine    = engine[2..]

# Validate arguments
if not query? or algorithm not in ['global', 'local'] or engine not in ['naive', 'symbolic']
  console.log "usage: benchmark.coffee [--global|--local] [--naive|--symbolic] [folder] [expect] [query]"
  process.exit(1)

{WCTL:            global.WCTL}            = require './WCTL'
{WKS:             global.WKS}             = require './WKS'
WCTLParser                                = require './WCTLParser'
{NaiveEngine:     global.NaiveEngine}     = require './NaiveEngine'
WKSParser                                 = require './WKSParser'
{SymbolicEngine:  global.SymbolicEngine}  = require './SymbolicEngine'

fs = require 'fs'

if engine is 'naive'
  engine = NaiveEngine
  cval   = true
else
  engine = SymbolicEngine
  cval   = 0

expected = expect is 'true'

files = fs.readdirSync(folder)
dataset = {}
for filename in files
  data = fs.readFileSync(folder + "/" + filename, 'utf-8')
  dataset[filename] =
    wks:    WKSParser.parse(data)
    phi:    WCTLParser.parse(query)


start = process.hrtime()

for filename in files
  {wks, phi} = dataset[filename]
  initial_state = 0
  try
    checker = new engine(wks, phi)
    result = checker[algorithm](initial_state) is cval
  catch error
    console.log "Error: #{error.message}"
    process.exit(2)
  
  if result isnt expected
    console.log "Unexpected result in #{filename}"
    if result
      console.log "#{wks.names[initial_state]} satisfies #{query}"
    else
      console.log "#{wks.names[initial_state]} does not satisfy #{query}"

time = process.hrtime(start)
p = WCTLParser.parse(query)

console.log "#{query} (#{p.bound}, #{time[0] * 1000 + (time[1] / 1000000)})"
#console.log "Executed in #{time[0]} s and #{(time[1] / 1000000)} ms"

