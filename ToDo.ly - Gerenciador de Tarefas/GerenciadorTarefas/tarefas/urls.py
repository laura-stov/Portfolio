from django.urls import path
from . import views

urlpatterns = [
    path('', views.listaTarefa, name='lista-tarefa'),
    #passa parametro string chamado nome e imprime ele no template
    path('tarefa/<int:id>', views.veTarefa, name='ve-tarefa'),
    path('novatarefa/', views.novaTarefa, name='nova-tarefa'),
    path('editar/<int:id>', views.editarTarefa, name='editar-tarefa'),
    path('excluir/<int:id>', views.excluirTarefa, name='excluir-tarefa'),
    path('alterarstatus/<int:id>', views.alterarStatus, name='alterar-status'),
    path('logout/', views.logout_view, name='logout'),
]
