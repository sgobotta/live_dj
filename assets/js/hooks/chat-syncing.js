const ChatSyncing = () => ({
  mounted() {

    const chat = document.getElementById('chat')
    chat.scrollTop = chat.scrollHeight

    this.handleEvent('receive_new_message', () => {
      chat.scrollTop = chat.scrollHeight
    })
  }
})

export default ChatSyncing
