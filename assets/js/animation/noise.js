const W = 160
const H = 90

export function startNoise(canvas) {
  const ctx = canvas.getContext('2d')
  canvas.width = W
  canvas.height = H
  const imageData = ctx.createImageData(W, H)
  const data = imageData.data

  function drawFrame() {
    for (let i = 0; i < data.length; i += 4) {
      const v = 80 + ((Math.random() * 75) | 0)
      data[i] = v
      data[i + 1] = v
      data[i + 2] = v
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
