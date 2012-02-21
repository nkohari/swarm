uuid = require 'node-uuid'
Base = require './Base'

class Producer extends Base
	
	constructor: (config) ->
		super(config)
		@id = uuid.v4()
		@redis.events.subscribe @key('response', @id)
		@callbacks = {}
	
	queue: (args...) ->
		channel  = args.shift()
		command  = args.shift()
		payload  = args.shift() unless args[0] instanceof Function
		callback = args.shift()
		
		request = {id: uuid.v4(), command: command, payload: payload}
		
		if callback?
			request.replyTo = @id
			@callbacks[request.id] = callback
			
		@redis.data.lpush @key(channel), @pack(request)
		@redis.data.publish @key(channel, 'request'), ''
	
	onMessage: (channel, data) =>
		response = @unpack(data)
		callback = @callbacks[response.id]
		
		if callback?
			callback(response.err, response.result)
			delete @callbacks[response.id]
			
		event = if response.err? then 'failure' else 'success'
		@emit event, response

module.exports = Producer
