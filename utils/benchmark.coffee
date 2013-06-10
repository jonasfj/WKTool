#! /usr/bin/env coffee

os            = require 'os'
fs            = require 'fs'
{spawn}       = require 'child_process'
path          = require 'path'

global.fetchTaskGraph = (file) ->
  filename = path.join(__dirname, '../', file)
  return fs.readFileSync(filename, 'utf8')

{ScalableModels: global.ScalableModels} = require './ScalableModels'

# Configuration
###
Consider only: local-dfs
Remember: positive/negative instances

Naive vs Symbolic, Scale bound
+ Leader Election with P=6        EF[<=#{n*n}] leader
- Leader Election with P=6        AF[<=n*n] 
+ Alternating Bit Protocol B=4    EF[<= #{k * n}] delivered == #{n}

Local vs Global, Scale problem size
- Alternating Bit Protocol D=1    EF (send0 && deliver1) || (send1 && deliver0)
+ Alternating Bit Protocol D=4    EF[<= #{k * n + 500}] delivered == #{n}
NOTE: ABP is identical for global/local, not easy to explain
###




configurations = require("./" + process.argv[2]).config

# Memory Size
memlimit    = 1000  # MiB

timeout     = 10 * 60000 #ms

engines     = ['global', 'local-dfs', 'local-bfs']
encodings   = ['naive', 'symbolic', 'min-max']

# Temporary file
tmpFile = path.join os.tmpDir(), "WKTool-benchmark-input-#{process.pid}.wks"

# WKTool js file
WKTool = path.join(__dirname, 'WKTool.js')

# Run query at qindex from model with engine and encoding
run = (model, qindex, engine, encoding, callback) ->
  console.error("Running: " + model.name + " with " + encoding + "/" + engine + " qindex: " + qindex)
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
        console.error("Out-of-memory")
      else if timedOut
        out = 
          failed:   "Timeout"
          message:  retval
        console.error("Timeout")
      else
        console.error("Unknown death")
        out = 
          failed:   "Unknown"
          message:  retval
    callback(status is 0, out)

# Things to execute
jobs = []

job_run = (model, qindex, engine, encoding, instResult, key) ->
  cb = (success, result) ->
    instResult[key] = {success, result}
    nextJob()
  jobs.push ->
    run(model, qindex, engine, encoding, cb)


do ->
  results = {}
  for table, conf of configurations
    results[table] = props = []
    for prop in conf.properties
      m = ScalableModels[conf.model].factory(conf.params[0]...)
      props.push pVal =
        pindex:   conf.pindex
        formula:  prop.name
        sat:      prop.sat
        state:    m.properties[prop.qindex].state
        instances: []
      for param in conf.params
        pVal.instances.push inst = 
          param:    param
        model = ScalableModels[conf.model].factory(param...)
        for encoding in conf.encodings
          for engine in conf.engines
            key = encoding + "/" + engine
            job_run(model, prop.qindex, engine, encoding, inst, key)
  
  # Last job, print all output
  jobs.push ->
    console.log JSON.stringify(results)

nJobs = jobs.length

nextJob = ->
  if jobs.length > 0
    console.error "Starting job #{nJobs - jobs.length + 1} of #{nJobs}"
    jobs.shift()()
  else
    console.error "Finished!"

nextJob()
