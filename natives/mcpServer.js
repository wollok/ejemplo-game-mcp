import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js'
import { z } from 'zod/v4'
import { pendingMoves, position, serveMCP } from '../server.js'

const pendingCallbacks = []
var i = 0

const mcpServer = new McpServer({
  name: 'wollok-game',
  version: '1.0.0',
})

function parseCoordinates(coordinates) {
  const match = /^(\d+)@(\d+)$/.exec(coordinates)
  if (!match) {
    throw new Error('Las coordenadas deben tener el formato x@y, por ejemplo 1@2.')
  }

  const x = Number(match[1])
  const y = Number(match[2])
  if (!Number.isSafeInteger(x) || !Number.isSafeInteger(y)) {
    throw new Error('Las coordenadas deben ser números enteros válidos.')
  }

  return [x, y]
}

const mcp = {
  *registerAction(_self, wDescription, callbackOrParameterName, wParameterDescription, parameterizedCallback) {
    const description = wDescription.innerString
    if (parameterizedCallback) {
      const parameterName = callbackOrParameterName.innerString
      const parameterDescription = wParameterDescription.innerString
      mcpServer.registerTool(
        (i++).toString(),
        {
          description,
          inputSchema: {
            [parameterName]: z.string().describe(parameterDescription),
          },
        },
        ({ [parameterName]: coordinates }) => {
          const args = parseCoordinates(coordinates)
          return new Promise((resolve, reject) => {
            pendingCallbacks.push({ callback: parameterizedCallback, args, resolve, reject })
          })
        },
      )
      return
    }

    const callback = callbackOrParameterName
    mcpServer.registerTool(
      (i++).toString(),
      { description },
      () => new Promise((resolve, reject) => {
        pendingCallbacks.push({ callback, args: [], resolve, reject })
      }),
    )
  },

  *flush(_self) {
    while (pendingCallbacks.length > 0) {
      const { callback, args, resolve, reject } = pendingCallbacks.shift()
      try {
        const wollokArgs = []
        for (const arg of args) {
          wollokArgs.push(yield* this.reify(arg))
        }
        const response = yield* this.send('apply', callback, ...wollokArgs)
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
