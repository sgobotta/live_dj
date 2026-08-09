// Persists the chat display name per room in a cookie so the server can read it
// during the initial HTTP render (via the session) and resolve the name once,
// before the first paint. The hook only writes; the server is the single source
// of truth for what gets rendered, so there is no read-back that would assign a
// default and then change it.
const COOKIE_MAX_AGE = 60 * 60 * 24 * 365

export default {
  mounted() {
    const roomId = this.el.dataset.roomId

    this.handleEvent('store_display_name', ({ name }) => {
      const value = encodeURIComponent(name)
      document.cookie =
        `livedj_display_name_${roomId}=${value}; ` +
        `path=/; max-age=${COOKIE_MAX_AGE}; samesite=lax`
    })
  }
}
