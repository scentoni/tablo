Meteor.publish 'tables', ->
  Tables.find {}

Meteor.startup ->
  ContingencyTable.resetDatabase unless Tables.find().count > 0
