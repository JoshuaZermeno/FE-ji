# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).ready ->
  setTableRowsClickableEmployees()
  validateEmployeePanel()
  validateInformationPanel()
  validateReasonPanel()
  $('#bucket_name').change ->
    $('#new_buck_get_form').submit()
    validateBucket()
    return

  $('#buck_post').on 'click', (e) ->
    e.preventDefault()
    $(this).prop('disabled', true)
    $('#buck_employee_id').val($('#employee_id').val())
    $('#buck_bucket_name').val($('#bucket_name').val())
    $('#buck_value').val($('#value').val())
    $('#buck_performed_at').val($('#performed_at').val())
    $('#buck_reason').val($('#reason').val())
    $('#new_buck_post_form').submit()
    return

  $('#value').on 'keyup', ->
    validateInformationPanel()
    $('#value').val($('#value').val())
    return

  $('#employee_id').on 'keyup', ->
    validateEmployeePanel()
    return

  $('#value').on 'keyup', ->
    validateInformationPanel()
    $('#value').val($('#value').val())
    return

  $('#reason').on 'keyup', ->
    validateReasonPanel()
    return

  $('#performed_at').on 'focusout', ->
    
    return

  $('#clear_employee').on 'click', ->
    $('#employee_id').val('')
    $('#employee_first').val('')
    $('#employee_last').val('')
    return

  return
  
validateEmployeePanel = ->
  ID = document.getElementById('employee_id')
  if ID != null and ID.value.match /\d{9}/
    $('#name_panel').removeClass('panel-danger')
    $('#name_panel').addClass('panel-success')
  else
    $('#name_panel').removeClass('panel-success')
    $('#name_panel').addClass('panel-danger')
  return

validateInformationPanel = ->
  min = parseInt($('#bucket_min').val())
  max = parseInt($('#bucket_max').val())
  req_date = $('#bucket_require_date').val()
  if validateValue(min, max) and validateBucket()
    $('#information_panel').removeClass('panel-danger')
    $('#information_panel').addClass('panel-success')
  else
    $('#information_panel').removeClass('panel-success')
    $('#information_panel').addClass('panel-danger')
  return

validateBucket = ->
  bucket = document.getElementById("bucket_name").value
  if bucket == ""
    $('#bucket_name').addClass('error')
    return false
  else
    $('#bucket_name').removeClass('error')
    return true
  return

validateValue = (min, max) ->
  buckValue = parseInt($('#value').val())
  if min == ""
    $('#value').removeClass('error')
    return true
  else
    if buckValue < min or buckValue > max or $.isNumeric(buckValue) == false or buckValue == ""
      $('#value').addClass('error')
      return false
    else
      $('#value').removeClass('error')
      return true
  return 

validateReasonPanel = ->
  reason = $('#reason').val()
  if reason == ''
    $('#reason_panel').addClass('panel-danger')
    $('#reason').addClass('error')
    $('#reason_panel').removeClass('panel-success')
    return false
  else
    $('#reason_panel').addClass('panel-success')
    $('#reason_panel').removeClass('panel-danger')
    $('#reason').removeClass('error')
    return true
  return

@toggle_reasons = ->
  o = document.getElementById('reason_options')
  r = document.getElementById('reason')
  t = document.getElementById('toggle_reasons')
  if o.style.display == 'block'
    o.style.display = 'none'
    r.style.display = 'block'
    t.innerHTML = '+ Common Reasons'
  else
    o.style.display = 'block'
    r.style.display = 'none'
    t.innerHTML = '- Common Reasons'
  updateLength()
  return

@updateReasonValue = (obj) ->
  text_area = document.getElementById('reason')
  value = obj.innerHTML
  text_area.value = value
  toggle_reasons()
  validateReasonPanel()
  return

textLength = (value) ->
  maxLength = 255
  if value.length > maxLength
    return false
  else
    return true
  return

@updateLength = ->
  counter = document.getElementById('text_length')
  text_area = document.getElementById('reason')
  counter.innerHTML = text_area.value.length + '/250 characters max'
  return

validateIDnum = ->
  ID = document.getElementById('employee_id')
  ID.value.match '/d{9}'
  return

setTableRowsClickableEmployees = undefined

setTableRowsClickableEmployees = ->
  j = undefined
  k = undefined
  k = document.getElementById('table-bucks-employee-list')
  if k != null
    rows = k.rows
    j = 0
    while j < rows.length
      rows[j].onclick = (event) ->
        cells = undefined
        s1 = undefined
        s2 = undefined
        s3 = undefined
        if @parentNode.nodeName == 'THEAD'
          return
        cells = @cells
        s1 = document.getElementById('employee_id')
        s2 = document.getElementById('employee_first')
        s3 = document.getElementById('employee_last')
        s1.value = $.trim(cells[0].innerHTML)
        s2.value = $.trim(cells[1].innerHTML)
        s3.value = $.trim(cells[2].innerHTML)
        validateEmployeePanel()

        return

      j++
  return



