import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "boolean", "addButton", "removeButton", "clauseInputs"]
  static values = { totalRows: Number, visibleRows: Number }

  connect() {
    this.syncBeginsWithOptions()
    this.syncRows()
    this.syncClauses()
  }

  select(event) {
    const count = Number(event.currentTarget.dataset.count)
    this.updateBeginsWithOption(count)
  }

  addRow(event) {
    event.preventDefault()
    if (this.visibleRowsValue >= this.totalRowsValue) return

    this.visibleRowsValue += 1
    this.syncRows()
    this.syncClauses()
  }

  removeRow(event) {
    event.preventDefault()
    if (this.visibleRowsValue <= 1) return

    this.clearRow(this.visibleRowsValue)
    this.visibleRowsValue -= 1
    this.syncRows()
    this.syncClauses()
  }

  syncClauses() {
    if (!this.hasClauseInputsTarget) return

    this.clauseInputsTarget.innerHTML = ""

    this.visibleClauseRows().forEach((row, index) => {
      const rowNumber = Number(row.dataset.rowIndex)
      const field = this.valueForRow(rowNumber, `#f_${rowNumber}`)
      const query = this.valueForRow(rowNumber, `#q_${rowNumber}`)
      const match = this.valueForRow(rowNumber, `#operator_q_${rowNumber}`)

      if (!query) return

      this.appendHiddenClauseInput(index, "field", field)
      this.appendHiddenClauseInput(index, "query", query)
      this.appendHiddenClauseInput(index, "match", match)

      if (index > 0) {
        this.appendHiddenClauseInput(index, "op", this.booleanOperatorForRow(rowNumber))
      }
    })
  }

  syncRows() {
    this.rowTargets.forEach((row, index) => {
      const visible = index < this.visibleRowsValue
      row.classList.toggle("d-none", !visible)
      this.toggleInputs(row, !visible)
    })

    this.booleanTargets.forEach((booleanGroup, index) => {
      const visible = index < this.visibleRowsValue - 1
      booleanGroup.classList.toggle("d-none", !visible)
      this.toggleInputs(booleanGroup, !visible)
    })

    if (this.hasAddButtonTarget) {
      this.addButtonTarget.disabled = this.visibleRowsValue >= this.totalRowsValue
    }

    if (this.hasRemoveButtonTarget) {
      this.removeButtonTarget.disabled = this.visibleRowsValue <= 1
    }

    this.syncBeginsWithOptions()
    this.syncClauses()
  }

  syncBeginsWithOptions() {
    this.rowTargets.forEach((_, index) => {
      this.updateBeginsWithOption(index + 1)
    })
  }

  updateBeginsWithOption(count) {
    const searchField = document.getElementById(`f_${count}`)
    const operatorSelect = document.getElementById(`operator_q_${count}`)

    if (!searchField || !operatorSelect) return

    const selectedOption = searchField.options[searchField.selectedIndex]
    const optionText = selectedOption ? selectedOption.text : ""
    const beginsWithOption = operatorSelect.querySelector("option[value='begins_with']")
    const beginsWithOptions = ["Title", "Author/creator/contributor", "Subject", "Publisher", "Call Number", "Series Title"]

    if (!beginsWithOption) return

    if (beginsWithOptions.includes(optionText)) {
      beginsWithOption.text = "begins with"
      beginsWithOption.hidden = false
      beginsWithOption.disabled = false
    } else {
      if (operatorSelect.value === "begins_with") {
        operatorSelect.value = "contains"
      }

      beginsWithOption.text = ""
      beginsWithOption.hidden = true
      beginsWithOption.disabled = true
    }
  }

  clearRow(count) {
    const row = this.rowTargets[count - 1]
    if (row) {
      row.querySelectorAll("input[type='text']").forEach((input) => {
        input.value = ""
      })

      row.querySelectorAll("select").forEach((select) => {
        select.selectedIndex = 0
      })
    }

    const booleanGroup = this.booleanTargets[count - 2]
    if (booleanGroup) {
      const andOption = booleanGroup.querySelector("input[value='AND']")
      if (andOption) {
        andOption.checked = true
      }
    }

    this.updateBeginsWithOption(count)
  }

  visibleClauseRows() {
    return this.rowTargets.filter((row) => !row.classList.contains("d-none"))
  }

  valueForRow(rowNumber, selector) {
    const row = this.rowTargets[rowNumber - 1]
    return row?.querySelector(selector)?.value || ""
  }

  booleanOperatorForRow(rowNumber) {
    const booleanGroup = this.booleanTargets[rowNumber - 2]
    const checked = booleanGroup?.querySelector("input[type='radio']:checked")

    switch (checked?.value) {
      case "OR":
        return "should"
      case "NOT":
        return "must_not"
      default:
        return "must"
    }
  }

  appendHiddenClauseInput(index, key, value) {
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = `clause[${index}][${key}]`
    input.value = value
    this.clauseInputsTarget.appendChild(input)
  }

  toggleInputs(container, disabled) {
    container.querySelectorAll("input, select, textarea").forEach((element) => {
      element.disabled = disabled
    })
  }
}
