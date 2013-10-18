app = angular.module 'R20', []

controllers =
  main: ->
    @engine = 'R20'
    @version= '0.0.0'
    @name   = 'Radzimy.co'
    @motto  = 'Podnosimy świadomość prawną.'

app.controller controllers
