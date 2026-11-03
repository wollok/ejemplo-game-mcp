import { mkdirSync, writeFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const pngSignature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])
const projectDirectory = fileURLToPath(new URL('../..', import.meta.url))

const pngGenerator = {
  *generate(_self, wEncodedText) {
    const encodedText = wEncodedText.innerString
    if (!/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(encodedText)) {
      throw new Error('The encoded PNG must be valid base64')
    }

    const png = Buffer.from(encodedText, 'base64')
    if (png.length < pngSignature.length || !png.subarray(0, pngSignature.length).equals(pngSignature)) {
      throw new Error('The encoded data does not contain a PNG image')
    }

    const exportDirectory = resolve(projectDirectory, 'export')
    mkdirSync(exportDirectory, { recursive: true })
    writeFileSync(resolve(exportDirectory, Date.now().toString() + '.png'), png)
  },
}

export { pngGenerator }
