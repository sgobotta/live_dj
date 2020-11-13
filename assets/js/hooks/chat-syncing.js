const ChatSyncing = () => ({
  mounted() {

    const chat = document.getElementById('chat')
    chat.scrollTop = chat.scrollHeight

    const input = document.getElementById('submit_message')

    input.onmouseenter = () => {
      input.focus()
    }

    this.handleEvent('receive_new_message', () => {
      chat.scrollTop = chat.scrollHeight
    })
  }
})

export default ChatSyncing
