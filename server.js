import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js'
import { createServer } from 'node:http'

const host = process.env.MCP_HOST ?? 'localhost'
const port = Number(process.env.MCP_PORT ?? 3000)
const endpoint = '/mcp'
const pendingMoves = []
const position = { x: 0, y: 0 }

const movements = [
  { tool: 'move_left', direction: 'left', label: 'izquierda' },
  { tool: 'move_right', direction: 'right', label: 'derecha' },
  { tool: 'move_up', direction: 'up', label: 'arriba' },
  { tool: 'move_down', direction: 'down', label: 'abajo' },
]

function createMcpServer() {
  const mcp = new McpServer({
    name: 'wollok-game',
    version: '1.0.0',
  })

  for (const { tool, direction, label } of movements) {
    mcp.registerTool(
      tool,
      { description: `Mueve al personaje hacia ${label}.` },
      async () => {
        pendingMoves.push(direction)
        return {
          content: [{ type: 'text', text: `Movimiento ${direction} agregado a la cola.` }],
        }
      },
    )
  }

  mcp.registerTool(
    'get_position',
    { description: 'Indica la posición actual del personaje en coordenadas x e y.' },
    async () => ({
      content: [{ type: 'text', text: `La posición actual del personaje es (${position.x}, ${position.y}).` }],
    }),
  )

  return mcp
}

async function readJsonBody(request) {
  let body = ''

  for await (const chunk of request) {
    body += chunk
    if (body.length > 1_000_000) {
      throw new Error('El cuerpo de la solicitud supera el límite de 1 MB')
    }
  }

  return JSON.parse(body)
}

function sendError(response, status, message) {
  response.writeHead(status, { 'Content-Type': 'application/json' })
  response.end(JSON.stringify({ error: message }))
}

function serveMCP(mcp) {

  const httpServer = createServer(async (request, response) => {
    const requestUrl = new URL(request.url, `http://${host}:${port}`)
    if (requestUrl.pathname !== endpoint) {
      sendError(response, 404, 'Ruta inexistente')
      return
    }

    if (request.method !== 'POST') {
      response.writeHead(405, { Allow: 'POST' })
      response.end()
      return
    }

    let body
    try {
      body = await readJsonBody(request)
    } catch (error) {
      sendError(response, 400, error instanceof SyntaxError ? 'JSON inválido' : error.message)
      return
    }

    const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined })

    response.on('close', () => {
      void transport.close()
      void mcp.close()
    })

    try {
      await mcp.connect(transport)
      await transport.handleRequest(request, response, body)
    } catch (error) {
      console.error('Error al procesar solicitud MCP:', error)
      if (!response.headersSent) {
        sendError(response, 500, 'Error interno del servidor MCP')
      }
    }
  })

  httpServer.listen(port, host, () => {
    const address = httpServer.address()
    const listeningPort = typeof address === 'object' && address ? address.port : port
    console.log(`🤖 MCP available at http://${host}:${listeningPort}${endpoint}`)
  })

}

export { pendingMoves, position, serveMCP }
