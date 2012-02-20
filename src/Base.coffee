events = require 'events'
redis  = require 'redis'

class Base extends events.EventEmitter
	
	constructor: (@config) ->
		@redis =
			events: redis.createClient @config.port, @config.host
			data:   redis.createClient @config.port, @config.host
		@redis.events.on 'message', @onMessage
	
	onMessage: ->
	
	key: (args...) ->
		args.unshift @config.namespace
		args.join ':'
	
	pack: (message) ->
		JSON.stringify(message)
	
	unpack: (data) ->
		JSON.parse(data)

module.exports = Base
