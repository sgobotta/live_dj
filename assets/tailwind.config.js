// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex"
  ],
  darkMode: 'class',
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({addVariant}) => addVariant(
      "phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])
    ),
    plugin(({addVariant}) => addVariant(
      "phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])
    ),
    plugin(({addVariant}) => addVariant(
      "phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])
    ),
    plugin(({addVariant}) => addVariant(
      "phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])
    ),
    plugin(({addVariant}) => addVariant(
      "drag-item", [".drag-item&", ".drag-item &"])
    ),
    plugin(({addVariant}) => addVariant(
      "drag-ghost", [".drag-ghost&", ".drag-ghost &"])
    ),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function({matchComponents, theme}) {
      const iconsDir = path.join(__dirname, "./vendor/heroicons/optimized")
      const values = {}
      const icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"]
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).map(file => {
          const name = path.basename(file, ".svg") + suffix
          values[name] = {fullPath: path.join(iconsDir, dir, file), name}
        })
      })
      matchComponents({
        "hero": ({name, fullPath}) => {
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
      }, {values})
    })
  ],
  safelist: [
    {
      pattern: /(dark)/
    }
  ],
  theme: {
    extend: {
      colors: {
        brand: "#FD4F00"
      }
    }
  }
}
