import wollok.game.*

object pixelArt {
  const property pixels = []
  const property base64Alphabet = [
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
    "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
    "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "+", "/"
  ]

  method newPixelIn(position) {
    const pixel = new Pixel(position = position)
    pixels.add(pixel)
    game.addVisual(pixel)
  }

  method encode() {
    const scanlines = []

    (0 .. (game.height() - 1)).forEach({ y =>
      scanlines.add(0)
      (0 .. (game.width() - 1)).forEach({ x =>
        self.addPixelBytes(scanlines, game.at(x, y))
      })
    })

    const png = [137, 80, 78, 71, 13, 10, 26, 10]
    const header = []
    self.appendBigEndian32(header, game.width())
    self.appendBigEndian32(header, game.height())
    header.add(8)
    header.add(6)
    header.add(0)
    header.add(0)
    header.add(0)
    self.appendChunk(png, [73, 72, 68, 82], header)

    const compressed = self.compress(scanlines)
    self.appendChunk(png, [73, 68, 65, 84], compressed)
    self.appendChunk(png, [73, 69, 78, 68], [])

    return self.encodeBytes(png)
  }

  method addPixelBytes(bytes, position) {
    var alpha = 0
    var color = 0
    pixels.forEach({ pixel =>
      if (pixel.position() == position) {
        alpha = 255
        if (pixel.code() == 2) color = 0 else color = 255
      }
    })
    bytes.add(color)
    bytes.add(color)
    bytes.add(color)
    bytes.add(alpha)
  }

  method compress(scanlines) {
    const compressed = [120, 1]
    const blockSize = 65535
    const blockCount = ((scanlines.size() + blockSize - 1) / blockSize).truncate(0)

    (0 .. (blockCount - 1)).forEach({ block =>
      const start = block * blockSize
      var length = scanlines.size() - start
      if (length > blockSize) length = blockSize
      if (block == blockCount - 1) compressed.add(1) else compressed.add(0)
      compressed.add((length % 256).truncate(0))
      compressed.add(((length - length % 256) / 256).truncate(0))
      const inverseLength = 65535 - length
      compressed.add((inverseLength % 256).truncate(0))
      compressed.add(((inverseLength - inverseLength % 256) / 256).truncate(0))
      (0 .. (length - 1)).forEach({ offset =>
        compressed.add(scanlines.get(start + offset))
      })
    })

    var firstAdler = 1
    var secondAdler = 0
    scanlines.forEach({ byte =>
      firstAdler = (firstAdler + byte) % 65521
      secondAdler = (secondAdler + firstAdler) % 65521
    })
    self.appendBigEndian32(compressed, secondAdler * 65536 + firstAdler)

    return compressed
  }

  method appendChunk(png, type, data) {
    self.appendBigEndian32(png, data.size())
    const crcData = []
    type.forEach({ byte =>
      png.add(byte)
      crcData.add(byte)
    })
    data.forEach({ byte =>
      png.add(byte)
      crcData.add(byte)
    })
    self.appendBigEndian32(png, self.crc32(crcData))
  }

  method appendBigEndian32(bytes, value) {
    bytes.add(((value - value % 16777216) / 16777216).truncate(0))
    bytes.add((((value % 16777216) - value % 65536) / 65536).truncate(0))
    bytes.add((((value % 65536) - value % 256) / 256).truncate(0))
    bytes.add((value % 256).truncate(0))
  }

  method crc32(bytes) {
    var crc = 4294967295
    var remainingByte = 0
    const polynomial = 3988292384
    bytes.forEach({ currentByte =>
      var lowByte = crc % 256
      const previousLowByte = lowByte
      var xorByte = 0
      var bitValue = 1
      remainingByte = currentByte;
      (0 .. 7).forEach({ bit =>
        if ((lowByte % 2) != (remainingByte % 2)) xorByte = xorByte + bitValue
        lowByte = (lowByte - lowByte % 2) / 2
        remainingByte = (remainingByte - remainingByte % 2) / 2
        bitValue = bitValue * 2
      })
      crc = (crc - previousLowByte) + xorByte;
      (0 .. 7).forEach({ bit =>
        if (crc % 2 == 1) {
          crc = self.xor32((crc - 1) / 2, polynomial)
        } else {
          crc = crc / 2
        }
      })
    })
    return 4294967295 - crc
  }

  method xor32(left, right) {
    var result = 0
    var placeValue = 1
    var leftBits = left
    var rightBits = right;
    (0 .. 31).forEach({ bit =>
      if ((leftBits % 2) != (rightBits % 2)) result = result + placeValue
      leftBits = (leftBits - leftBits % 2) / 2
      rightBits = (rightBits - rightBits % 2) / 2
      placeValue = placeValue * 2
    })
    return result
  }

  method encodeBytes(bytes) {
    var encoded = ""
    var groupSize = 0
    var firstByte = 0
    var secondByte = 0

    bytes.forEach({ byte =>
      if (groupSize == 0) {
        firstByte = byte
        groupSize = 1
      } else if (groupSize == 1) {
        secondByte = byte
        groupSize = 2
      } else {
        encoded = encoded
          + base64Alphabet.get(((firstByte - firstByte % 4) / 4).truncate(0))
          + base64Alphabet.get(((firstByte % 4) * 16 + (secondByte - secondByte % 16) / 16).truncate(0))
          + base64Alphabet.get(((secondByte % 16) * 4 + (byte - byte % 64) / 64).truncate(0))
          + base64Alphabet.get((byte % 64).truncate(0))
        groupSize = 0
      }
    })

    if (groupSize == 1) {
      encoded = encoded
        + base64Alphabet.get(((firstByte - firstByte % 4) / 4).truncate(0))
        + base64Alphabet.get(((firstByte % 4) * 16).truncate(0))
        + "=="
    } else if (groupSize == 2) {
      encoded = encoded
        + base64Alphabet.get(((firstByte - firstByte % 4) / 4).truncate(0))
        + base64Alphabet.get(((firstByte % 4) * 16 + (secondByte - secondByte % 16) / 16).truncate(0))
        + base64Alphabet.get(((secondByte % 16) * 4).truncate(0))
        + "="
    }

    return encoded
  }
}

class Pixel {
  const property position
  var activated = true

  method image() = if (activated) "black.png" else "white.png"

  method code() = if (activated) 2 else 1

  method toogle() {
    activated = not activated
  }
}
