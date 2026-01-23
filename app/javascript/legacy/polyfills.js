/* eslint-disable no-extend-native, func-names */
if (!String.prototype.includes) {
  String.prototype.includes = function includes(search, start) {
    const offset = typeof start === "number" ? start : 0

    if (offset + search.length > this.length) {
      return false
    }

    return this.indexOf(search, offset) !== -1
  }
}

if (!Array.prototype.includes) {
  Object.defineProperty(Array.prototype, "includes", {
    value: function includes(searchElement, fromIndex) {
      if (this == null) {
        throw new TypeError("\"this\" is null or not defined")
      }

      const arrayLike = Object(this)
      const len = arrayLike.length >>> 0

      if (len === 0) {
        return false
      }

      const n = fromIndex | 0
      let k = Math.max(n >= 0 ? n : len - Math.abs(n), 0)

      const sameValueZero = (x, y) => x === y || (
        typeof x === "number"
        && typeof y === "number"
        && Number.isNaN(x)
        && Number.isNaN(y)
      )

      while (k < len) {
        if (sameValueZero(arrayLike[k], searchElement)) {
          return true
        }
        k += 1
      }

      return false
    },
  })
}
