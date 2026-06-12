// Bridge Blacklight 8 markup to Blacklight Frontend 7 modal behavior.
// Blacklight 8 facet templates use data-bl-dismiss, while this app's modal
// JS listens for Bootstrap dismiss conventions.
document.addEventListener('click', (event) => {
  const dismissTarget = event.target.closest('[data-bl-dismiss="modal"]')
  if (!dismissTarget) return

  event.preventDefault()

  const modalEl = dismissTarget.closest('.modal') || document.getElementById('blacklight-modal')
  if (!modalEl || !window.bootstrap?.Modal) return

  window.bootstrap.Modal.getOrCreateInstance(modalEl).hide()
})
