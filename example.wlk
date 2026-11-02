object wko {
  var property position = game.center()
  const property image = "wko.png"
  
  method up() {
    position = position.up(1)
  }
  
  method down() {
    position = position.down(1)
  }
  
  method left() {
    position = position.left(1)
  }
  
  method right() {
    position = position.right(1)
  }
}

object mcp {
  method flush() native
  
  method x() = wko.position().x()
  method y() = wko.position().y()

  method up() {
    wko.up()
  }
  
  method down() {
    wko.down()
  }
  
  method left() {
    wko.left()
  }
  
  method right() {
    wko.right()
  }
}