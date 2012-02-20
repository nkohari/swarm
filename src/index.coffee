Producer = require './Producer'
Consumer = require './Consumer'

config =
	host: 'localhost'
	port: 6379
	namespace: 'swarm'

module.exports =
	
	configure: (options) ->
		config[name] = value for name, value of options
	
	createProducer: ->
		new Producer(config)
	
	createConsumer: (channel) ->
		new Consumer(config, channel)
