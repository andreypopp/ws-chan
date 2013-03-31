# ws-chan

WebSocket interaction modeled as a pair of streams, for incoming and outgoing
messages correspondingly. It provides:

  * JSON encoding/decoding of incoming/outgoing messages correspondingly
  * reconnect logic with exponential backoff (by default)
