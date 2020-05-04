$(document).ready(function(){
    url= "/api/list/nodes"      
    $('#addnode').on('submit', function(evt) {
        var nodeid = $('#node').val(), error;
        $.getJSON(url, function(data){
            $.each(data, function(key, value){
                if (value.id == nodeid)
                    error = 'Node already created';
                if (error) { evt.preventDefault(); alert(error); return false;}     
            });
            if(!error){
                alert ("Operation started");
                jQuery.ajax({
                    type: "POST",
                    data: "id=" +nodeid,
                    url: url,
                });
            }
        });
    });       
    $(document).on('click', '.deletenode', function(){
        if (window.confirm('Are you sure?')) {
            id = jQuery(this).parent().attr("id");
            jQuery.ajax({
                type: "DELETE",
                data: "id=" +id,
                url: url,
            });
        }
    });
    function get_data() {
        $.getJSON(url, function(data){
            var employee_data = '';
            $.each(data, function(key, value){
                employee_data += '<tr'+(value.statusid == 1 ? ' class="table-success"': (value.statusid == 2 ? ' class="table-warning"' : ' class="table-danger"')) + '>';
                employee_data += '<td>'+value.id+'</td>';
                employee_data += '<td>'+value.hostname+'</td>';
                employee_data += '<td>'+value.status+'</td>';
                employee_data += '<td>'+value.role+'</td>';
                employee_data += '<td>'+value.ip+'</td>';
                employee_data += '<td id="'+value.id+'">'+ (value.statusid != 2 ? '<button type="button" class="btn btn-sm btn-danger deletenode"><i class="far fa-trash-alt"></i></button>': '') +'</td>';
            });
            $('#worker').empty();
            $('#worker').append(employee_data);
        });
    }  
    get_data();
    setInterval(get_data,10000)
});
