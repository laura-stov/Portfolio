from django.db import models
from django.contrib.auth import get_user_model
from django.contrib.auth.models import User

#classe que comporta os campos que vamos ter na tabela do sql
class Tarefa(models.Model):
    STATUS = (
        ('doing', 'Em andamento'),
        ('done', 'Concluída'),
        ('pending', 'Pendente')
    )
    
    titulo = models.CharField(max_length=50)
    descricao = models.TextField()
    done = models.CharField(
        max_length=7,
        choices=STATUS,        
    )   
    #se deletar usuário deleta tudo
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="tasks_created")
    created_at = models.DateTimeField(auto_now_add=True) 
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.titulo