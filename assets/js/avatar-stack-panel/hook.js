import {pushScope} from '../keyboard'

// The member panel (mini_avatar_stack_component.ex) opens three ways: CSS
// :hover, CSS :focus-visible on this element (Tab into it), or a tap
// toggling the "panel-visible" class - there's no single assign or
// always-present attribute to key a scope's lifecycle off of. Rather than
// track that with a MutationObserver, just check the live DOM at the
// moment Escape is pressed: are we focused inside the stack, or is the
// panel currently tap-toggled open. Declining (returning false) otherwise
// lets Escape fall through to whatever's below - most days, nothing.
function isOpen(hook, panel) {
  return hook.el.contains(document.activeElement) ||
    Boolean(panel?.classList.contains('panel-visible'))
}

export default {
  destroyed() {
    this.detach?.()
  },

  mounted() {
    const panel = document.getElementById(`${this.el.id}-panel`)

    this.detach = pushScope({
      bindings: {
        escape: () => {
          if (!isOpen(this, panel)) return false
          panel?.classList.remove('panel-visible')
          this.el.blur()
        }
      },
      id: `avatar-stack-panel-${this.el.id}`
    })
  }
}
