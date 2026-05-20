import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["itemsContainer", "row", "quantity", "unitCost", "rowSubtotal", "total"]

  connect() {
    this.rowIndex = this.rowTargets.length
    this.recalculate()
  }

  addRow() {
    const template = document.getElementById("purchase-item-template")
    const clone = template.content.cloneNode(true)
    const tr = clone.querySelector("tr")
    tr.innerHTML = tr.innerHTML.replaceAll("REPLACE_INDEX", this.rowIndex++)
    this.itemsContainerTarget.appendChild(tr)
    this.recalculate()
  }

  removeRow(event) {
    event.currentTarget.closest("tr").remove()
    this.recalculate()
  }

  recalculate() {
    let grandTotal = 0
    this.rowTargets.forEach(row => {
      const qty = parseFloat(row.querySelector("[data-purchase-form-target='quantity']")?.value) || 0
      const cost = parseFloat(row.querySelector("[data-purchase-form-target='unitCost']")?.value) || 0
      const subtotal = qty * cost
      grandTotal += subtotal
      const subtotalEl = row.querySelector("[data-purchase-form-target='rowSubtotal']")
      if (subtotalEl) subtotalEl.textContent = "$" + subtotal.toFixed(2)
    })
    if (this.hasTotalTarget) {
      this.totalTarget.textContent = "$" + grandTotal.toFixed(2)
    }
  }
}
