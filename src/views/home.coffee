View = require "teacup-view"

layout  = require "./layouts/default"

module.exports = new View
  components: __dirname + "/components"
  (data) ->
    {
      query
      entries
    } = data

    layout data, =>
      @searchForm { query }
      do @hr
      @newsFeed { entries }