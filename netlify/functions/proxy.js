const https = require('https');

exports.handler = async (event) => {
  const path = event.path.replace('/.netlify/functions/proxy', '');
  const url = `https://kewere-aissa-smart.onrender.com${path}`;
  
  return new Promise((resolve) => {
    const options = {
      method: event.httpMethod,
      headers: {
        ...event.headers,
        'host': 'kewere-aissa-smart.onrender.com',
      },
    };

    const req = https.request(url, options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': '*',
            'Content-Type': 'application/json',
          },
          body,
        });
      });
    });

    if (event.body) req.write(event.body);
    req.end();
  });
};