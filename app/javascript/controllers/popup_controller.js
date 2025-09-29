import { Controller } from "stimulus"

export default class extends Controller {
  connect() {
    console.log("popup controller connected", this.element.dataset)
  }

  show(event) {
    event.preventDefault()

    const showAlert = this.data.get("showAlert") === "true"

    if (showAlert) {
      alert("Auto-remediation is starting — click OK to continue download")
    }

    window.location.href = this.element.href
  }
}