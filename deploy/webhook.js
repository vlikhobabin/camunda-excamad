const http = require('http');
const createHandler = require('github-webhook-handler');
const { exec } = require('child_process');

// Замените YOUR_WEBHOOK_SECRET на реальный секретный ключ при установке
const handler = createHandler({ path: '/webhook', secret: 'YOUR_WEBHOOK_SECRET' });

http.createServer((req, res) => {
  handler(req, res, (err) => {
    res.statusCode = 404;
    res.end('no such location');
  });
}).listen(7777);

handler.on('error', (err) => {
  console.error('❌ Error:', err.message);
});

handler.on('push', (event) => {
  console.log('📥 Received a push event for %s to %s',
    event.payload.repository.name,
    event.payload.ref);
    
  if (event.payload.ref === 'refs/heads/master') {
    console.log('🚀 Starting automatic deployment...');
    exec('/opt/scripts/deploy.sh', (error, stdout, stderr) => {
      if (error) {
        console.error(`❌ Deploy error: ${error}`);
        return;
      }
      console.log(`✅ Deploy output: ${stdout}`);
      if (stderr) {
        console.error(`⚠️ Deploy stderr: ${stderr}`);
      }
    });
  }
});

console.log('🎣 Webhook server listening on port 7777');
console.log('📡 Waiting for GitHub webhook events...'); 