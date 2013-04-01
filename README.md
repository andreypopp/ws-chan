# ws-chan

WebSocket interaction modeled as a pair of streams, for incoming and outgoing
messages correspondingly. It provides:

  * JSON encoding/decoding of incoming/outgoing messages correspondingly
  * reconnect logic with exponential backoff (by default)

## Example usage

On a client:

```javascript
var channel = require('ws-chan');
var ch = channel('ws://localhost');

ch.in.on('data', function(message) {
  console.log('received', message);
});
ch.out.write({'data': 1});
```

Channel also emits `open`, `end` and `error` events on corresponding socket
stream events.

On socket `end` and `error` channel tries to re-establish a connection after
some timeout which is handled by node-backoff module (by default exponential
backoff algorithm is used).
