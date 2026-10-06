// jsdom doesn't implement window.CSS, which assets/js/keyboard/grid.js
// (and the existing assets/js/playlist/hook.js) rely on via CSS.escape.
// Minimal polyfill, sufficient for the identifier-like values this app
// ever passes to it.
if (typeof window !== 'undefined' && !window.CSS) {
  window.CSS = {
    escape: (value) => String(value).replace(/([^a-zA-Z0-9_-])/g, '\\$1')
  }
}

// jsdom doesn't implement scrollIntoView either.
if (typeof Element !== 'undefined' && !Element.prototype.scrollIntoView) {
  Element.prototype.scrollIntoView = () => {}
}
