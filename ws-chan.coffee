websocket = require 'websocket-stream'
backoff = require 'backoff'
{Transform, PassThrough} = require 'stream'
{Transform, PassThrough} = require 'readable-stream' unless Transform? and PassThrough?
{EventEmitter} = require 'events'

class SyncTransform extends Transform

  constructor: (fn, options = {}) ->
    options = Object.create(options)
    options.objectMode = true
    super(options)
    this.fn = fn

  _transform: (chunk, encoding, cb) ->
    try
      this.push(if this.fn? then this.fn(chunk) else chunk)
      cb()
    catch e
      cb(e)

class Channel extends EventEmitter

  constructor: (uri, options = {}) ->
    this.uri = uri
    this.options = options
    this.sock = undefined

    this.preventBackoff = false

    this.backoffState = options.backoff or backoff.exponential(options)
    if this.backoffState?
      this.backoffState.failAfter(options.failAfter) if options.failAfter?
      this.backoffState.on 'backoff', this.onBackoff.bind(this)
      this.backoffState.on 'ready', this.onBackoffReady.bind(this)
      this.backoffState.on 'fail', this.onBackoffFail.bind(this)

    this.in = new PassThrough(objectMode: true)
    this.out = new PassThrough(objectMode: true)
    this.out.pause()

    this.start() if options.start

  start: ->
    return if this.sock?
    this.sock = this.createSocket()
    this.sock.on 'open',  this.onOpen.bind(this)
    this.sock.on 'end',   this.onEnd.bind(this)
    this.sock.on 'error', this.onError.bind(this)

    this.sock
      .pipe(new SyncTransform(JSON.parse))
      .pipe(this.in, end: false)

    this.out
      .pipe(new SyncTransform(JSON.stringify), end: false)
      .pipe(this.sock)
    
  stop: ->
    this.preventBackoff = true
    this.sock.end()

  backoff: ->
    if this.backoffState? and not this.preventBackoff
      this.backoffState.backoff()

  resetBackoff: ->
    if this.backoffState?
      this.backoffState.reset()

  createSocket: ->
    websocket(this.uri)

  cleanup: ->
    this.out.unpipe()
    this.sock = undefined

  log: (msg) ->
    console.log "channel: #{msg}"

  onOpen: ->
    this.out.resume()
    this.log "connection established"
    this.emit 'open', this
    this.resetBackoff()

  onEnd: ->
    this.out.pause()
    this.log "connection terminated"
    this.emit 'end', this
    this.cleanup()
    this.backoff()

  onError: (e) ->
    this.out.pause()
    this.log "error #{e}"
    this.emit 'error', e, this
    this.cleanup()
    this.backoff()

  onBackoff: (number, delay) ->
    this.log "next connection attempt in #{delay}ms"

  onBackoffReady: ->
    this.log "trying to re-establish connection"
    this.start()

  onBackoffFail: ->
    this.log "out of attempts to re-establish connection"

module.exports = (uri, options) -> new Channel(uri, options)
module.exports.channel = exports
module.exports.Channel = Channel
