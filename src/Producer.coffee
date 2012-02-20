uuid = require 'node-uuid'
Base = require './Base'

class Producer extends Base
	
	constructor: (config) ->
		super(config)
		@callbacks = {}
		@subscriptions = {}
	
	queue: (channel, data, callback) ->
		request = {id: uuid.v4(), data: data}
		if callback?
			@_subscribe @key(channel, 'response')
			@callbacks[request.id] = callback
		@redis.data.lpush @key(channel), @pack(request)
		@redis.data.publish @key(channel, 'request'), request.id
	
	onMessage: (channel, data) =>
		response = @unpack(data)
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
		else
			@subscriptions[channel]++
	
	_unsubscribe: (channel) ->
		if --@subscriptions[channel] == 0
			@redis.events.unsubscribe channel

module.exports = Producer
