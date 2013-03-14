#! /usr/bin/env coffee


[program, cwd, filename, option] = process.argv


if not filename?
  console.log "usage: table.coffee [FILE] [--latex]"
  process.exit(1)

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
    if result.failed is "Unknown"
      if result.message.indexOf("process out of memory") != -1
        result.failed = "OOM"
    return result.failed
  time = (parseInt(result.time_s)) + (parseInt(result.time_ns) / 1000000000)
  return time.toFixed(2)

if option isnt '--latex'
  # Print all tables in ASCII art
  for model, properties of data
    for property, subtable in properties
      colsDefined = []
      for col of property.instances[0] when col in cols
        colsDefined.push col
      firColLen = ("" + (property.instances[property.instances.length - 1].param)).length
      console.log ""
      console.log "Table: \"" + model + "\" Sub-table: " + subtable
      console.log property.state + " |= " + property.formula.replace(/#.*/, "").replace("\n", "")
      console.log FormatLength(" ", firColLen) + "  " + (FormatLength(col, 20) for col in colsDefined).join('')
      for instance, i in property.instances
        console.log "#{FormatLength(instance.param[property.pindex], firColLen)}: " + (FormatLength(findTime(instance[col].result), 20) for col in colsDefined).join('')
  
  # Tables print, exit 0
  process.exit(0)



# Print beginning of latex document
console.log [
  "\\documentclass{article}"
  "\\usepackage{multirow}"
  "\\usepackage{rotating}"
  "\\usepackage{array,graphicx}"
  ""
  "\\begin{document}"
].join('\n')

for model, properties of data
  for property, subtable in properties
    console.log ""
    console.log "% Table: \"" + model + "\" Sub-table: " + subtable
    # Find columns defined
    columnsDefined = (col for col of property.instances[0] when col in cols)
    pindex         = property.pindex

    console.log "\\begin{tabular}{| #{('r' for i in [0...2 + columnsDefined.length]).join(' | ')} |}\\hline"

    console.log FormatLength("$n$", 7) + " & " + (FormatLength(col, 20) for col in columnsDefined).join(' & ') + " & \\\\\\hline"

    _firstRow = true
    print_row = (vals) ->
      if _firstRow # print multirow if first row
        _firstRow = false
        rows = property.instances.length-1
        formula = property.formula.replace(/#.*/, "").replace("\n", "")
        sat = ""
        if not property.sat
          sat = "\\not"
        console.log [
          FormatLength(vals[0], 7) + " & "
          (FormatLength(val, 20) for val in [vals[1...]...]).join(' & ')
          " & \n"
          "\\parbox[t]{4mm}{"
          "\\multirow{#{rows}}{*}{\\rotatebox[origin=c]{-90}{"
          "$\\textit{#{property.state}} #{sat}\\models #{formula}$ "
          "}}"
          "}"
          "\\\\"
        ].join('')
      else
        console.log FormatLength(vals[0], 7) + " & " + (FormatLength(val, 20) for val in [vals[1...]...]).join(' & ') + " & \\\\"

    findTime2 = (result) ->
      if result.failed?
        if result.failed is "Unknown"
          if result.message.indexOf("process out of memory") != -1
            result.failed = "OOM"
        return result.failed
      time = (parseInt(result.time_s)) + (parseInt(result.time_ns) / 1000000000)
      return parseFloat time.toFixed(2)

    for instance in property.instances
      values = ["$" + instance.param[property.pindex] + "$"]
      for col in columnsDefined
        time = findTime2(instance[col].result)
        if typeof time is 'number'
          values.push "$" + time.toFixed(2) + "$"
        else
          values.push time
      print_row(values)
    console.log "\\hline"

    console.log "\\end{tabular}\n"


#& \multicolumn{2}{|c|}{DG} & \multicolumn{2}{|c|}{SDG} & \\ \hline
#Scale & L-dfs & G & L-dfs & G & Formula \\ \hline
#	1 & 0 & 0 & 0 & 0 & \multirow{3}{*}{ \begin{rotate}{90} $EF \phi$ \end{rotate} } \\
#	2 & 0 & 0 & 0 & 0 & \\
#	3 & 0 & 0 & 0 & 0 & \\ \hline


# Print end of document
console.log "\\end{document}"

