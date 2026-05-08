import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.showModal()
    this.element.addEventListener("click", this.#handleBackdropClick.bind(this))
  }

  close() {
    this.element.close()
    this.element.closest("turbo-frame").innerHTML = ""
  }

  #handleBackdropClick(e) {
    if (e.target === this.element) this.close()
  }
}
