import { Controller } from "@hotwired/stimulus"

  function getMetaValue(name) {
    const element = document.head.querySelector(`meta[name="${name}"]`)
    return element.getAttribute("content")
  }

export default class extends Controller {
  static targets = [ "table", "spinner"]


  initialize() {
    this.sortKey = null
    this.sortDirection = null
    if (this.hasUrl) { // for IE branch and jest testing
      this.get_loans()
    }
  }

  get_loans() {
    fetch(this.data.get("url"), {
      credentials: "same-origin",
      headers: {
        "X-CSRF-Token": getMetaValue("csrf-token")
      },
    })
      .then(response => response.text())
      .then(html => {
        $(this.spinnerTarget).remove();
        this.tableTarget.innerHTML = html
        this.applySort()
      })
  }

  connect() {
    this.updateSortIndicators()
    $('input[type=checkbox]').click(function(){
      var x = document.getElementsByName("loan_ids[]");
      var checked = false;
      $(x).each(function() {
        if( $(this).prop('checked')){
          checked = true;
        }
      });
    });
  }

  selectallchecks() {
    var x = document.getElementsByName("loan_ids[]");
    var y = document.getElementById("checkall");
    var i;
    if (y.checked == true) {
      for (i = 0; i < x.length; i++) {
        if (x[i].type == "checkbox") {
          x[i].checked = true;
        }
      }
    }
    else {
      for (i = 0; i < x.length; i++) {
        if (x[i].type == "checkbox") {
          x[i].checked = false;
        }
      }
    }
  }

  deselectallchecks() {
    var x = document.getElementsByName("loan_ids[]");
    var y = document.getElementById("checkall");
    y.checked = false;
    var i;
    for (i = 0; i < x.length; i++) {
      if (x[i].type == "checkbox") {
          x[i].checked = false;
      }
    }
  }

  toggleSort(event) {
    const button = event.currentTarget
    const key = button.dataset.sortKey

    if (this.sortKey === key) {
      this.sortDirection = this.sortDirection === "ascending" ? "descending" : "ascending"
    } else {
      this.sortKey = key
      this.sortDirection = "ascending"
    }

    this.updateSortIndicators()
    this.sortRows()
  }

  applySort() {
    this.updateSortIndicators()
    if (this.sortKey) {
      this.sortRows()
    }
  }

  updateSortIndicators() {
    const headers = this.element.querySelectorAll("th[data-loans-sort-key]")
    headers.forEach((header) => {
      const key = header.dataset.loansSortKey
      if (key === this.sortKey) {
        header.dataset.sortState = this.sortDirection
        header.setAttribute("aria-sort", this.sortDirection)
      } else {
        header.dataset.sortState = "none"
        header.setAttribute("aria-sort", "none")
      }
    })
  }

  get hasUrl() {
    return Boolean(this.data.get("url")) && this.hasTableTarget
  }

  sortRows() {
    if (!this.sortKey) return
    const rows = Array.from(this.tableTarget.querySelectorAll("tr"))
    const footerRow = rows.find((row) => row.querySelector("td.submit"))
    const sortableRows = rows.filter((row) => !row.querySelector("td.submit"))

    const keyedRows = sortableRows.map((row, index) => {
      const cell = row.querySelector(`[data-sort-key="${this.sortKey}"]`)
      const rawValue = cell ? (cell.dataset.sortValue || cell.textContent || "") : ""
      return { row, value: this.normalizeValue(rawValue), index }
    })

    keyedRows.sort((a, b) => {
      if (a.value < b.value) return this.sortDirection === "ascending" ? -1 : 1
      if (a.value > b.value) return this.sortDirection === "ascending" ? 1 : -1
      return a.index - b.index
    })

    this.tableTarget.innerHTML = ""
    keyedRows.forEach(({ row }) => this.tableTarget.appendChild(row))
    if (footerRow) this.tableTarget.appendChild(footerRow)
  }

  normalizeValue(value) {
    if (this.sortKey === "due") {
      const parsed = Date.parse(value)
      return Number.isNaN(parsed) ? 0 : parsed
    }
    return value.toString().toLowerCase()
  }
}
