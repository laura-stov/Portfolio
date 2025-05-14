namespace Biblioteca.Models
{
    public class Livro
    {
        public Livro()
        {
            LivroId = Guid.NewGuid().ToString();
        }

        public string? LivroId { get; set; }

        public string? Titulo { get; set; }

        public string? Genero { get; set; }

        public int QtdExemplares { get; set; }

        public DateTime CriadoEm { get; set; } = DateTime.Now;
        
        public int AnoLancamento { get; set; }

        public string? Editora { get; set; }

        public Autor? Autor { get; set; }

        public string AutorId { get; set; }
    }
}