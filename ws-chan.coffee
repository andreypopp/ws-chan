websocket = require 'websocket-stream'
backoff = require 'backoff'
Stream = require 'stream'

class SyncTransform extends Stream.Transform

  constructor: (fn, options) ->
    options = Object.create(options)
    options.objectMode = true
    super(options)
    this.fn = fn

  _transform: (chunk, encoding, cb) ->
    try
      cb(null, if this.fn? then this.fn(chunk) else chunk)
    catch e
      cb(e, null)

class Channel

  constructor: (uri, options) ->
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

    this.in = through()
    this.out = through()

  start: ->
    this.sock = websocket(this.uri)
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

  cleanup: ->
    this.out.unpipe()

  log: (msg) ->
    console.log "channel: #{msg}"

  onOpen: ->
    this.log "connection established"
    this.resetBackoff()

  onEnd: ->
    this.log "connection terminated"
    this.cleanup()
    this.backoff()

  onError: (e) ->
    this.log "error #{e}"
    this.cleanup()
    this.backoff()

  onBackoff: (number, delay) ->
    this.log "next connection attempt in #{delay}ms"

  onBackoffReady: ->
    this.log "trying to re-establish connection"
    this.start()

  onBackoffFail: ->
    this.log "out of attempts to re-establish connection"

exports = (uri, options) -> new Channel(uri, options)
exports.channel = exports
exports.Channel = Channel
