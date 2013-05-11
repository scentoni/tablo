@Tables = new Meteor.Collection("tables")

Meteor.methods
  createTable: (options = {}) ->
    Tables.insert
      title: options.title
      data: options.data
      variables: options.variables
      categories: options.categories

@displayTitle = (table) ->
  table.title

@lookupTableID = (table) ->
  table._id
