export default {
  mounted() {
    this.el.addEventListener("click", () => {
      const text = this.el.dataset.copyText
      navigator.clipboard.writeText(text).then(() => {
        const original = this.el.innerText
        this.el.innerText = "Copied!"
        setTimeout(() => { this.el.innerText = original }, 2000)
      })
    })
  }
}
