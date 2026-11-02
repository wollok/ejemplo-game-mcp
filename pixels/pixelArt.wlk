import wollok.game.*

object pixelArt {
  method newPixelIn(position) {
    game.addVisual(new Pixel(position = position))
  }
  
  method createCanvas() {
    (0 .. (game.width() - 1)).forEach(
      { x => (0 .. (game.height() - 1)).forEach(
          { y => game.addVisual(new Pixel(position = game.at(x, y))) }
        ) }
    )
  }
}

class Pixel {
  const property position
  var activated = true
  
  method image() = if (activated) "black.png" else "white.png"
  
  method toogle() {
    activated = not activated
  }
}
