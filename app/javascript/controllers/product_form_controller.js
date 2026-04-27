import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["costPrice", "salePrice", "margin"]

  calculate() {
    const cost = parseFloat(this.costPriceTarget.value) || 0
    const sale = parseFloat(this.salePriceTarget.value) || 0

    if (cost <= 0 || sale <= 0) {
      this.marginTarget.textContent = "—"
      this.marginTarget.className = this.#baseClasses("stone")
      return
    }

    const margin = ((sale - cost) / cost * 100).toFixed(1)
    this.marginTarget.textContent = `${margin}%`

    if (margin >= 20) {
      this.marginTarget.className = this.#baseClasses("emerald")
    } else if (margin >= 5) {
      this.marginTarget.className = this.#baseClasses("amber")
    } else {
      this.marginTarget.className = this.#baseClasses("rose")
    }
  }

  #baseClasses(color) {
    const map = {
      stone:   "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-stone-100 text-stone-500",
      emerald: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700",
      amber:   "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-50 text-amber-700",
      rose:    "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-rose-50 text-rose-700",
    }
    return map[color]
  }
}
