$(document).ready(function(){
    var deletaBtn = $('.deleta-btn');
    var searchBtn = $('#search-btn');
    var searchForm = $('#search-form');
    var baseUrl = 'http://127.0.0.1:8000/';
    var filter = $('#filter')

    $(deletaBtn).on('click', function(e){
        e.preventDefault();

        var delLink = $(this).attr('href');
        var resultado = confirm('Quer deletar essa tarefa?');

        if(resultado){
            window.location.href = delLink;
        }
    });

    $(searchBtn).on('click', function(){
        searchForm.submit();
    });

    $(filter).change(function(){
        var filter = $(this).val();
        console.log(filter);
        window.location.href = baseUrl + '?filter=' + filter;
    });

    $('.status-select').on('change', function() {
        var status = $(this).val();
        var tarefaId = $(this).closest('li').data('id');
        var url = `/alterarstatus/${tarefaId}/`;

        $.ajax({
            url: url,
            method: 'POST',
            data: {
                'status': status,
                'csrfmiddlewaretoken': $('input[name="csrfmiddlewaretoken"]').val()
            },
            success: function() {
                // Atualiza a página ou a parte relevante para refletir a mudança
                location.reload();
            }
        });
    });
});