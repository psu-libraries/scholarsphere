import { Controller } from "stimulus"

export default class extends Controller {
  show(event) {
    event.preventDefault()

    const showAlert = this.data.get("showAlert") === "true"

    if (showAlert) {
      const modalEl = document.getElementById('remediationPopup')
      
      modalEl.showModal()

      modalEl.querySelector("#modalOkBtn").addEventListener("click", () => {
        modalEl.close()
        window.location.href = this.element.href
      }, { once: true })

      modalEl.addEventListener("hidden.bs.modal", () => modalEl.remove())
    } else {
      window.location.href = this.element.href
    }
  }
}
