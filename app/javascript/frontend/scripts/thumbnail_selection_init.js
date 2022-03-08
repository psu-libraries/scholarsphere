import $ from 'jquery'

$(document).ready(thumbnailSelectionInit)

function thumbnailSelectionInit () {
  var inputField = $('input#thumbnail_form_thumbnail_upload')
  var thumbnailUploadRadio = $('input#thumbnail_form_thumbnail_selection_uploaded_image')
  var thumbnailUploadLabel = $('label[for="thumbnail_form_thumbnail_selection_uploaded_image"]')

  inputField.change(function () {
    var fileName = $(this).val()
    if (fileName.length) {
      thumbnailUploadRadio.attr('disabled', false)
      thumbnailUploadRadio.prop('checked', true)
      thumbnailUploadLabel.attr('class', '')
    }
  })
}
