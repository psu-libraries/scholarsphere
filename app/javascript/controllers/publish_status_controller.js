import { Controller } from 'stimulus'
import consumer from '../channels/consumer'

export default class extends Controller {
  static targets = ['show_buttons', 'help_text'];

  connect () {
    this.data.set('versionAllowed', 'true')

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
    this.data.set('accessibilityAllowed', data.allow_publish)
    this.renderPublishStatus()
  }

  renderPublishStatus () {
    const primaryAction = this.data.get('primaryAction')

    const accessibilityAllowed = this.data.get('accessibilityAllowed') === 'true'
    const versionAllowed = this.data.get('versionAllowed') === 'true'

    const allowPublish = accessibilityAllowed && versionAllowed
    const show = allowPublish || primaryAction === 'save_and_continue'

    this.show_buttonsTarget.classList.toggle('d-none', !show)
    this.help_textTarget.classList.toggle('d-none', show)

     if (!show) {
      const blockReason = !accessibilityAllowed ? 'accessibility' : 'version'

      this.help_textTarget.textContent =
        blockReason === 'version'
          ? this.data.get('versionMessage')
          : this.data.get('accessibilityMessage')
    }
  }
}
