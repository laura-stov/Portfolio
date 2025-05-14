from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.auth.decorators import login_required
from django.core.paginator import Paginator
from django.http import HttpResponse
from .forms import TarefaFormulario
from django.contrib import messages
from django.contrib.auth import logout
from django.utils import timezone
from django.contrib.auth import get_user_model
from .models import Tarefa
from django.contrib.auth.models import User
import datetime

@login_required
def listaTarefa(request):
    search = request.GET.get('search')
    filter = request.GET.get('filter')
        
    tarefasPendentes = Tarefa.objects.filter(done='pending', user=request.user).count()
    tarefasFeitasRecentemente = Tarefa.objects.filter(done='done', updated_at__gt=timezone.now()-datetime.timedelta(days=30), user=request.user).count()
    tarefasFeitas = Tarefa.objects.filter(done='done', user=request.user).count()
    tarefasFazendo = Tarefa.objects.filter(done='doing', user=request.user).count()
    if search:
        #filtra pelo título e é case insensitive
        tarefas = Tarefa.objects.filter(titulo__icontains=search, user=request.user)
        
    elif filter:
        tarefas = Tarefa.objects.filter(done=filter, user=request.user)

    else:
        #pegando as tarefas do banco de dados e jogando para o template
        tarefas_lista = Tarefa.objects.all().order_by('-created_at').filter(user=request.user)
        paginacao = Paginator(tarefas_lista, 5)
        pagina = request.GET.get('pagina')
        tarefas = paginacao.get_page(pagina)
    
    return render(request, 'tarefas/lista.html', {'tarefas': tarefas, 'tarefasrecentes': tarefasFeitasRecentemente, 'tarefasfeitas': tarefasFeitas, 'tarefasfazendo': tarefasFazendo, 'tarefaspendentes': tarefasPendentes})

@login_required
def veTarefa(request, id):
    tarefa = get_object_or_404(Tarefa, pk=id)
    return render(request, 'tarefas/tarefa.html', {'tarefa': tarefa})

@login_required
def novaTarefa(request):
    user_queryset = User.objects.all()
    
    if request.method == 'POST':
        formulario = TarefaFormulario(request.POST, user_queryset=user_queryset)
        
        #conferindo se os dados são válidos
        if formulario.is_valid():
            tarefa = formulario.save()
            tarefa.save()
            messages.info(request, 'Tarefa criada com sucesso!')
            
            #retorna pra home
            return redirect('/')
            
    else:
        formulario = TarefaFormulario(user_queryset=user_queryset)
        return render(request, 'tarefas/adicionartarefas.html', {'formulario': formulario})

@login_required
def editarTarefa(request, id):
    tarefa = get_object_or_404(Tarefa, pk=id)
    formulario = TarefaFormulario(instance=tarefa)
    user_queryset = User.objects.all()
    
    if(request.method == 'POST'):
        formulario = TarefaFormulario(request.POST, instance=tarefa, user_queryset=user_queryset)
        
        if(formulario.is_valid()):
            tarefa = formulario.save()
            
            messages.info(request, 'Tarefa editada com sucesso!')
            return redirect('/')
        else:
            return render(request, 'tarefas/editartarefa.html', {'formulario': formulario, 'tarefa': tarefa})
            
    else:
        return render(request, 'tarefas/editartarefa.html', {'formulario': formulario, 'tarefa': tarefa})

@login_required
def excluirTarefa(request, id):
    tarefa = get_object_or_404(Tarefa, pk=id)
    tarefa.delete()
    messages.info(request, 'Tarefa deletada com sucesso!')
    
    return redirect('/')

@login_required
def alterarStatus(request, id):
    tarefa = get_object_or_404(Tarefa, pk=id)
    
    if request.method == 'POST':
        novo_status = request.POST.get('status', tarefa.done)
        tarefa.done = novo_status
        tarefa.save()
        messages.info(request, 'Status da tarefa atualizado com sucesso!')
    
    return redirect('/')

@login_required
def logout_view(request):
    logout(request)
    return redirect('login') 
    