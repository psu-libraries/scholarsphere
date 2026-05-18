import { Controller } from 'stimulus'
import consumer from '../channels/consumer'

export default class extends Controller {
  static targets = ['show_buttons', 'help_text'];

connect () {
  document.addEventListener('open-access:version-updated', this.handleVersionUpdate)

  consumer.subscriptions.create(
    { channel: 'PublishStatusChannel' },
    {
      connected: () => {
        this.renderPublishStatus()
      },
      received: (data) => {
        this.updatePublishStatus(data)
      }
    }
  )
}

  updatePublishStatus (data) {
    this.data.set('allowPublish', data.allow_publish)

    this.renderPublishStatus()
  }

  renderPublishStatus () {
    const primaryAction = this.data.get('primaryAction')
    const allowPublish = this.data.get('allowPublish') === 'true'
    const versionAllowed = this.data.get('versionAllowed') || 'true'
    const versionAllowsPublish = versionAllowed === 'true'
    const show = (allowPublish && versionAllowsPublish) || primaryAction === 'save_and_continue'
    this.show_buttonsTarget.classList.toggle('d-none', !show)
    this.help_textTarget.classList.toggle('d-none', show)
     if (!show) {
      const blockReason = !allowPublish ? 'accessibility' : 'version'
      this.help_textTarget.textContent =
        blockReason === 'version'
          ? this.data.get('versionMessage')
          : this.data.get('accessibilityMessage')
    }
  }

  disconnect() {
  document.removeEventListener('open-access:version-updated', this.handleVersionUpdate)
}

handleVersionUpdate = (event) => {
  this.data.set('versionAllowed', event.detail.versionAllowed)
  this.renderPublishStatus()
}
}
