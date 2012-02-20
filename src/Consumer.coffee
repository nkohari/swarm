redis = require 'redis'
Base  = require './Base'

class Consumer extends Base
	
	constructor: (config, @channel) ->
		super(config)
		@queueKey = @key(@channel)
		@redis.events.subscribe @key(@channel, 'request')
		console.log "[consumer] subscribed to #{@key(@channel, 'request')}"
		@process()
	
	onMessage: (channel) =>
		console.log "[consumer] got message on #{channel}"
		@process()
	
	process: ->
		next = () =>
			@redis.data.rpop @queueKey, (err, data) =>
				return if err?
				request = @unpack(data)
				return unless request?
				console.log "[consumer] processing #{request.id}"
				@emit 'request', request.data, (err, result) =>
					console.log "[consumer] got response"
					response =
						id:     request.id
						status: if err? then 'failure' else 'success'
						err:    err
						result: result
					@redis.data.publish @key(@channel, 'response'), @pack(response)
					console.log "[consumer] queued response on #{@key(@channel, 'response')}"
				process.nextTick(next)
		next()
		
module.exports = Consumer
