using Microsoft.AspNetCore.Mvc;
using Biblioteca.Models;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDbContext<AppDataContext>();

builder.Services.AddCors(options =>
    options.AddPolicy("Acesso Total",
        configs => configs
            .AllowAnyOrigin()
            .AllowAnyHeader()
            .AllowAnyMethod())
);

var app = builder.Build();

app.MapGet("/", () => "API de Livros");

// ------ LIVROS -------

// Listar livro com autor
app.MapGet("/biblioteca/livro/listar", ([FromServices] AppDataContext ctx) =>
{
    var livros = ctx.Livros.Include(x => x.Autor).ToList();
    if (livros.Any())
    {
        return Results.Ok(livros);
    }
    return Results.NotFound();
});

// Buscar livro pelo id
app.MapGet("/biblioteca/livro/buscar/{id}", ([FromRoute] string id, [FromServices] AppDataContext ctx) =>{
    Livro? livro = ctx.Livros.Find(id);
    if (livro == null){
        return Results.NotFound();
    } 
    return Results.Ok(livro);
});

// Cadastrar livro
app.MapPost("/biblioteca/livro/cadastrar", ([FromBody] Livro livro, [FromServices] AppDataContext ctx) =>
{
    Autor? autor = ctx.Autores.Find(livro.AutorId);
    if (autor is null)
    {
        return Results.NotFound("Autor não encontrado.");
    }
    livro.Autor = autor;
    ctx.Livros.Add(livro);
    ctx.SaveChanges();
    return Results.Created("", livro);
});

// Deletar livro pelo id
app.MapDelete("/biblioteca/livro/deletar/{id}", ([FromRoute] string id, [FromServices] AppDataContext ctx) =>{
    Livro? livro = ctx.Livros.Find(id);
    if(livro == null){
        return Results.NotFound();
    }
    ctx.Livros.Remove(livro);
    ctx.SaveChanges();
    return Results.Ok(livro);
});

// Alterar livro pelo id
app.MapPut("/biblioteca/livro/alterar/{id}", ([FromRoute] string id, [FromBody] Livro livroAlterado, [FromServices] AppDataContext ctx) =>
{
    Livro? livro = ctx.Livros.Find(id);
    if (livro == null)
    {
        return Results.NotFound();
    }
    Autor? autor = ctx.Autores.Find(livroAlterado.AutorId);
    if (autor is null)
    {
        return Results.NotFound();
    }
    livro.Autor = autor;
    livro.Titulo = livroAlterado.Titulo;
    livro.QtdExemplares = livroAlterado.QtdExemplares;
    livro.Genero = livroAlterado.Genero;
    livro.AnoLancamento = livroAlterado.AnoLancamento;
    livro.Editora = livroAlterado.Editora;
    ctx.Livros.Update(livro);
    ctx.SaveChanges();
    return Results.Ok(livro);
});

// ------ AUTORES -------

// Cadastrar autor
app.MapPost("/biblioteca/autor/cadastrar", ([FromBody] Autor autor, [FromServices] AppDataContext ctx) =>
{
    ctx.Autores.Add(autor);
    ctx.SaveChanges();
    return Results.Created("", autor);
});

// Listar autor
app.MapGet("/biblioteca/autor/listar", ([FromServices] AppDataContext ctx) =>
{
    if (ctx.Autores.Any()){
        return Results.Ok(ctx.Autores.ToList());
    }    
    return Results.NotFound();
});

// Buscar autor pelo id
app.MapGet("/biblioteca/autor/buscar/{id}", ([FromRoute] string id, [FromServices] AppDataContext ctx) =>{
    Autor? autor = ctx.Autores.Find(id);
    if (autor == null){
        return Results.NotFound();
    } 
    return Results.Ok(autor);
});

// Deletar autor pelo id
app.MapDelete("/biblioteca/autor/deletar/{id}", ([FromRoute] string id, [FromServices] AppDataContext ctx) =>{
    Autor? autor = ctx.Autores.Find(id);
    if(autor == null){
        return Results.NotFound();
    }
    ctx.Autores.Remove(autor);
    ctx.SaveChanges();
    return Results.Ok(autor);
});

// Alterar autor pelo id
app.MapPut("/biblioteca/autor/alterar/{id}", ([FromRoute] string id, [FromBody] Autor autorAlterado, [FromServices] AppDataContext ctx) => {
    Autor? autor = ctx.Autores.Find(id);
    if(autor == null){
        return Results.NotFound();
    }
    autor.Nome = autorAlterado.Nome;
    autor.Sobrenome = autorAlterado.Sobrenome;
    autor.Pais = autorAlterado.Pais;
    ctx.SaveChanges();
    return Results.Ok(autor);
});

// ------ LEITORES -------

// Cadastrar leitor/cliente
app.MapPost("/biblioteca/leitor/cadastrar", ([FromBody] Leitor leitor, [FromServices] AppDataContext ctx) =>
{
    ctx.Leitores.Add(leitor);
    ctx.SaveChanges();
    return Results.Created("", leitor);
});

// Listar leitor/cliente
app.MapGet("/biblioteca/leitor/listar", ([FromServices] AppDataContext ctx) =>
{
    if (ctx.Leitores.Any()){
        return Results.Ok(ctx.Leitores.ToList());
    }    
    return Results.NotFound();
});

// Buscar leitor/cliente pelo id
app.MapGet("/biblioteca/leitor/buscar/{id}", ([FromRoute] string id, [FromServices] AppDataContext ctx) =>{
    Leitor? leitor = ctx.Leitores.Find(id);
    if (leitor == null){
        return Results.NotFound();
    } 
    return Results.Ok(leitor);
});

// Deletar leitor/cliente pelo id
app.MapDelete("/biblioteca/leitor/deletar/{id}", ([FromRoute] string id, [FromServices] AppDataContext ctx) =>{
    Leitor? leitor = ctx.Leitores.Find(id);
    if(leitor == null){
        return Results.NotFound();
    }
    ctx.Leitores.Remove(leitor);
    ctx.SaveChanges();
    return Results.Ok(leitor);
});

// Alterar autor pelo id
app.MapPut("/biblioteca/leitor/alterar/{id}", ([FromRoute] string id, [FromBody] Leitor leitorAlterado, [FromServices] AppDataContext ctx) => {
    Leitor? leitor = ctx.Leitores.Find(id);
    if(leitor == null){
        return Results.NotFound();
    }
    leitor.Nome = leitorAlterado.Nome;
    leitor.Sobrenome = leitorAlterado.Sobrenome;
    leitor.Email = leitorAlterado.Email;
    leitor.Telefone = leitorAlterado.Telefone;
    leitor.CPF = leitorAlterado.CPF;
    ctx.SaveChanges();
    return Results.Ok(leitor);
});

// ------- EMPRESTIMOS ------

// Realizar ficha do empréstimo
app.MapPost("/biblioteca/emprestimo/ficha", ([FromBody] Emprestimo emprestimo, [FromServices] AppDataContext ctx) =>
{
    Livro? livro = ctx.Livros.Find(emprestimo.LivroId);
    Leitor? leitor = ctx.Leitores.Find(emprestimo.LeitorId);

    if (livro == null || leitor == null)
        return Results.NotFound("Livro ou Leitor não encontrados.");

    if (livro.QtdExemplares <= 0)
        return Results.BadRequest("Não há exemplares disponíveis.");

    // Atualiza a quantidade de exemplares do livro
    livro.QtdExemplares--;

    emprestimo.Livro = livro;
    emprestimo.Leitor = leitor;

    ctx.Emprestimos.Add(emprestimo);
    ctx.SaveChanges();

    return Results.Created("", emprestimo);
});

// Lista dos empréstimos ativos (não devolvidos)
app.MapGet("/biblioteca/emprestimo/listar", ([FromServices] AppDataContext ctx) =>
{
    var emprestimos = ctx.Emprestimos
        .Include(e => e.Livro)
        .ThenInclude(l => l.Autor)
        .Include(e => e.Leitor)
        .Where(e => e.Ativo)
        .ToList();

    return emprestimos.Any() ? Results.Ok(emprestimos) : Results.NotFound();
});

// Devolução dos livros
app.MapPut("/biblioteca/emprestimo/devolver/{id}", ([FromRoute] string id, [FromServices] AppDataContext ctx) =>
{
    Emprestimo? emprestimo = ctx.Emprestimos
        .Include(e => e.Livro)
        .FirstOrDefault(e => e.EmprestimoId == id);

    if (emprestimo == null)
        return Results.NotFound("Empréstimo não encontrado.");

    if (!emprestimo.Ativo)
        return Results.BadRequest("O empréstimo já foi devolvido.");

    // Atualiza a quantidade de exemplares
    emprestimo.Livro.QtdExemplares++;

    // Marca o empréstimo como inativo
    emprestimo.Ativo = false;

    emprestimo.DataDevolucao = DateTime.Now;

    ctx.SaveChanges();

    return Results.Ok(emprestimo);
});

app.MapPut("/biblioteca/emprestimo/alterar/{id}", ([FromRoute] string id, [FromBody] Emprestimo emprestimoAlterado, [FromServices] AppDataContext ctx) =>
{
    // Busca o empréstimo original no banco
    Emprestimo? emprestimo = ctx.Emprestimos
        .Include(e => e.Livro)
        .Include(e => e.Leitor)
        .FirstOrDefault(e => e.EmprestimoId == id);

    if (emprestimo == null)
    {
        return Results.NotFound("Empréstimo não encontrado.");
    }

    // Busca o novo livro e leitor no banco
    Livro? novoLivro = ctx.Livros.Find(emprestimoAlterado.LivroId);
    Leitor? novoLeitor = ctx.Leitores.Find(emprestimoAlterado.LeitorId);

    if (novoLivro == null || novoLeitor == null)
    {
        return Results.NotFound("Livro ou Leitor não encontrados.");
    }

    // Incrementa a quantidade do livro devolvido (antigo livro)
    if (emprestimo.Livro != null)
    {
        emprestimo.Livro.QtdExemplares++;
    }

    // Decrementa a quantidade do novo livro
    novoLivro.QtdExemplares--;

    if (novoLivro.QtdExemplares < 0)
    {
        return Results.BadRequest("O novo livro não possui exemplares disponíveis.");
    }

    // Atualiza os relacionamentos e outras informações
    emprestimo.Livro = novoLivro;
    emprestimo.Leitor = novoLeitor;

    // Salva as alterações no banco
    ctx.SaveChanges();

    return Results.Ok(emprestimo);
});

// Lista das devoluções (empréstimos devolvidos)
app.MapGet("/biblioteca/devolucao/listar", ([FromServices] AppDataContext ctx) =>
{
    var devolucoes = ctx.Emprestimos
        .Include(e => e.Livro) // Inclui o livro do empréstimo
        .ThenInclude(l => l.Autor) // Inclui o autor do livro
        .Include(e => e.Leitor) // Inclui o leitor do empréstimo
        .Where(e => !e.Ativo) // Filtra apenas os empréstimos que foram devolvidos (DataDevolucao não nula)
        .OrderBy(e => e.DataDevolucao) // Ordena por data de devolução
        .ToList();

    if (devolucoes.Any())
    {
        return Results.Ok(devolucoes); // Retorna as devoluções com livros e autores
    }

    return Results.NotFound(); // Caso não haja devoluções
});

// Buscar empréstimo pelo id
app.MapGet("/biblioteca/emprestimo/buscar/{id}", ([FromRoute] string id, [FromServices] AppDataContext ctx) =>{
    Emprestimo? emprestimo = ctx.Emprestimos.Find(id);
    if (emprestimo == null){
        return Results.NotFound();
    } 
    return Results.Ok(emprestimo);
});

// Deletar empréstimo pelo id
app.MapDelete("/biblioteca/emprestimo/deletar/{id}", ([FromRoute] string id, [FromServices] AppDataContext ctx) =>
{
    // Busca o empréstimo no banco
    Emprestimo? emprestimo = ctx.Emprestimos
        .Include(e => e.Livro) // Inclui o relacionamento com o livro
        .FirstOrDefault(e => e.EmprestimoId == id);

    if (emprestimo == null)
    {
        return Results.NotFound("Empréstimo não encontrado.");
    }

    // Incrementa a quantidade de exemplares do livro associado
    if (emprestimo.Livro != null)
    {
        emprestimo.Livro.QtdExemplares++;
    }

    // Remove o empréstimo do banco
    ctx.Emprestimos.Remove(emprestimo);

    // Salva as alterações no banco
    ctx.SaveChanges();

    return Results.Ok("Empréstimo deletado com sucesso.");
});

app.UseCors("Acesso Total");
app.Run();