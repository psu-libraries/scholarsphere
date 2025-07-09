// Implements multiple fields in our forms by adding DOM elements to add and remove cloned fields
// in the form. Relies heavily on Bootstrap's form elements. Including the proper data attributes
// will trigger the insertion of the buttons to manage the additional fields. Certain html elements
// are required, such as a label and the input-group css class.
// @example
//   <div class="form-group" data-controller="multiple-fields">
//     <!-- A label is required in order for the buttons to display correctly -->
//     <label>
//       Identifier
//     </label>
//     <!-- The input-group and form=control classes are required in order for new fields to be added -->
//     <div class="input-group">
//       <input class="form-control" />
//   </div>

import { Controller } from 'stimulus'

export default class extends Controller {
  buttonClass = 'js-mutiple-field-action'
  addButtonClass = 'js-multiple-fields-action--add'
  removeButtonClass = 'js-multiple-fields-action--remove'

  connect () {
    this.baseLabelText = this.element.getElementsByTagName('label').item(0).innerText
    this.firstInput = this.cloneFirstInput()

    this.updateActionButtons()
  }

  updateActionButtons () {
    const ACTIONS = {
      ADD: {
        className: this.addButtonClass,
        buildButton: () => this.addButton()
      },
      REMOVE: {
        className: this.removeButtonClass,
        buildButton: () => this.removeButton()
      }
    }

    Array.from(this.inputGroups).forEach((inputGroup, i) => {
      const isLast = i === this.inputGroups.length - 1
      const action = isLast ? ACTIONS.ADD : ACTIONS.REMOVE

      const existingButton = inputGroup.getElementsByClassName(this.buttonClass)[0]
      const existingButtonIsCorrect = existingButton && existingButton.classList.contains(action.className)

      if (existingButtonIsCorrect) {
        // Do nothing, the button already exists and is the correct type
      } else if (existingButton) {
        // A button already exists, but is the wrong type,
        // remove it and replace it with the right one
        existingButton.remove()
        inputGroup.appendChild(action.buildButton())
      } else {
        // No button exists, build the right one
        inputGroup.appendChild(action.buildButton())
      }
    })
  }

  // By default, Stimulus listens to click events on buttons and will execute this method.
  add (event) {
    event.preventDefault()
    this.element.appendChild(this.newField)
    this.updateActionButtons()
  }

  // By default, Stimulus listens to click events on buttons and will execute this method.
  remove (event) {
    event.preventDefault()
    event.target.parentElement.parentElement.remove()
    this.updateActionButtons()
  }

  // @return [HTMLElement] cloned field taken from the first input group.
  get newField () {
    const clone = this.firstInput.cloneNode(true)
    clone.appendChild(this.addButton())
    return clone
  }

  // @return [HTMLElement]
  addButton () {
    const node = document.createElement('a')
    node.setAttribute('href', '#')
    node.setAttribute('data-action', 'multiple-fields#add')
    node.classList.add(this.buttonClass, this.addButtonClass, 'add')

    const description = this.descriptionText('add another ' + this.baseLabelText)
    node.appendChild(description)

    const icon = this.materialIcon('add_circle_outline')
    node.appendChild(icon)

    return node
  }

  // @return [HTMLElement]
  removeButton () {
    const node = document.createElement('a')
    node.setAttribute('href', '#')
    node.setAttribute('data-action', 'multiple-fields#remove')
    node.classList.add(this.buttonClass, this.removeButtonClass, 'remove')

    const description = this.descriptionText('remove')
    node.appendChild(description)

    const icon = this.materialIcon('highlight_off')
    node.appendChild(icon)

    return node
  }

  // @return [HTMLElement]
  materialIcon (text) {
    const icon = document.createElement('i')
    icon.classList.add('material-icons')
    icon.setAttribute('aria-hidden', 'true')
    icon.appendChild(document.createTextNode(text))
    return icon
  }

  // @return [HTMLElement]
  descriptionText (text) {
    const element = document.createElement('span')
    element.classList.add('visually-hidden')
    element.appendChild(document.createTextNode(text))
    return element
  }

  // @return [HTMLCollection]
  get inputGroups () {
    return this.element.getElementsByClassName('js-multiple-field-group')
  }

  // @return [HTMLElement]
  cloneFirstInput () {
    const firstInput = this.inputGroups.item(0).cloneNode(true)
    Array.from(firstInput.getElementsByClassName('form-control')).forEach((input) => {
      input.value = ''
    })
    return firstInput
  }
}
