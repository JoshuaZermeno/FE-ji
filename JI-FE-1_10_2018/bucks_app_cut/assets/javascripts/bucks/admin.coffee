# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).ready ->

  $realInputField = $('#slide_image_image')
  pageLoadFlag = false

  $('#upload_button').click ->
    $realInputField.click()

  $realInputField.change ->
    j = undefined
    if $('#slideshow_image_image').val() == ''
        pageLoadFlag = false
    else
        $('#image_upload_form').submit()
        return

$(".gallery-item-remove").on "click", ->
    location.href = "/admin/slideshow/" + this.id
    