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

if conf.SKIP_CURRENCIES.length
  logger.warn 'Skipping currencies (config)', conf.SKIP_CURRENCIES.length

  currencies.list = (_.cmap currencies.list, (item) ->
    if item.name in conf.SKIP_CURRENCIES then return null
    return item
  )

for item in currencies.list
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

if conf.OFFCURRENCY_TRADES_ENABLED
  logger.info "Building offcurrency market positions"

  for item in _.clone(positions)
    for alt in _.clone(currencies.list)

      clone = _.clone(item)
      continue if alt.name is clone.name

      clone.OFFCURRENCY = true
      clone.alt_name = alt.name
      clone.alt_label = alt.label
      clone.alt_market_price = alt.market_price

      try delete clone.suggested_chaos_price
      try delete clone.suggested_chaos_fraction
      try delete clone.suggested_chaos_tag

      clone.market_price = (alt.market_price/clone.market_price).toFixed(3)

      clone.suggested_sell_price = (do =>
        v = +clone.market_price
        perc = (v * (conf.OFFCURRENCY_MARGIN_PERCENT/100))
        v += perc
        return v.toFixed(3)
      )

      clone.suggested_sell_fraction = fractions.find_closest(clone.suggested_sell_price)
      clone.suggested_sell_tag = """
        ~b/o #{clone.suggested_sell_fraction.fraction} #{alt.name.toLowerCase()}
      """

      positions.push(clone)
else
  logger.warn 'Offcurrency trading is disabled (config)'

logger.info "Bumping positions on poe.trade", positions.length, conf.POETRADE_URL, conf.POETRADE_LEAGUE

await poetrade.bump positions, defer e
if e then throw e

logger.info "Finished routine successfully, exiting", {
  elapsed_seconds: Math.round((new Date - start)/1000)
}

exit 0

