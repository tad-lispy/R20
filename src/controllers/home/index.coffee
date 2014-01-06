# Home controller

Controller  = require "express-controller"

debug       = require "debug"
$           = debug "R20:controllers:home"

views       =
  about       : require "../../views/about"
module.exports = new Controller
  name    : "home"
  routes  :
    start   :
      method  : "GET"
      url     : "/"
      action  : require "./start"
    about   :
      method  : "GET"
      url     : "/about"
      action  : (options, req, res) ->
        res.locals 
          text: "Piękni, młodzi i wkrótce bogaci :)"
        res.send views.about res.locals



