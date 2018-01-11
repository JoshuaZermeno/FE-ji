// Coffeescript for the Bucks views converted into Javascript through converter.
// Much of this is form validation with jQuery. Not really pure Javascript.

(function() {
  var setTableRowsClickableEmployees, textLength, validateBucket, validateEmployeePanel, validateIDnum, validateInformationPanel, validateReasonPanel, validateValue;

  $(document).ready(function() {
    setTableRowsClickableEmployees();
    validateEmployeePanel();
    validateInformationPanel();
    validateReasonPanel();
    $('#bucket_name').change(function() {
      $('#new_buck_get_form').submit();
      validateBucket();
    });
    $('#buck_post').on('click', function(e) {
      e.preventDefault();
      $(this).prop('disabled', true);
      $('#buck_employee_id').val($('#employee_id').val());
      $('#buck_bucket_name').val($('#bucket_name').val());
      $('#buck_value').val($('#value').val());
      $('#buck_performed_at').val($('#performed_at').val());
      $('#buck_reason').val($('#reason').val());
      $('#new_buck_post_form').submit();
    });
    $('#value').on('keyup', function() {
      validateInformationPanel();
      $('#value').val($('#value').val());
    });
    $('#employee_id').on('keyup', function() {
      validateEmployeePanel();
    });
    $('#value').on('keyup', function() {
      validateInformationPanel();
      $('#value').val($('#value').val());
    });
    $('#reason').on('keyup', function() {
      validateReasonPanel();
    });
    $('#performed_at').on('focusout', function() {});
    $('#clear_employee').on('click', function() {
      $('#employee_id').val('');
      $('#employee_first').val('');
      $('#employee_last').val('');
    });
  });

  validateEmployeePanel = function() {
    var ID;
    ID = document.getElementById('employee_id');
    if (ID !== null && ID.value.match(/\d{9}/)) {
      $('#name_panel').removeClass('panel-danger');
      $('#name_panel').addClass('panel-success');
    } else {
      $('#name_panel').removeClass('panel-success');
      $('#name_panel').addClass('panel-danger');
    }
  };

  validateInformationPanel = function() {
    var max, min, req_date;
    min = parseInt($('#bucket_min').val());
    max = parseInt($('#bucket_max').val());
    req_date = $('#bucket_require_date').val();
    if (validateValue(min, max) && validateBucket()) {
      $('#information_panel').removeClass('panel-danger');
      $('#information_panel').addClass('panel-success');
    } else {
      $('#information_panel').removeClass('panel-success');
      $('#information_panel').addClass('panel-danger');
    }
  };

  validateBucket = function() {
    var bucket;
    bucket = document.getElementById("bucket_name").value;
    if (bucket === "") {
      $('#bucket_name').addClass('error');
      return false;
    } else {
      $('#bucket_name').removeClass('error');
      return true;
    }
  };

  validateValue = function(min, max) {
    var buckValue;
    buckValue = parseInt($('#value').val());
    if (min === "") {
      $('#value').removeClass('error');
      return true;
    } else {
      if (buckValue < min || buckValue > max || $.isNumeric(buckValue) === false || buckValue === "") {
        $('#value').addClass('error');
        return false;
      } else {
        $('#value').removeClass('error');
        return true;
      }
    }
  };

  validateReasonPanel = function() {
    var reason;
    reason = $('#reason').val();
    if (reason === '') {
      $('#reason_panel').addClass('panel-danger');
      $('#reason').addClass('error');
      $('#reason_panel').removeClass('panel-success');
      return false;
    } else {
      $('#reason_panel').addClass('panel-success');
      $('#reason_panel').removeClass('panel-danger');
      $('#reason').removeClass('error');
      return true;
    }
  };

  this.toggle_reasons = function() {
    var o, r, t;
    o = document.getElementById('reason_options');
    r = document.getElementById('reason');
    t = document.getElementById('toggle_reasons');
    if (o.style.display === 'block') {
      o.style.display = 'none';
      r.style.display = 'block';
      t.innerHTML = '+ Common Reasons';
    } else {
      o.style.display = 'block';
      r.style.display = 'none';
      t.innerHTML = '- Common Reasons';
    }
    updateLength();
  };

  this.updateReasonValue = function(obj) {
    var text_area, value;
    text_area = document.getElementById('reason');
    value = obj.innerHTML;
    text_area.value = value;
    toggle_reasons();
    validateReasonPanel();
  };

  textLength = function(value) {
    var maxLength;
    maxLength = 255;
    if (value.length > maxLength) {
      return false;
    } else {
      return true;
    }
  };

  this.updateLength = function() {
    var counter, text_area;
    counter = document.getElementById('text_length');
    text_area = document.getElementById('reason');
    counter.innerHTML = text_area.value.length + '/250 characters max';
  };

  validateIDnum = function() {
    var ID;
    ID = document.getElementById('employee_id');
    ID.value.match('/d{9}');
  };

  setTableRowsClickableEmployees = void 0;

  setTableRowsClickableEmployees = function() {
    var j, k, rows;
    j = void 0;
    k = void 0;
    k = document.getElementById('table-bucks-employee-list');
    if (k !== null) {
      rows = k.rows;
      j = 0;
      while (j < rows.length) {
        rows[j].onclick = function(event) {
          var cells, s1, s2, s3;
          cells = void 0;
          s1 = void 0;
          s2 = void 0;
          s3 = void 0;
          if (this.parentNode.nodeName === 'THEAD') {
            return;
          }
          cells = this.cells;
          s1 = document.getElementById('employee_id');
          s2 = document.getElementById('employee_first');
          s3 = document.getElementById('employee_last');
          s1.value = $.trim(cells[0].innerHTML);
          s2.value = $.trim(cells[1].innerHTML);
          s3.value = $.trim(cells[2].innerHTML);
          validateEmployeePanel();
        };
        j++;
      }
    }
  };

}).call(this);