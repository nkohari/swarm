Swarm is a simple job queue backed by Redis. It's a lot like [Resque](https://github.com/defunkt/resque), but has support for bi-directional communication between producers and consumers. Also, rather than have consumers poll for new jobs, it uses Redis pub/sub to announce new requests and responses.

__NOTE: I JUST WROTE THIS. IT IS NOT PRODUCTION-QUALITY. PLEASE DO NOT USE IT IN ANY MISSLE-CONTROL SYSTEMS.__

# Example

Here's a simple example, with one producer and one consumer:

	swarm = require './swarm'
	
	producer = swarm.createProducer()
	consumer = swarm.createConsumer('math')
	
	consumer.on 'add', (items, callback) ->
		sum = 0
		sum += item for item in items
		callback(null, sum)
		
	producer.queue 'math', 'add', [2, 3, 4], (err, result) ->
		if err? then console.log "The request failed: #{err}"
		else console.log "The result was #{result}"

With each call to `queue()`, the producer adds the request to a FIFO queue via `LPUSH` and executes a corresponding `PUBLISH` to announce to consumers that new work has arrived. When consumers receive this message they `RPOP` the request from the queue and emit an event with the request payload and a callback.

Your consuming code should subscribe to the `request` event on the consumer, perform the work, and (optionally) pass the result to the callback when complete. If you call the callback, the consumer will `PUBLISH` a message containing the result. Producers listen for this result message and trigger the callback provided during the original call to `queue()`.

When a consumer receives an indication that new requests are queued, it will continue trying to `RPOP` requests until the queue is empty or an error occurs.

# API

## swarm.configure(options)

You can call this function to configure global options. The options are:

- `host`: The hostname or IP address of the Redis server _(default: localhost)_
- `port`: The port number of the Redis server _(default: 6379)_
- `namespace`: A string to distinguish your swarm from others that are using the same Redis server. _(default: 'swarm')_

## swarm.createProducer()

Creates a producer, which can queue requests.

## swarm.createConsumer(channel)

Creates a consumer, which will announce requests received on the specified channel.

## Producer Functions

Producers queue requests to be completed by one or more consumers. One producer can queue requests on any number of channels.

### producer.queue(channel, command, [payload], [callback])

This function will queue a request for processing by one or more consumers.
	
- `channel`: The channel to publish the request to. This is just a general topic that can be used to group consumer functionality.
- `command`: The command to execute, like a function call. This will be the event emitted by the consumer.
- `payload`: The (optional) payload to pass with the request.
- `callback`: The (optional) callback to execute when a response is received. Callbacks use the typical Node form of `(err, result)`. If you don't supply a callback, the producer won't `SUBSCRIBE` to any results.

## Consumer Functions

When requests are received, consumers emit events corresponding to the commands that were passed to the `queue()` call.

### consumer.on command, handler

To handle requests for a given `command`, you should listen for the corresponding event on the consumer.

If a payload was sent with the request, the handler will be called with `(payload, callback)`, and if not, it will be called just with `(callback)`.

The event handler that you supply should do whatever work is necessary, and then (optionally) call the callback.

# License (MIT)

Copyright (c) 2012 Nate Kohari.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.