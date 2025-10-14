import { Controller } from "stimulus"

export default class extends Controller {
  show(event) {
    event.preventDefault()

    const showAlert = this.data.get("showAlert") === "true"

    if (showAlert) {
      const modalEl = document.getElementById('remediationPopup')
      const modal = new window.bootstrap.Modal(modalEl)

      modal.show()

      modalEl.querySelector("#modalOkBtn").addEventListener("click", () => {
        modal.hide()
        window.location.href = this.element.href
      }, { once: true })

      modalEl.addEventListener("hidden.bs.modal", () => modalEl.remove())
    } else {
      window.location.href = this.element.href
    }
  }
}
