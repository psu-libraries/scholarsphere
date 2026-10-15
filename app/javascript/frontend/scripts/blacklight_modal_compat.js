// Custom script for blacklight frontend 7 modals to work with blacklight 8
document.addEventListener('click', (event) => {
  const dismissTarget = event.target.closest('[data-bl-dismiss="modal"]')
  if (!dismissTarget) return

  event.preventDefault()

  const modalEl = dismissTarget.closest('.modal') || document.getElementById('blacklight-modal')
  if (!modalEl || !window.bootstrap?.Modal) return

  window.bootstrap.Modal.getOrCreateInstance(modalEl).hide()
})
