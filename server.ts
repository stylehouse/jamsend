import { Server } from 'socket.io';
import { handler } from './build/handler.js';
import { init_an_io } from './src/lib/ws-server/ws-server';
import express from 'express';
import { createServer } from 'http';

const app = express();
const server = createServer(app);

// Initialize Socket.IO
const io = new Server(server);

init_an_io(io)

// requests for eg /_app/immutable/entry/app.6lm5gro6.js
// which are in this directory
app.use(express.static('build/client'));
// Let SvelteKit handle everything else..?
// will come up with something to be 'GET /'
//  leading to the above (they have to be in this order)
app.use(handler);

const port = process.env.PORT || 19091;
const host = process.env.HOST || '0.0.0.0';

server.listen(port, host, () => {
  console.log(`socket.io server on http://${host}:${port}`);
});