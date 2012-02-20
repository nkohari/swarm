uuid = require 'node-uuid'
Base = require './Base'

class Producer extends Base
	
	constructor: (config) ->
		super(config)
		@callbacks = {}
		@subscriptions = {}
	
	queue: (channel, data, callback) ->
		request = {id: uuid.v4(), data: data}
		
		console.log "[producer] queuing #{request.id}"
		
		if callback?
			@_subscribe @key(channel, 'response')
			@callbacks[request.id] = callback
		
		@redis.data.lpush @key(channel), @pack(request)
		@redis.data.publish @key(channel, 'request'), request.id
	
	onMessage: (channel, data) =>
		console.log "[consumer] got message on #{channel}"
		response = @unpack(data)
		console.log "[producer] got response for #{response.id}"
		callback = @callbacks[response.id]
		if callback?
			callback(response.err, response.result)
			delete @callbacks[response.id]
			@_unsubscribe(channel)
		@emit response.status, response

	_subscribe: (channel) ->
		if not @subscriptions[channel]
			@subscriptions[channel] = 1
			@redis.events.subscribe channel
			console.log "[producer] subscribed to #{channel}"
		else
			@subscriptions[channel]++
		console.log "[producer] subscriber count for #{channel} is #{@subscriptions[channel]}"
	
	_unsubscribe: (channel) ->
		if --@subscriptions[channel] == 0
			console.log "[producer] unsubscribed from #{channel}"
			@redis.events.unsubscribe channel
		console.log "[producer] subscriber count for #{channel} is #{@subscriptions[channel]}"

module.exports = Producer
