import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js'
import { pendingMoves, position, serveMCP } from '../server.js'

const pendingCallbacks = []
var i = 0

const mcpServer = new McpServer({
  name: 'wollok-game',
  version: '1.0.0',
})


const mcp = {
  *registerAction(_self, wDescription, callback) {
    const description = wDescription.innerString
    mcpServer.registerTool(
      (i++).toString(),
      { description },
      () => new Promise((resolve, reject) => {
        pendingCallbacks.push({ callback, resolve, reject })
      }),
    )
  },

  *flush(_self) {
    while (pendingCallbacks.length > 0) {
      const { callback, resolve, reject } = pendingCallbacks.shift()
      try {
        const response = yield* this.send('apply', callback)
        resolve({
          content: [{ type: 'text', text: response.innerString ?? 'OK' }],
        })
      } catch (error) {
        reject(error)
      }
    }
  },

  *serve(_self) {
    serveMCP(mcpServer)
  }
}

export { mcp }
