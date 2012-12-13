# front-end for model checker



#e1 = new WCTL.AtomicExpr('a')
#e2 = new WCTL.AtomicExpr('b')
#formula = new WCTL.UntilExpr(WCTL.quant.E, e1, e2, 5)

nanoTime = null

WKS = null              # Underlying model
wks_editor = null
state_selector = null   # Selector for initial state
engine_selector = null  # Selector for engine
alg_selector    = null
status = null           # Output box for results, errors or whatever.
initial_state = 0       # Initial state to verify against
engine = "NaiveEngine"  # Verification engine, default naive
algorithm    = "local"

sample = "digraph {\n
    s      [label = \"start { a }\"];\n
    t      [label = \"end { a,b }\"];\n
    s -> t [label = \"2\"];\n
}"
# DOM string for the progressbar
progress = "<div class='progress progress-striped active'>
              <div class='bar' style='width: 0%;'></div>
            </div>"
$(document).ready ->
  timer = $("#nano")[0]
  nanoTime = ->
    try
      return timer.nanoTime() / 1000000
    catch e
      console.log "TIMER: Fall-back to javascript timer."
      nanoTime = ->
        return (new Date).getTime()
      return nanoTime()

  state_selector = $("#states")
  engine_selector = $("#engine_selector")
  alg_selector = $("#alg_selector")
  status = $("#status")

  wks_sample = CodeMirror document.getElementById("wks_sample"),
      mode:           "WKS"
      lineNumbers:    true
      tabSize:        2
      readOnly:       true

  wks_sample.setValue(sample)

  wks_editor = CodeMirror document.getElementById("wks"),
      mode:           "WKS"
      lineNumbers:    true
      tabSize:        2
      lineWrapping:   true
  wks_editor.setValue(sample)
  
  wctl_editor = CodeMirror document.getElementById("query"), 
      mode:           "WCTL"
      lineNumbers:    false
      tabSize:        2
      lineWrapping:   true
  wctl_editor.setValue("E a U[5] b")
# syntax help buttons
  $("#btn_wctl_syntax").click ->
    $("#syntax_wctl").toggle()
  $("#btn_wks_syntax").click ->
    $("#syntax_wks").toggle()
    wks_sample.refresh()
  #Engine selector set-up
  engine_selector.find("a").first().addClass "active"
  engine_selector.find("a").click ->
    engine_selector.find("a").removeClass "active"
    engine = $(this).data("engine")
    $(this).addClass "active"
  #Alg selector set-up
  alg_selector.find("a").last().addClass "active"
  alg_selector.find("a").click ->
    alg_selector.find("a").removeClass "active"
    algorithm = $(this).data("alg")
    $(this).addClass "active"


  example_show = false
  removeExampleShow = (e) ->
    e.stopPropagation()
    if not example_show
      $(".dropdown-menu").show()
      $(window).on 'click', removeExampleShow
      example_show = true
    else
      $(".dropdown-menu").hide()
      $(window).off 'click', removeExampleShow
      example_show = false
  $("#btn_example").click removeExampleShow


  # Select an example
  $(".dropdown-menu li a").click (e) ->
    file =  $(this).html()
    cb = (data) ->
      wks_editor.setValue data
    $.get "examples/#{file}", cb, 'text'

  # Runs verification
  $("#btn_check").click ->
    try
      ast = WCTLParser.parse(wctl_editor.getValue())
      console.log WKS
      start = nanoTime()
      status.removeClass()
      if(engine == "SymbolicEngine")
        checker = new SymbolicEngine(WKS, ast)
        checkval = 0
      else
        checker = new NaiveEngine(WKS, ast)
        checkval = true
      if checker[algorithm](initial_state) == checkval
        msg = "Property is satisfied."
        status.addClass "alert alert-success well"
      else
        msg = "Property is not satisfied."
        status.addClass "alert well"
      status.html(msg + "<span style='float: right;' class=\"badge badge-info\">" + (nanoTime() - start).toFixed(3) + " ms.</span>")
    catch error
      status.removeClass().html(error.message)
      status.addClass "alert alert-error well"
    status.fadeIn()

  $("#btn_benchmark").click ->
    try
      start = nanoTime()
      val = null
      confused = false
      status.removeClass()
      #status.fadeIn().html(progress)
      #progress_bar = status.find(".bar")
      for i in [0...50]
        ast = WCTLParser.parse(wctl_editor.getValue())
        #progress_bar.css("width", "#{(i/50)*100}%")
        if(engine == "SymbolicEngine")
          checker = new SymbolicEngine(WKS, ast)
          checkval = 0
        else
          checker = new NaiveEngine(WKS, ast)
          checkval = true
        retval = checker[algorithm](initial_state) == checkval
        if retval != val and val != null
          confused = true
        val = retval
      if val and not confused
        msg = "Property is satisfied."
        status.addClass "alert alert-success well"
      else if not confused
        msg = "Property is not satisfied."
        status.addClass "alert well"
      else
        msg = "Property was both verified and rejected on different runs, we have a bug."
        status.addClass "alert alert-error well"
      status.html(msg + "<span style='float: right;' class=\"badge badge-info\">" + ((nanoTime() - start) / 50).toFixed(3) + " ms.</span>")
    catch error
      status.removeClass().html(error.message)
      status.addClass "alert alert-error well"
    status.fadeIn()
    
  # Clear buttons
  $("#btn_clear").click ->
    wctl_editor.setValue("")
  $("#btn_clear_wks").click ->
    wks_editor.setValue("")

  # Parse WKS
  ParseWKS = (popEdit = true) ->
    status.hide()
    try
      WKS = WKSParser.parse(wks_editor.getValue())
      WKSEdit.load(WKS)   if popEdit
    catch error
      status.removeClass().html(error.message)
      status.addClass "alert alert-error well"
      status.fadeIn()
    $("#statebox").fadeIn()
    state_selector.empty()
    for i in [0...WKS.states]
      state_selector.append "<option value='#{i}'>#{WKS.names[i]}</option>"

    state_selector.change ->
      initial_state = $(this).val()
  $("#btn_add_wks").click ParseWKS

  # Parse initial model
  ParseWKS(false)

# Select a state from the canvas
WKSEdit.selected = (state) ->
  state_selector.val(state)
  state_selector.fadeTo('fast', 0.1).fadeTo('fast', 1.0)
  initial_state = state