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
