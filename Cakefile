# System Modules
fs            = require 'fs'
{print}       = require 'util'
{spawn}       = require 'child_process'
path          = require 'path'

# Third Party Modules
watch         = require 'node-watch'
minimatch     = require 'minimatch'
connect       = require 'connect'

#### Configuration

# Port on localhost
_port = 3333

_target_site = 'wktool.jonasfj.dk:wktool.jonasfj.dk/'

# Scripts that must always be included
common_scripts = [
  'scripts/utils.coffee'
]

# Stylesheets that must always be included
common_style = [
]

_exampleFiles = []
do ->
  for file in fs.readdirSync(path.join(__dirname, 'examples'))
    f = path.join(__dirname, 'examples', file)
    if not fs.statSync(f).isDirectory()
      _exampleFiles.push file

# Static files to be copied over
static_files = [
  'img/glyphicons-halflings.png'
  'img/glyphicons-halflings-white.png'
  ("examples/#{file}" for file in _exampleFiles)...
  ("examples/TaskGraphs50/#{file}" for file in fs.readdirSync(path.join __dirname, 'examples/TaskGraphs50'))...
]

# Scripts to build, even if not included anyway
worker_scripts = [
  'lib/buckets.min.js'
  'engines/Strategies.coffee'
  'engines/NaiveEngine.coffee'
  'engines/SymbolicEngine.coffee'
  'engines/MinMaxEngine.coffee'
  'formats/WKSParser.pegjs'
  'formats/WCTLParser.pegjs'
  'formats/WCCSParser.pegjs'
  'formats/WKS.coffee'
  'formats/WCTL.coffee'
  'formats/WCCS.coffee'
  'scripts/VerificationWorker.coffee'
]

# For each template define scripts and stylesheets to include, these will be
# included or concatenated and potentially inlined in the order they are listed.
_templates =
  # File with dependencies
  'index.jade':
    # Scripts to be included
    scripts: [
      'lib/jquery.min.js'
      'lib/jquery.ui.min.js'
      'lib/jquery.layout.min.js'
      'lib/bootstrap.min.js'
      'lib/jquery.sparkline.min.js'
      'lib/codemirror.min.js'
      'lib/runmode.js'
      'lib/matchbrackets.js'
      'editor/WKS-mode.coffee'
      'editor/WCTL-mode.coffee'
      'editor/WCCS-mode.coffee'
      'lib/buckets.min.js'
      'engines/Strategies.coffee'
      'formats/WKS.coffee'
      'formats/WCTL.coffee'
      'formats/WCCS.coffee'
      'formats/WKSParser.pegjs'
      'formats/WCTLParser.pegjs'
      'formats/WCCSParser.pegjs'
      'scripts/Panel.coffee'
      'scripts/Editor.coffee'
      'scripts/Verifier.coffee'
      'scripts/ScalableModels.coffee'
    ]
    # Stylesheets to be included
    style: [
      'lib/bootstrap.min.css'
      'lib/layout-default.css'
      'editor/CodeMirror.styl'
      'style/Panel.styl'
      'style/Editor.styl'
      'style/Verifier.styl'
    ]
    # Additional template arguments
    args: {
      examples: (file.replace /.wkp$/, '' for file in _exampleFiles)
    }
  # Visualization of Weighted Kripke Structures
  'visualize.jade':
    # Scripts to be included
    scripts: [
      'lib/jquery.min.js'
      'lib/jquery.ui.min.js'
      'lib/jquery.layout.min.js'
      'lib/arbor.js'
      'lib/bootstrap.min.js'
      'lib/codemirror.min.js'
      'lib/runmode.js'
      'editor/WKS-mode.coffee'
      'editor/WCCS-mode.coffee'
      'formats/WKS.coffee'
      'formats/WCTL.coffee'
      'formats/WCCS.coffee'
      'formats/WKSParser.pegjs'
      'formats/WCTLParser.pegjs'
      'formats/WCCSParser.pegjs'
      'scripts/visualize.coffee'
    ]
    # Stylesheets to be included
    style: [
      'lib/bootstrap.min.css'
      'lib/layout-default.css'
      'editor/CodeMirror.styl'
      'style/visualize.styl'
    ]
    # Additional template arguments
    args: {}
  # Help file for WKTool
  'help.jade':
    # Scripts to be included
    scripts: [
      'lib/jquery.min.js'
      'lib/bootstrap.min.js'
      'lib/codemirror.min.js'
      'lib/runmode.js'
      'editor/WKS-mode.coffee'
      'editor/WCTL-mode.coffee'
      'editor/WCCS-mode.coffee'
      'scripts/help.coffee'
    ]
    # Stylesheets to be included
    style: [
      'lib/bootstrap.min.css'
      'editor/CodeMirror.styl'
      'style/help.styl'
    ]
    # Additional template arguments
    args: {}

swapSlash = (s) -> s.replace "\\", "/"

# Template arguments for template
template_arguments = (template) ->
  template = swapSlash template
  if not _templates[template]?
    print "Template #{template} isn't configured in `_templates`"
    return null
  rel = path.relative(path.dirname(template), __dirname)
  {scripts, style, args} = _templates[template]
  return {
    args:     args
    scripts: [
      (swapSlash path.join rel, file.replace /\.(coffee|pegjs)$/, ".js" for file in common_scripts)...
      (swapSlash path.join rel, file.replace /\.(coffee|pegjs)$/, ".js" for file in scripts)...
    ]
    style: [
      (swapSlash path.join rel, file.replace /\.styl$/, ".css" for file in common_style)...
      (swapSlash path.join rel, file.replace /\.styl$/, ".css" for file in style)...
    ]
  }

# All files to be compiled
_all_files = 
  templates:  []
  scripts:    [
    (path.normalize file for file in common_scripts)...
    (path.normalize file for file in worker_scripts)...
  ]
  style:      (path.normalize file for file in common_style)
  static:     (path.normalize file for file in static_files)
for template, {scripts, style} of _templates
  _all_files.templates.push  path.normalize template
  _all_files.scripts.push    (path.normalize file for file in scripts)...
  _all_files.style.push      (path.normalize file for file in style)...


# Command line tools
_cmds =
  coffee: 'coffee'
  stylus: 'stylus'
  jade:   'jade'
  docco:  'docco'
  pegjs:  'pegjs'
  cake:   'cake'
  rsync:  'rsync'

# Postfix commandline tools with .cmd if one windows
if process.platform is "win32"
  _cmds[id] = "#{cmd}.cmd"     for id, cmd of _cmds


#### Cake Tasks

task 'deploy', "Rebuild everything, upload to wktool.jonasfj.dk from bin/", ->
  # Delete everything from bin/
  rmdir path.join __dirname, 'bin'
  # Run cake release as subtask
  proc = spawn _cmds.cake, ['build']
  proc.stdout.on 'data', (data) -> print data
  proc.stderr.on 'data', (data) -> print data
  proc.on 'exit', (status) ->
    print_msg("cake build", status is 0, "")
    if status is 0
      # git add
      log = ""
      proc = spawn _cmds.rsync, ['-ar', '--delete', 'bin/', _target_site]
      proc.stdout.on 'data', (data) -> log += data
      proc.stderr.on 'data', (data) -> log += data
      proc.on 'exit', (status) ->
        print_msg("rsync -arv --delete bin/ #{_target_site}", status is 0, log)

task 'build', "Compile all source files", ->
  for file in _all_files.scripts
    if /\.coffee$/.test file
      compile file
    else if /\.pegjs$/.test file
      generate file
    else
      copy file
  for file in _all_files.style
    if /\.styl$/.test file
      translate file
    else 
      copy file
  for file in _all_files.static
    copy file
  for file in _all_files.templates
    render file

task 'watch', "Restart cake watch-files on changes to cake file", ->
  cake = null
  restart = ->
    if cake?
      cake.kill()
    cake = spawn _cmds.cake, ['build', 'watch-files'],
            stdio: ['ignore', process.stdout, process.stderr]
  restart()
  watch __dirname, (file) ->
    file = path.relative __dirname, file
    if file is 'Cakefile'
      restart()

task 'watch-files', "Rebuild files on changes", ->
  watch __dirname, (file) ->
    file = path.relative __dirname, file
    if file in _all_files.scripts
      if /\.coffee$/.test file
        compile file
      else if /\.pegjs$/.test file
        generate file
      else
        copy file
    if file in _all_files.style
      if /\.styl$/.test file
        translate file
      else 
        copy file
    if file in _all_files.templates
      render file
    if file in _all_files.static
      copy file

task 'server', "Launch development server", ->
  connect(
    connect.static(path.join __dirname, 'bin')
  ).listen _port

task 'develop', "Build, watch and launch development server", ->
  invoke 'watch'
  invoke 'server'

task 'docs',  "Generate source code documentation", ->
  exec "Generating Documentation",
       _cmds.docco, '-c', 'docco.css', _all_files.scripts...

task 'clean', "Clean-up generated files", ->
  failed = false
  log = ""
  try
    # Delete everything from bin/
    rmdir path.join __dirname, 'bin'
  catch e
    failed = true
    log = e.toString() + "\n"
  print_msg "Removed generated files", not failed, log




#### Compilation of files

compile = (file) ->
  dst = path.dirname path.join __dirname, 'bin', file
  mkdirp dst
  exec "Compiling   #{file}",
        _cmds.coffee, '-c', '-o', dst, file

generate = (file) ->
  dst = path.dirname path.join __dirname, 'bin', file
  mkdirp dst
  target = path.join dst, path.basename(file).replace /\.pegjs$/, '.js'
  variable = "(typeof module === 'undefined' ? this : module.exports)"
  variable += "['#{path.basename file, '.pegjs'}']"
  exec "Generating  #{file}",
        _cmds.pegjs, '--track-line-and-column', '--cache', '-e', variable, file, target

translate = (file) ->
  dst = path.dirname path.join __dirname, 'bin', file
  mkdirp dst
  exec "Translating #{file}",
       _cmds.stylus, '-o', dst, file

render = (file) ->
  dst = path.dirname path.join __dirname, 'bin', file
  mkdirp dst
  obj = JSON.stringify(template_arguments(file))
  exec "Rendering   #{file}",
       _cmds.jade, '--out', dst, '--pretty', '--path', file, '--obj', obj, file

copy = (file) ->
  dst = path.dirname path.join __dirname, 'bin', file
  mkdirp dst
  target = path.join dst, path.basename(file)
  failed = false
  log = ""
  try
    data = fs.readFileSync file
    fs.writeFileSync target, data
  catch e
    failed = true
    log = e.toString() + "\n"
  print_msg "Copying     #{file}", not failed, log

#### Auxiliary Functions

# Terminal colors
reset     = "\u001b[0m"
red       = (s) -> "\u001b[31m" + s + reset
bold      = (s) -> "\u001b[1m" + s + reset
underline = (s) -> "\u001b[4m" + s + reset
highlight = (s) -> "\u001b[47m" + s + reset

# Execute cmd with args, writing msg as title in terminal
exec = (msg, cmd, args...) ->
  log = ""
  proc = spawn cmd, args
  proc.stdout.on 'data', (data) -> log += data
  proc.stderr.on 'data', (data) -> log += data
  proc.on 'exit', (status) ->
    print_msg(msg, status is 0, log)

# Print a nice message of what happend, success/failure and log
print_msg = (msg, success, log) ->
  result = ""
  result_length = msg.length
  if success
    result = "[Success]"
    result_length += result.length
  else
    result = "[Failed]"
    result_length += result.length
    result = red result
  length = Math.max(Math.abs(80 - result_length), 0)
  padding = (" " for i in [0...length]).join("")
  print msg + padding + result + '\n'
  if log != ""
    print log

# Recursively delete a folder
rmdir = (folder) ->
  for name in fs.readdirSync(folder)
    file = path.join folder, name
    if fs.statSync(file).isDirectory()
      rmdir file
    else
      fs.unlinkSync file
  fs.rmdirSync folder

# Recursively create folder
mkdirp = (folder, mode) ->
  folder = path.resolve folder
  try
    fs.mkdirSync folder, mode
  catch e
    if e.code is 'ENOENT'
      mkdirp path.dirname(folder), mode
      fs.mkdirSync folder, mode
