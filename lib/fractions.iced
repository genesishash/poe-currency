_ = require('wegweg')({
  globals: on
})

obj = {}

for x in [1..100]
  for y in [1..100]
    obj["#{x}/#{y}"] = parseFloat(x/y).toFixed(3)
    obj["#{y}/#{x}"] = parseFloat(y/x).toFixed(3)

arr = []

for k,v of obj
  arr.push {fraction:k,value:+v}

arr = _.sortBy arr, (x) -> x.fraction.length

fractions = {
  list: arr
  find_closest: ((value) ->
    value = (+value)

    has_zero = false

    list = _.map @list, (fraction) ->
      biggest = value
      smallest = fraction.value

      if value < fraction.value
        biggest = fraction.value
        smallest = value

      fraction.diff = biggest - smallest

      if fraction.diff is 0
        has_zero = true

      return fraction

    list = _.sortBy list, (x) -> x.diff

    if has_zero
      list = _.cmap list, (x) ->
        if x.diff then return null
        return x

    return list.shift()
  )
}

module.exports = fractions

##
if !module.parent
  log /DEVEL/
  log fractions.find_closest(0.659493)
  process.exit 0

