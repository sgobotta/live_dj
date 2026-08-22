import multiavatar from "@multiavatar/multiavatar"

function render(el) {
  const seed = el.dataset.seed
  if (!seed) return

  el.innerHTML = multiavatar(seed)

  const svg = el.querySelector("svg")
  if (svg) {
    svg.removeAttribute("width")
    svg.removeAttribute("height")
    svg.setAttribute("class", "h-full w-full")
  }
}

export default {
  mounted() {
    render(this.el)
  },
  updated() {
    render(this.el)
  }
}
