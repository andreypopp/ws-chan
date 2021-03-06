stream = require 'stream'
{equal, deepEqual} = require 'assert'
{Channel} = require '../ws-chan'

class TestChannel extends Channel

  constructor: (options = {}) ->
    super('', options)

  createSocket: ->
    sock = new stream.PassThrough   
    open = -> sock.emit 'open'
    setTimeout(open, 50)
    sock

describe 'Channel', ->

  it 'writes to sock on write to Channel.out', (done) ->
    chan = new TestChannel(start: true)

    chan.sock.on 'data', (chunk) ->
      data = JSON.parse(chunk)
      deepEqual(data, {hello: 'world'})
      done()

    chan.out.write({hello: 'world'})

  it 'allows messages from sock can be read from Channel.in', (done) ->

    chan = new TestChannel(start: true)

    chan.in.on 'data', (message) ->
      deepEqual(message, {hello: 'world'})
      done()

    chan.sock.write(JSON.stringify({hello: 'world'}))

  it 'allows messages from sock can be read from Channel.in (delayed start)', (done) ->

    chan = new TestChannel()

    chan.in.on 'data', (message) ->
      deepEqual(message, {hello: 'world'})
      done()

    chan.start()

    chan.sock.write(JSON.stringify({hello: 'world'}))

  it 'queues outgoing messages before connect', (done) ->
    chan = new TestChannel()

    chan.out.write({hello: 'world'})

    chan.on 'open', ->
      chan.sock.on 'data', (chunk) ->
        data = JSON.parse(chunk)
        deepEqual(data, {hello: 'world'})
        done()

    chan.start()

  describe 'reconnection logic', ->

    it 'maintains in channel connected to current socket', (done) ->

      first = true

      chan = new TestChannel(start: true)

      chan.in.on 'data', (message) ->
        deepEqual(message, {hello: 'world'})
        done()

      chan.on 'open', ->
        if first
          chan.sock.end()
          first = false
        else
          chan.sock.write(JSON.stringify({hello: 'world'}))

    it 'maintains out channel connected to current socket', (done) ->

      first = true

      chan = new TestChannel(start: true)

      chan.on 'open', ->
        if first
          chan.sock.end()
          first = false
        else
          chan.sock.on 'data', (data) ->
            message = JSON.parse(data)
            deepEqual(message, {hello: 'world'})
            done()
          chan.out.write({hello: 'world'})
