import { Controller } from 'stimulus'
import FormUpdater from './open_access_version/form_updater'
import { createOpenAccessVersionSubscription, safeUnsubscribe, unsubscribe } from './open_access_version/subscription'
import VersionLoader from './open_access_version/version_loader'

export default class extends Controller {
  static targets = ['versionMessage', 'fieldUpdates', 'loading', 'controls']

  connect() {
    this.formUpdater = new FormUpdater({
      data: this.data,
      versionMessageTarget: this.versionMessageTarget,
      fieldUpdatesTarget: this.hasFieldUpdatesTarget ? this.fieldUpdatesTarget : null,
      onVersionAllowed: (versionAllowed) => {
        document.dispatchEvent(new CustomEvent('open-access:version-updated', {
          detail: { versionAllowed }
        }))
      }
    })

    const selectedVersion = this.element.querySelector('input[name="work_version[open_access_version]"]:checked')

    if (selectedVersion) {
      this.refresh({ target: selectedVersion })
    }

    const id = this.data.get('id')

    if (id) {
      this.subscription = createOpenAccessVersionSubscription({
        id,
        onVersionReceived: (openAccessVersion) => this.#applyOpenAccessVersion(openAccessVersion)
      })
      this.versionLoader = new VersionLoader({
        onVersionReceived: (openAccessVersion) => this.#applyOpenAccessVersion(openAccessVersion),
        onLoadingTimedOut: () => this.#handleLoadingTimeout(),
        onFinished: () => safeUnsubscribe(this.subscription)
      })
      this.versionLoader.load(id)
      this.versionLoader.start(id)
    }
  }

  disconnect() {
    if (this.versionLoader) this.versionLoader.stop()
    if (this.formUpdater) this.formUpdater.disconnect()
    unsubscribe(this.subscription)
  }

  refresh(event) {
    this.formUpdater.refresh(event.target.value)
  }

  #applyOpenAccessVersion(open_access_version) {
    if (!open_access_version) return
    const radio = this.element.querySelector(
      `input[name="work_version[open_access_version]"][value="${open_access_version}"]`
    )
    if (radio) {
      radio.checked = true
      this.refresh({ target: radio })
      if (this.hasLoadingTarget) this.loadingTarget.classList.add('d-none')
      if (this.hasControlsTarget) this.controlsTarget.classList.remove('d-none')
    }
  }

  #handleLoadingTimeout() {
    const spinnerVisible = this.hasLoadingTarget && !this.loadingTarget.classList.contains('d-none')
    const controlsHidden = this.hasControlsTarget && this.controlsTarget.classList.contains('d-none')

    if (!spinnerVisible || !controlsHidden) return false

    if (this.hasControlsTarget) this.controlsTarget.classList.remove('d-none')
    if (this.hasLoadingTarget) this.loadingTarget.classList.add('d-none')

    return true
  }
}