import { Controller } from 'stimulus'
import Uppy from '@uppy/core'
import AwsS3Multipart from '@uppy/aws-s3-multipart'
import Dashboard from '@uppy/dashboard'
import { generateUploadedFileData, simulateEditAndUpload } from './uppy_utils'

export default class extends Controller {
  connect() {
    this.uploadSubmit = document.querySelector('.upload-submit')
    this.parentForm = document.getElementById(this.data.get('parentForm'))
    this.blacklist = JSON.parse(this.data.get('blacklist') || '[]')

    this.initializeUppy()
  }

  initializeUppy() {
    this.uppy = this.createUppyInstance()
    this.configureUppyPlugins()
    this.registerUppyEventHandlers()
  }

  createUppyInstance() {
    return new Uppy({
      id: 'uppy_' + (new Date().getTime()),
      autoProceed: false,
      allowMultipleUploads: true,
      onBeforeFileAdded: (currentFile, files) => this.handleBeforeFileAdded(currentFile, files),
      onBeforeUpload: (files) => this.handleBeforeUpload(files)
    })
  }

  configureUppyPlugins() {
    this.uppy
      .use(Dashboard, {
        id: 'dashboard',
        target: this.element,
        inline: 'true',
        showProgressDetails: true,
        height: 350,
        doneButtonHandler: null,
        metaFields: [
          {
            id: 'alt_text',
            name: 'Alt Text',
            placeholder: 'Describe this image for accessibility',
            required: true
          }
        ]
      })
      .use(AwsS3Multipart, {
        companionUrl: '/'
      })
  }

  registerUppyEventHandlers() {
    this.uppy
      .on('file-added', (file) => this.handleFileAdded(file))
      .on('complete', (result) => this.onUppyComplete(result))
  }

  handleBeforeFileAdded(currentFile, files) {
    const filename = currentFile.name
    const isBlacklisted = this.blacklist.includes(filename)

    if (isBlacklisted) {
      this.uppy.info(`Error: ${filename} already exists in this version`, 'error', 10000)
      return false
    }
  }

  handleBeforeUpload(files) {
    const fileCount = Object.keys(files).length
    const file = Object.values(files)[fileCount - 1]
    const missingAltText = file.type?.startsWith('image/') && !file.meta.alt_text?.trim()

    if (missingAltText) {
      this.uppy.info('Please provide alt text for all image files before uploading.', 'error', 5000)
      simulateEditAndUpload()
      return false
    }
  }

  handleFileAdded(file) {
    if (file.type.startsWith('image/')) {
      this.uppy.pauseResume(file.id)
      setTimeout(() => {
        this.simulateEditAndUpload()
      }, 100)
    } else {
      this.uppy.upload()
    }
  }

  onUppyComplete(result) {
    result.successful.forEach(success => {
      this.parentForm.appendChild(this.createHiddenFileInput(success))
    })
  }

  createHiddenFileInput(success) {
    const inputName = this.data.get('inputName')
    const uploadedFileData = generateUploadedFileData(success)

    const input = document.createElement('input')
    input.setAttribute('type', 'hidden')
    input.setAttribute('name', inputName)
    input.setAttribute('value', uploadedFileData)

    return input
  }
}
