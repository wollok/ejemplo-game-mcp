import example.*

object mcp {
  method flush() native
  method serve() native
  method registerAction(description, action) native
  method registerAction(description, parameterName, parameterDescription, action) native
  
  
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