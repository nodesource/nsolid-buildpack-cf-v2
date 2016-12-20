const http = require('http')

const port = process.env.PORT || '3000'
const result = {
  uuid: process.argv[2],
  versions: {
    node: process.version.slice(1),
    nsolid: process.versions.nsolid
  }
}

const server = http.createServer(onRequest)
server.listen(port, () => {
  console.log(`server running on http://localhost:${port}`)
})

function onRequest (req, res) {
  res.statusCode = 200

  const body = JSON.stringify(result, null, 4)
  res.end(body, 'utf8')
}
