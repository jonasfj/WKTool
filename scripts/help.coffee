

$ ->
  $('.close-button').click ->
    window.parent.postMessage({type: 'close-help-message'}, Utils.origin())
  $('[data-highlight]').each ->
    mode = $(this).data('highlight')
    text = $(this).data('code') + ""
    $(this).empty()
    CodeMirror.runMode text, mode, this