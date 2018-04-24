_ = require('wegweg')({
  globals: true
})

conf = require './../conf'
logger = require './logger'

cheerio = require 'cheerio'

module.exports = poetrade = {
  API_KEY: conf.POETRADE_URL.split('/').pop()
}

poetrade.bump = ((arr,cb) ->
  opt = {
    cookies: {
      league: conf.POETRADE_LEAGUE
      apikey: @API_KEY
    }
  }

  await _.get "http://currency.poe.trade/shop?league=#{conf.POETRADE_LEAGUE}", opt, defer e,r
  if e then return cb e

  packet = "league=#{conf.POETRADE_LEAGUE}&apikey=#{@API_KEY}"

  for position in arr

    if !position.OFFCURRENCY
      if !conf.SELL_ONLY_MODE
        log.info 'Appending buy position to bump', "CHAOS:#{position.name}"

        [left,right] = position.suggested_chaos_fraction.fraction.split '/'
        packet += """
          &sell_currency=Chaos+Orb&sell_value=#{right}&buy_value=#{left}&buy_currency=#{escape position.label}
        """

      log.info 'Appending sell position to bump', "#{position.name}:CHAOS"

      [left,right] = position.suggested_sell_fraction.fraction.split '/'
      packet += """
        &sell_currency=#{escape position.label}&sell_value=#{left}&buy_value=#{right}&buy_currency=Chaos+Orb
      """

    else if position.OFFCURRENCY
      log.info 'Appending offcurrency position to bump', "#{position.name}:#{position.alt_name}"

      [left,right] = position.suggested_sell_fraction.fraction.split '/'
      packet += """
        &sell_currency=#{escape position.label}&sell_value=#{right}&buy_value=#{left}&buy_currency=#{position.alt_label}
      """

  logger.info 'Submitting bump packet to poe.trade', require('querystring').parse(packet)

  await _.post "http://currency.poe.trade/shop?league=#{conf.POETRADE_LEAGUE}", packet, opt, defer e,r
  if e then return cb e

  return cb null, true
)

