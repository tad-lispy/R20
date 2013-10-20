app = angular.module 'R20', ['ngRoute']

app.config ($routeProvider) ->
  $routeProvider.when '/',
    templateUrl: 'home.html'
    controller: 'Main'

controllers =
  Main: ($http) ->
    console.log 'Controller init'
    console.log JSON.stringify @
    @name = 'Application name'

    # about = $http.get '/about'
    # console.log JSON.stringify @
    # about.success (data) =>
    #   console.log 'about to succeed'
    #   console.log JSON.stringify @
    #   @engine = 'R20'
    #   @[key] = value for key, value of data


app.controller controllers
