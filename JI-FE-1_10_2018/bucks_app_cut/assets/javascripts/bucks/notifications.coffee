# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).ready ->
  $('#notification_select_all').on 'click', ->
    $('.icheckbox').prop('checked', true)
    return

  $('#notification_deselect_all').on 'click', ->
    $('.icheckbox').prop('checked', false)
    return 
  return