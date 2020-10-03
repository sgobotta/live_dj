import Player from './player'

export default {
  init(playerContainer, videoId, done) {
    Player.init(playerContainer, videoId, (player) => {
      done(player)
    })
  }
}
