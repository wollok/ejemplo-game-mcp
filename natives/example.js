import { pendingMoves, position } from '../mcp-server.js'

const mcp = {
  *flush(_self) {
    const wx = yield* this.send('x', _self)
    const wy = yield* this.send('y', _self)
    position.x = wx.innerNumber
    position.y = wy.innerNumber
    

    for (const move of pendingMoves)
      yield* this.send(move, _self)

    pendingMoves.length = 0
  },
}

export { mcp }