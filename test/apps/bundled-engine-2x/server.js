const http = require('http')
const express = require('express')
const buffertools = require('buffertools')

const port = process.env.PORT || '3000'

const app = express()
app.disable('x-powered-by')
app.set('env', 'production')

app.get('/', (req, res) => {
  res.status(200).json({
    buff: buffertools.concat(new Buffer('buf'), new Buffer('fer')).toString(),
    uuid: process.argv[2],
    versions: {
      node: process.version.slice(1),
      nsolid: process.versions.nsolid
    }
  })
})

const server = http.createServer(app)
server.listen(port, () => {
  console.log(`server running on http://localhost:${port}`)
})
