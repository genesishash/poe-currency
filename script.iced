_ = require('wegweg')({
  globals: on
})

conf = require './conf'
logger = require './lib/logger'

poetrade = require './lib/poetrade'
fractions = require './lib/fractions'
currencies = require './lib/currencies'

logger.info "Script loaded", (start = new Date), conf
logger.info "Fetching prices for all currencies", currencies.list.length

positions = []

for item in currencies.list
  if item.name in conf.SKIP_CURRENCIES
    log.warn "Skipping currency #{item.name} (config)"
    continue

  logger.info "Calculating market position for currency #{item.name}"

  await currencies.get_price item.code, defer e,price

  item.market_price = (price.toFixed(3))

  item.suggested_sell_price = (do =>
    v = +item.market_price
    perc = (v * (conf.SELL_PRICE_MARGIN_PERCENT/100))
    v -= perc
    return v.toFixed(3)
  )

  item.suggested_sell_fraction = fractions.find_closest(item.suggested_sell_price)
  item.suggested_sell_tag = """
    ~b/o #{item.suggested_sell_fraction.fraction} chaos
  """

  item.suggested_chaos_price = (do =>
    v = +item.market_price
    perc = (v * (conf.BUY_PRICE_MARGIN_PERCENT/100))
    v += perc
    return v.toFixed(3)
  )

  item.suggested_chaos_fraction = fractions.find_closest(item.suggested_chaos_price)
  item.suggested_chaos_tag = """
    ~b/o #{item.suggested_chaos_fraction.fraction} #{item.name.toLowerCase()}
  """

  positions.push(item)

logger.info "Finished calculating initial market positions", positions.length

# @todo: append offcurrency position permutations

logger.info "Bumping positions on poe.trade", positions.length, conf.POETRADE_URL, conf.POETRADE_LEAGUE

await poetrade.bump positions, defer e
if e then throw e

logger.info "Finished routine successfully, exiting", {
  elapsed_seconds: Math.round((new Date - start)/1000)
}

exit 0

