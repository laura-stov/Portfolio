from django import forms
from .models import Tarefa
from django.contrib.auth import get_user_model
from django.contrib.auth.models import User

class TarefaFormulario(forms.ModelForm):

    class Meta:
        model = Tarefa
        fields = ['titulo', 'descricao', 'done', 'user']
        labels = {
            'titulo': 'Título',
            'descricao': 'Descrição',
            'done': 'Status',
            'user': 'Usuário'
        }
    
    def __init__(self, *args, **kwargs):
        user_queryset = kwargs.pop('user_queryset', None)
        super(TarefaFormulario, self).__init__(*args, **kwargs)
        if user_queryset is not None:
            self.fields['user'].queryset = user_queryset