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
				
				args = [request.command]
				if request.payload? then args.push(request.payload)
				if request.replyTo? then args.push (err, result) =>
					response = {id: request.id}
					if err?    then response.err = err
					if result? then response.result = result
					@redis.data.publish @key('response', request.replyTo), @pack(response)
					
				@emit.apply(this, args)
				process.nextTick(next)
		next()
		
module.exports = Consumer
