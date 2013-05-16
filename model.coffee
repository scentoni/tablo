# Each table is represented by a document in the Tables collection:
#   owner: user id
#   title, description: String
#   data: Array of Number
#   variables: Array of String
#   categories: Array of Array of String
#   publicq: Boolean
#   viewshares, editshares: Array of user id's that are shared

@Tables = new Meteor.Collection("tables")

Tables.allow
  insert: (userId, table) ->
    false # no cowboy inserts -- use createTable method

  update: (userId, table, fields, modifier) ->
    return false if userId isnt table.owner # not the owner
    allowed = ["title", "description", "data", "variables", "categories", "publicq"]
    return false if _.difference(fields, allowed).length # tried to write to forbidden field
    true

  remove: (userId, table) ->
    # You can only remove tables that you created
    table.owner is userId

######################

Meteor.methods
  # options should include: title, description, data, publicq
  createTable: (options = {}) ->
    throw new Meteor.Error(400, "Required parameter missing") unless typeof options.title is "string" and options.title.length and typeof options.description is "string" and options.description.length
    throw new Meteor.Error(413, "Title too long") if options.title.length > 100
    throw new Meteor.Error(413, "Description too long") if options.description.length > 1000
    throw new Meteor.Error(403, "You must be logged in") unless @userId
    Tables.insert
      owner: @userId
      data: options.data
      variables: options.variables
      categories: options.categories
      title: options.title
      description: options.description
      publicq: options.publicq

  updateTable: (options = {}) ->
    throw new Meteor.Error(400, "Required parameter missing") unless typeof options.title is "string" and options.title.length and typeof options.description is "string" and options.description.length
    throw new Meteor.Error(413, "Title too long") if options.title.length > 100
    throw new Meteor.Error(413, "Description too long") if options.description.length > 1000
    throw new Meteor.Error(403, "You must be logged in") unless @userId
    Tables.update options._id,
      $set:
        data: options.data
        variables: options.variables
        categories: options.categories
        title: options.title
        description: options.description
        publicq: options.publicq


  resetDB: ->
    resetDatabase()

@displayTitle = (table) ->
  table.title

@lookupTableID = (table) ->
  table._id

@isAdmin = (user) ->
  user.roles.some (role) -> role is 'admin'
