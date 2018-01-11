# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/



$ ->
  $('#variant_images').on 'click', 'img', ->
    $('#prize_image_holder').attr('style', 'background-image: url(' + $(this).attr('src') + ')')
    false
  return

$ ->
  $('#btn_inc_qty').on 'click', ->
    quantity = $('#prize_quantity').val();
    quantity++;
    $('#prize_quantity').val(quantity);
    false
  return

$ ->
  $('#btn_dec_qty').on 'click', ->
    quantity = $('#prize_quantity').val();
    if quantity > 1
      quantity--;
    $('#prize_quantity').val(quantity);
    false
  return

$ ->
  $('#btn_delete_item').on 'click', ->
    $('#delete_item_popup').attr('style', 'display: block')
    false
  $('#btn_close_danger').on 'click', ->
    $('#delete_item_popup').attr('style', 'display: none')
    false
  return

$ ->
  $('#store_purchase_button').on 'click', ->
    details = $('#prize_details').val();
    color = $('#prize_color').val();
    size = $('#prize_size').val();
    quantity = $('#prize_quantity').val();
    $('#popup_message').html("Details: " + details + "<br/>Color: " + color + "<br/>Size: " + size + "<br/>Quantity: " + quantity);
    $('#message-box-default').attr('style', 'display: block')
    false
  return

$ ->
  $('#store_cancel_button').on 'click', ->
    $('#message-box-default').attr('style', 'display: none')
    false
  return

$(document).ready ->
  setTableRowsClickableEmployees()
  return
$(document).ajaxStop ->
  setTableRowsClickableEmployees()
  return

setTableRowsClickableEmployees = undefined


setTableRowsClickableEmployees = ->
  j = undefined
  k = undefined
  k = document.getElementById('table-prizes-choose')
  if k != null
    rows = k.rows
    j = 0
    while j < rows.length

      rows[j].onclick = (event) ->
        cells = undefined
        s1 = undefined
        s2 = undefined
        if @parentNode.nodeName == 'THEAD'
          return
        cells = @cells
        s1 = document.getElementById('prize_name')
        s2 = document.getElementById('prize_cost')
        s3 = document.getElementById('prize_image')
        s1.value = cells[0].innerHTML
        s2.value = cells[1].innerHTML
        s3.value = cells[2].innerHTML
        return

      j++
  return