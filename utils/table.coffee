#! /usr/bin/env coffee


[program, cwd, filename] = process.argv

if not filename?
  console.log "usage: table.coffee [FILE]"

fs = require 'fs'

data = JSON.parse fs.readFileSync(filename, 'utf-8')

engines     = ['global', 'local-dfs', 'local-bfs']
encodings   = ['naive', 'symbolic']

cols = [
  'naive/global', 'naive/local-dfs', 'naive/local-bfs',
  'symbolic/global', 'symbolic/local-dfs', 'symbolic/local-bfs'
]

FormatLength = (str, length) ->
  r = "" + str
  while r.length < length
    r = " " + r
  return r

findTime = (result) ->
  if result.failed?
    return FormatLength result.failed, 20
  time = (parseInt(result.time_s) * 1000) + (parseInt(result.time_ns) / 1000000)
  return FormatLength(time.toFixed(2), 20)

for model, properties of data
  for property in properties
    firColLen = ("" + (property.instances[property.instances.length - 1].param)).length
    console.log ""
    console.log model
    console.log property.state + " |= " + property.formula.replace(/#.*/, "").replace("\n", "")
    console.log FormatLength(" ", firColLen) + "  " + (FormatLength(col, 20) for col in cols).join('')
    for instance, i in property.instances
      console.log "#{FormatLength(instance.param, firColLen)}: " + (findTime(instance[col].result) for col in cols).join('')
