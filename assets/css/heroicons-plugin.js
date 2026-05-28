const fs = require("fs")
const path = require("path")

module.exports = function({ matchComponents, theme }) {
  const iconsDir = path.join(__dirname, "../vendor/heroicons/optimized")
  const values = {}
  const icons = [
    ["", "/24/outline"],
    ["-solid", "/24/solid"],
    ["-mini", "/20/solid"]
  ]
  icons.forEach(([suffix, dir]) => {
    fs.readdirSync(path.join(iconsDir, dir)).map(file => {
      const name = path.basename(file, ".svg") + suffix
      values[name] = { fullPath: path.join(iconsDir, dir, file), name }
    })
  })
  matchComponents({
    "hero": ({ name, fullPath }) => {
      const content = fs
        .readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
      return {
        [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
        "-webkit-mask": `var(--hero-${name})`,
        "background-color": "currentColor",
        "display": "inline-block",
        "height": theme("spacing.5"),
        "mask": `var(--hero-${name})`,
        "mask-repeat": "no-repeat",
        "vertical-align": "middle",
        "width": theme("spacing.5")
      }
    }
  }, { values })
}
