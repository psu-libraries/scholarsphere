import consumer from '../../channels/consumer'

export function createOpenAccessVersionSubscription({ id, onVersionReceived }) {
  return consumer.subscriptions.create(
    { channel: 'OpenAccessVersionChannel', id },
    {
      received: (data) => {
        if (String(data.id) !== String(id)) return
        onVersionReceived(data.open_access_version)
      }
    }
  )
}

export function unsubscribe(subscription) {
  if (subscription && subscription.unsubscribe) {
    subscription.unsubscribe()
  }
}

export function safeUnsubscribe(subscription) {
  if (!subscription || !subscription.unsubscribe) return

  try {
    subscription.unsubscribe()
  } catch (e) {
    void e
  }
}