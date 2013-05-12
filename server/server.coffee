Meteor.publish 'tables', ->
  Tables.find {}

Meteor.startup ->
  resetDatabase unless Tables.find().count > 0
