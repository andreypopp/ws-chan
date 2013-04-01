stream = require 'stream'
{equal, deepEqual} = require 'assert'
{Channel} = require '../ws-chan'

class TestChannel extends Channel

  constructor: (options) ->
    options.start = true
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

  it 'messages from sock can be read from Channel.in', (done) ->

    chan = new TestChannel(start: true)

    chan.in.on 'data', (message) ->
      deepEqual(message, {hello: 'world'})
      done()

    chan.sock.write(JSON.stringify({hello: 'world'}))

  describe 'reconnection logic', ->

    it 're-establishes connection on end of a socket stream', (done) ->

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
