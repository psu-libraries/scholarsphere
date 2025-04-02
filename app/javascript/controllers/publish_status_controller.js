import { Controller } from 'stimulus'
import consumer from "../channels/consumer"

export default class extends Controller {
  static targets = ['show_buttons'];

//   updatePublishStatus(data) {
//     console.log("TESTING: PublishStatusController updatePublishStatus called");
//     const allowPublish = data.allow_publish === "true";
//     const primaryAction = data.primary_action;
//     const show = allowPublish || primaryAction === "save_and_continue";
//     // if (show) {
//     //     this.show_buttonsTarget.classList.remove('d-none')
//     //   } else {
//     //     this.show_buttonsTarget.classList.add('d-none')
//     //   }
//     console.log("TESTING: PublishStatusController show set as ", show);
//     this.show_buttonsTarget.classList.toggle('d-none', !show);
//   }

  connect() {
    console.log("TESTING: PublishStatusController connected");
    consumer.subscriptions.create(
      { channel: "PublishStatusChannel" },
      {
        connected: () => {
            this.renderPublishStatus()
        },
        received: (data) => {
            this.updatePublishStatus(data)
        }
      }
    )
    console.log("TESTING: PublishStatusChannel subscription created");
  }

  updatePublishStatus (data) {
    this.data.set('allowPublish', data.allow_publish)
    
    this.renderPublishStatus()
  }

  renderPublishStatus () {
    const primaryAction = this.data.get('primaryAction')
    const allowPublish = this.data.get('allowPublish') === 'true'
    const show = allowPublish || primaryAction === "save_and_continue"

    console.log("TESTING: PublishStatusController show set as ", show);
    this.show_buttonsTarget.classList.toggle('d-none', !show);
  }

  disconnect() {
    this.subscription.unsubscribe();
  }
}