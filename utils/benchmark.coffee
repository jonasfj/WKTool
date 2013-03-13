#! /usr/bin/env coffee

os            = require 'os'
fs            = require 'fs'
{spawn}       = require 'child_process'
path          = require 'path'

{ScalableModels: global.ScalableModels} = require '../bin/scripts/ScalableModels'

# Configuration

models = {
  "Leader Election with N Processes":     ([i] for i in [1..2])
  "k-Buffered Alternating Bit Protocol":  ([i, 1] for i in [1..2])
}

# Memory Size
memlimit    = 1000  # MiB

engines     = ['global', 'local-dfs', 'local-bfs']
encodings   = ['naive', 'symbolic']

# Temporary file
tmpFile = path.join os.tmpDir(), "WKTool-benchmark-input-#{process.pid}.wks"

# WKTool js file
WKTool = path.join(__dirname, 'WKTool.js')

# Run query at qindex from model with engine and encoding
run = (model, qindex, engine, encoding, callback) ->
  fs.writeFileSync(tmpFile, JSON.stringify(model))
  retval = ""
  proc = spawn 'node', ['--max-old-space-size=1000', WKTool, '--' + engine, '--' + encoding, tmpFile, "" + qindex]
  proc.stdout.on 'data', (data) -> retval += data
  proc.stderr.on 'data', (data) -> retval += data
  proc.on 'exit', (status) ->
    try
      out = JSON.parse(retval)
    catch err
      if "process out of memory" in retval
        out =
          failed:   "out of Memory"
          message: retval
      else
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

instance_jobs = (model, qindex, instResult)
  for encoding in encodings
    for engine in engines
      key = encoding + "/" + engine
      job_run(model, qindex, engine, encoding, instResult, key)

model_jobs = (model, qindex, params, instances) ->
  for param in params
    m = ScalableModels[model].factory(param...)
    inst =
      model:    model
      param:    param
      name:     m.name
    instances.push inst
    instance_jobs(m, qindex, inst)

model_prop_jobs = (model, params, results) ->
  props = []
  results[model] = props
  for prop, i in model.properties
    propResult =
      state:      prop.state
      formula:    prop.formula
      instances:  []
    props.push propResult
    model_jobs(model, i, params, propResult.instances)

do ->
  results = {}
  for model, params of models
    model_prop_jobs(model, params, results)
  
  # Last job, print all output
  jobs.push ->
    console.log JSON.stringify(results)

nextJob = ->
  if jobs.length > 0
    jobs.shift()()
