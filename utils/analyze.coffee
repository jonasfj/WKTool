#! /usr/bin/env coffee


[program, cwd, filename] = process.argv


if not filename?
  console.log "usage: analyze.coffee [FILE]"
  process.exit(1)

fs = require 'fs'

json = JSON.parse fs.readFileSync(filename, 'utf-8')

timeLocal = 0
timeGlobal = 0
secs = 0
nanos = 0
failed = 0
for result in json.results
  result.param    # List of parameters
  if not result.q4_global.failed? and not result.q4_local.failed?
    timeLocal += result.q4_local.s + (result.q4_local.ns / 1000000000)
    timeGlobal += result.q4_global.s + (result.q4_global.ns / 1000000000)
  else
    failed++

console.log "Global total:" + timeGlobal
console.log "Local total:" + timeLocal
console.log "Failed: " + failed + " of: " + json.results.length