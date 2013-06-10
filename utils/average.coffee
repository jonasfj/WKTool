#! /usr/bin/env coffee

os            = require 'os'
fs            = require 'fs'
{spawn}       = require 'child_process'
path          = require 'path'

global.fetchTaskGraph = (file) ->
  filename = path.join(__dirname, '../', file)
  return fs.readFileSync(filename, 'utf8')

{ScalableModels: global.ScalableModels} = require './ScalableModels'

# Memory Size
memlimit    = 1000  # MiB

timeout     = 10 * 60000 #ms

engines     = ['global', 'local-dfs']
encodings   = ['symbolic', 'min-max']

# Temporary file
tmpFile = path.join os.tmpDir(), "WKTool-average-input-#{process.pid}.wks"

# WKTool js file
WKTool = path.join(__dirname, 'WKTool.js')

# Run query at qindex from model with engine and encoding
run = (model, qindex, engine, encoding, callback) ->
  fs.writeFileSync(tmpFile, JSON.stringify(model))
  retval = ""
  proc = spawn 'node', ['--max-old-space-size=' + memlimit, WKTool, '--' + engine, '--' + encoding, tmpFile, "" + qindex]
  proc.stdout.on 'data', (data) -> retval += data
  proc.stderr.on 'data', (data) -> retval += data
  timedOut = false
  myTimeout = setTimeout (->
    timedOut = true
    proc.kill()
  ), timeout
  proc.on 'exit', (status) ->
    clearTimeout myTimeout
    try
      out = JSON.parse(retval)
    catch err
      if retval.indexOf("process out of memory") != -1
        out =
          failed:   "OOM"
          message:  retval
      else if timedOut
        out = 
          failed:   "Timeout"
          message:  retval
      else
        out = 
          failed:   "Unknown"
          message:  retval
    callback(status is 0, out)


# Things to execute
jobs = []

job_run = (model, qindex, engine, encoding, instResult, key) ->
  cb = (success, result) ->
    if result.failed?
      instResult[key] = {failed: true, info: result}
    else
      instResult[key] = {s: parseInt(result.time_s), ns: parseInt(result.time_ns)}
    nextJob()
  jobs.push ->
    run(model, qindex, engine, encoding, cb)

# Run 4 test task graphs...
#params  = ([i, 6, 120] for i in [0..3])

# Run all 180 task graphs
bound = parseInt process.argv[2]
params  = ([i, 6, bound] for i in [0..179])
factory = ScalableModels["Standard Task Graph"].factory

results = []
for param in params
  model = factory(param...)
  results.push inst =
    param:    param
  for enc in encodings
    #job_run(model, 4, 'global',     enc, inst, 'q4_global/' + enc)
    job_run(model, 4, 'local-dfs',  enc, inst, 'q4_local/' + enc)

# Print results
jobs.push ->
  averages = {}
  for key in [('q4_local/' + enc for enc in encodings)...] #, ('q4_global/'+enc for enc in encodings)...]
    seconds = 0
    nanos   = 0
    failed  = 0
    for entry in results
      if entry[key].failed?
        failed += 1
      else
        seconds += entry[key].s
        nanos += entry[key].ns
        while nanos > 1000000000
          nanos -= 1000000000
          seconds += 1
    averages[key] =
      failed:   failed
      seconds:  seconds / (results.length - failed) + (nanos / 1000000000) / (results.length - failed)
  console.log JSON.stringify({averages, results})


nJobs = jobs.length

nextJob = ->
  if jobs.length > 0
    console.error "Starting job #{nJobs - jobs.length + 1} of #{nJobs}"
    jobs.shift()()
  else
    console.error "Finished!"

nextJob()



