import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "productSelect", "quantityInput", "tableBody", "itemTemplate",
    "subtotalInput", "discountInput", "totalInput", "debtInput",
    "customerSection", "customerRequired", "customerSelect"
  ]

  connect() {
    // Estado inicial: Efectivo seleccionado, no A Crédito
    this.setCustomerRequired(false)
  }

  // ── Agregar / quitar productos ────────────────────────────

  add(e) {
    e.preventDefault()
    const select = this.productSelectTarget
    const option = select.options[select.selectedIndex]
    if (!option.value) return

    const id    = option.value
    const name  = option.dataset.name
    const price = parseFloat(option.dataset.price) || 0
    const qty   = parseFloat(this.quantityInputTarget.value) || 0
    const rowId = new Date().getTime()
    const subtotalRow = price * qty

    const fragment = this.itemTemplateTarget.content.cloneNode(true)
    const row = fragment.querySelector("tr")

    row.innerHTML = row.innerHTML.replace(/NEW_ID/g, rowId)

    row.querySelector('[data-label="name"]').textContent = name
    row.querySelector('[data-label="productId"]').value  = id
    row.querySelector('[data-label="unitPrice"]').value  = price
    row.querySelector('[data-label="quantity"]').value   = qty
    row.querySelector('[data-label="price"]').textContent = `$${price.toFixed(2)}`

    const subtotalEl = row.querySelector('[data-label="subtotal"]')
    subtotalEl.setAttribute("data-row-total", subtotalRow.toFixed(2))
    subtotalEl.textContent = `$${subtotalRow.toFixed(2)}`

    this.tableBodyTarget.appendChild(fragment)
    select.value = ""
    this.quantityInputTarget.value = 1

    this.calculateTotals()
  }

  remove(e) {
    e.preventDefault()
    e.target.closest("tr").remove()
    this.calculateTotals()
  }

  // ── Cálculos ──────────────────────────────────────────────

  calculateTotals() {
    let subtotal = 0
    this.tableBodyTarget.querySelectorAll("[data-row-total]").forEach((el) => {
      subtotal += parseFloat(el.getAttribute("data-row-total")) || 0
    })

    const discount = parseFloat(this.discountInputTarget.value) || 0
    const total    = Math.max(subtotal - discount, 0)

    this.subtotalInputTarget.value = subtotal.toFixed(2)

    if (this.totalInputTarget.readOnly) {
      this.totalInputTarget.value = total.toFixed(2)
    }

    this.calculateDebt()
  }

  calculateDebt() {
    const subtotal      = parseFloat(this.subtotalInputTarget.value) || 0
    const discount      = parseFloat(this.discountInputTarget.value) || 0
    const montoRecibido = parseFloat(this.totalInputTarget.value) || 0
    const deuda         = Math.max(subtotal - discount - montoRecibido, 0)

    this.debtInputTarget.value = deuda.toFixed(2)
  }

  // ── Método de pago (Efectivo / Transferencia) ─────────────
  // Solo actualiza cálculos; el monto recibido ya fue definido
  // por toggleCredit.
  togglePaymentMode() {
    this.calculateTotals()
  }

  // ── Toggle A Crédito ──────────────────────────────────────

  toggleCredit(e) {
    const isCredit = e.target.checked

    if (isCredit) {
      // A Crédito: monto recibido editable, empieza en 0
      this.totalInputTarget.readOnly = false
      this.totalInputTarget.classList.remove("bg-stone-50")
      this.totalInputTarget.classList.add("bg-white", "border-amber-400", "ring-1", "ring-amber-400")
      this.totalInputTarget.value = "0.00"
      this.calculateDebt()
    } else {
      // Sin crédito: monto recibido bloqueado = total a pagar
      this.totalInputTarget.readOnly = true
      this.totalInputTarget.classList.add("bg-stone-50")
      this.totalInputTarget.classList.remove("bg-white", "border-amber-400", "ring-1", "ring-amber-400")
      this.calculateTotals()
    }

    this.setCustomerRequired(isCredit)
  }

  // ── Cliente requerido ─────────────────────────────────────

  setCustomerRequired(required) {
    if (this.hasCustomerRequiredTarget) {
      this.customerRequiredTarget.classList.toggle("hidden", !required)
    }
    if (this.hasCustomerSectionTarget) {
      this.customerSectionTarget.classList.toggle("ring-2",         required)
      this.customerSectionTarget.classList.toggle("ring-amber-400", required)
    }
    if (this.hasCustomerSelectTarget) {
      this.customerSelectTarget.required = required
    }
  }
}
