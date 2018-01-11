# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->  
  $('#add_range').on 'click', ->
    $('#value_range_false').attr('style', 'display: none')
    $('#value_range_true').attr('style', 'display: block')
    $('#bucket_value').val('')
    $('#bucket_min').val(0)
    $('#bucket_max').val(0)
  return

$ ->
  $('#remove_range').on 'click', ->
    $('#value_range_false').attr('style', 'display: block')
    $('#value_range_true').attr('style', 'display: none')
    $('#bucket_value').val(0)
    $('#bucket_min').val('')
    $('#bucket_max').val('')
  return

$ ->
  $('#btn_delete_bucket').on 'click', ->
  	$('#message-box-danger').addClass('open')
  	return
