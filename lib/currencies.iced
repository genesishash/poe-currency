_ = require('wegweg')({
  globals: on
})

cheerio = require 'cheerio'

conf = require './../conf'

arr = [
  null
  'ALT'
  'FUSE'
  'ALCH'
  null
  'GCP'
  null
  'CHROME'
  'JEW'
  'CHANCE'
  'CHISEL'
  'SCOUR'
  'BLESSE'
  'REGRET'
  'REGAL'
  'DIVINE'
  'VAAL'
]

currencies = []

i = 1

while 1
  cur = arr[i]

  if cur is null
    i += 1
    continue

  if !cur
    break

  currencies.push {
    name: cur
    code: i
  }

  i += 1

get_price = ((code,cb) ->
  await _.get "http://currency.poe.trade/search?league=#{conf.POETRADE_LEAGUE}&online=x&want=#{code}&have=4", defer e,r
  if e then return cb e

  $ = cheerio.load(r.body)

  prices = []

  $('#content').find('div.displayoffer').each ->
    sell_val = parseFloat($(this).data('sellvalue'))
    buy_val = parseFloat($(this).data('buyvalue'))

    prices.push(sell_val/buy_val)
    return false if prices.length > 5

  prices.shift()

  return cb null, (_.sum(prices)/prices.length)
)

module.exports = obj = {
  list: currencies
  get_price: get_price
}

