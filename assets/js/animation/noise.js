const W = 160
const H = 90

// r/g/b offsets applied to a base grayscale value (80–155), clamped to 0–255
export const PALETTES = [
  { b: 0,   g: 0,   r: 0   }, // grayscale
  { b: -60, g: 25,  r: 70  }, // warm amber
  { b: 80,  g: 10,  r: -60 }  // cool blue
]

function clamp(v) { return v < 0 ? 0 : v > 255 ? 255 : v }

export function startNoise(canvas, palette = PALETTES[0]) {
  const ctx = canvas.getContext('2d')
  canvas.width = W
  canvas.height = H
  const imageData = ctx.createImageData(W, H)
  const data = imageData.data
  const { b, g, r } = palette

  function drawFrame() {
    for (let i = 0; i < data.length; i += 4) {
      const v = 80 + ((Math.random() * 75) | 0)
      data[i]     = clamp(v + r)
      data[i + 1] = clamp(v + g)
      data[i + 2] = clamp(v + b)
      data[i + 3] = 255
    }
    ctx.putImageData(imageData, 0, 0)
    canvas._noiseRaf = requestAnimationFrame(drawFrame)
  }

  drawFrame()
}

export function stopNoise(canvas) {
  cancelAnimationFrame(canvas._noiseRaf)
  canvas._noiseRaf = null
  const ctx = canvas.getContext('2d')
  ctx.clearRect(0, 0, canvas.width, canvas.height)
}
