@Utils = {}

@Utils.origin = ->
  {protocol, hostname, port} = document.location
  if port
    return "#{protocol}//#{hostname}:#{port}"
  return "#{protocol}//#{hostname}"

@_gaq ?= []
@_gaq.push(['_setAccount', 'UA-479982-9'])
@_gaq.push(['_trackPageview'])
do ->
  ga = document.createElement('script')
  ga.type = 'text/javascript'
  ga.async = true
  ga.src = (if 'https:' is document.location.protocol then 'https://ssl' else 'http://www') + '.google-analytics.com/ga.js'
  s = document.getElementsByTagName('script')[0]
  s.parentNode.insertBefore(ga, s)

@Utils.track = (category, action, label, value) ->
  _gaq.push(['_trackEvent', category, action, label, value])
