const tomSelectOptions = {
  plugins: ["caret_position", "input_autogrow"],
  maxOptions: 1000,
  hidePlaceholder: true,

  onItemAdd() {
    this.setActiveItem(null)
    this.setCaret(this.items.length)
    this.focus()
    this.inputState()
  },

  onInitialize() {
    this.control_input.addEventListener("keydown", (event) => {
      if (event.key !== "Delete" || event.defaultPrevented || event.target.value) return

      const index = Math.min(this.caretPos, this.items.length - 1)
      const value = this.items[index]
      if (!value) return

      event.preventDefault()
      this.removeItem(value)
      this.setCaret(index)
    })
  }
}

export default tomSelectOptions
