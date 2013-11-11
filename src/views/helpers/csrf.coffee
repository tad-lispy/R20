{ renderable, input } = require "teacup"

module.exports = renderable ->
  input type: "hidden", name: "_csrf", value: @_csrf