#! /usr/bin/env coffee


[program, cwd, filename] = process.argv


if not filename?
  console.log "usage: analyze.coffee [FILE]"
  process.exit(1)

fs = require 'fs'


json = JSON.parse fs.readFileSync(filename, 'utf-8')

symtimeLocal = 0
symtimeGlobal = 0
symsucc = 0
mmtimeLocal = 0
mmtimeGlobal = 0
mmsucc = 0
for result in json.results
  result.param    # List of parameters
  if not result['q4_global/symbolic'].failed? and not result['q4_local/symbolic'].failed?
    symtimeLocal += result['q4_local/symbolic'].s + (result['q4_local/symbolic'].ns / 1000000000)
    symtimeGlobal += result['q4_global/symbolic'].s + (result['q4_global/symbolic'].ns / 1000000000)
    symsucc++
  if not result['q4_global/min-max'].failed? and not result['q4_local/min-max'].failed?
    mmtimeLocal += result['q4_local/min-max'].s + (result['q4_local/min-max'].ns / 1000000000)
    mmtimeGlobal += result['q4_global/min-max'].s + (result['q4_global/min-max'].ns / 1000000000)
    mmsucc++

console.log "Symbolic:"
console.log "Global total:" + symtimeGlobal
console.log "Local total:" + symtimeLocal
console.log "Success: " + symsucc + " of: " + json.results.length
console.log ""
console.log "Min-Max:"
console.log "Global total:" + mmtimeGlobal
console.log "Local total:" + mmtimeLocal
console.log "Success: " + mmsucc + " of: " + json.results.length