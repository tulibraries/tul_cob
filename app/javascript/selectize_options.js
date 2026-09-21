const selectizeOptions = {
  onItemAdd() {
    this.setActiveItem(null)
    this.showInput()
    this.setCaret(this.items.length)
    this.focus()
  },

  onInitialize() {
    const selectize = this

    this.$control_input.on("keydown", (event) => {
      if ((event.key !== "Delete" && event.keyCode !== 46) || event.isDefaultPrevented() || event.target.value) return

      const index = Math.min(selectize.caretPos, selectize.items.length - 1)
      const value = selectize.items[index]
      if (!value) return

      event.preventDefault()
      selectize.removeItem(value)
      selectize.setCaret(index)
    })
  }
}

export default selectizeOptions
