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