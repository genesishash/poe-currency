_ = require('wegweg')({
  globals: true
})

conf = require './../conf'
logger = require './logger'

module.exports = poetrade = {
  API_KEY: conf.POETRADE_URL.split('/').pop()
}

poetrade.bump = ((arr,cb) ->
  logger.info 'Bumping poe.trade shop settings', arr.length

  opt = {
    cookies: {
      league: conf.POETRADE_LEAGUE
      apikey: @API_KEY
    }
  }

  await _.get "http://currency.poe.trade/shop?league=#{conf.POETRADE_LEAGUE}", opt, defer e,r
  if e then return cb e

  log r.body

  return cb null, true
)

