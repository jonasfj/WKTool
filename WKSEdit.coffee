@WKSEdit = WKSEdit = {}

cy = null

$ ->
  $("#canvas").cytoscape
    layout:
        name:       'arbor'
    style: cytoscape.stylesheet()
            .selector('node').css
                'border-color':       '#777'
                'background-color':   '#fff'
                'border-width':       3
                'content':            'data(label)'
                'width':              20
                'height':             20
                'font-size':          '12px'
                'text-valign':        'bottom'
                'cursor':             'pointer'
            .selector('edge').css
                'line-color':         '#aaa'
                'content':            'data(weight)'
                'target-arrow-shape': 'triangle'
                'target-arrow-color': '#aaa'
                'width':              4
                'font-size':          '14px'
                'cursor':             'pointer'
            .selector(':selected').css
                'background-color':   '#777'
                'line-color':         '#777'
                'target-arrow-color': '#777'
    ready: ->
      cy = $("#canvas").cytoscape("get")
      cy.on 'click', 'node', (evt) ->
        console.log "event"
      cy.on 'select', 'node', (evt) ->
        if WKSEdit.selected?
          WKSEdit.selected(evt.cyTarget.data().id)
    elements: [
      {group: 'nodes', data: {id: "0", label: "start {a}"}},
      {group: 'nodes', data: {id: "1", label: "end {a,b}"}},
      {group: 'edges', data: {id: "0-1", source: '0', target: '1', weight: "2"}}
    ]
    $('#canvas').keydown (e) ->
      console.log "Event: " + e.which
      if e.which is 46
        cy.$('').edgesWith('node:selected').remove()
        cy.$('node:selected').remove()
      if e.which is 13
        if cy.$('node:selected').length > 0
          node = cy.$('node:selected')[0].data()
          #TODO Edit node
          console.log node
        else if cy.$('edge:selected').length > 0
          edge = cy.$('edge:selected')[0].data()
          #TODO Edit edge
          console.log edge
    $('#canvas').attr('tabindex', 1)

WKSEdit.clear = ->
  cy.$('node').remove()

WKSEdit.load = (wks) ->
  WKSEdit.clear()
  for state in [0...wks.states]
    cy.add
      group:      'nodes'
      data:
          id:     "#{state}"
          label:  wks.names[state] + " {" + wks.props[state] + "}"
  for state in [0...wks.states]
    for {weight, target} in wks.next[state]
      cy.add
        group:      'edges'
        data:
            id:     state + '-' + target
            source: "#{state}"
            target: "#{target}"
            weight: "#{weight}"
  cy.layout()