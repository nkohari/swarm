redis = require 'redis'
Base  = require './Base'

class Consumer extends Base
	
	constructor: (config, @channel) ->
		super(config)
		@queueKey = @key(@channel)
		@redis.events.subscribe @key(@channel, 'request')
		@process()
	
	onMessage: (channel) =>
		@process()
	
	process: ->
		next = () =>
			@redis.data.rpop @queueKey, (err, data) =>
				return if err?
				request = @unpack(data)
				return unless request?
				@emit 'request', request.data, (err, result) =>
					response =
						id:     request.id
						status: if err? then 'failure' else 'success'
						err:    err
						result: result
					@redis.data.publish @key(@channel, 'response'), @pack(response)
				process.nextTick(next)
		next()
		
module.exports = Consumer
