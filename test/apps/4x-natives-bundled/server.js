const http = require('http')
const express = require('express')
const buffertools = require('buffertools')

const port = process.env.PORT || '3000'

const app = express()
app.disable('x-powered-by')
app.set('env', 'production')

const result = {
  uuid: process.argv[2],
  versions: {
    node: process.version.slice(1),
    nsolid: process.versions.nsolid
  }
}

app.get('/', (req, res) => {
  result.buff = buffertools.concat(new Buffer('buf'), new Buffer('fer')).toString()
  res.status(200).json(result)
})

const server = http.createServer(app)
server.listen(port, () => {
  console.log(`server running on http://localhost:${port}`)
})
