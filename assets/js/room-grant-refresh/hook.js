// Silently refreshes the room authorization cookie after a password change.
//
// The server pushes a "refresh_room_grant" event carrying a short-lived,
// single-use grant URL. Fetching it (same-origin, so the session cookie is
// sent and any Set-Cookie is applied) rewrites the browser's authorization
// with the room's new password fingerprint, so a reload keeps access instead
// of bouncing the visitor to the unlock challenge.
export default {
  mounted() {
    this.handleEvent("refresh_room_grant", ({ url }) => {
      fetch(url, { credentials: "same-origin", method: "GET" }).catch(() => {})
    })
  }
}
