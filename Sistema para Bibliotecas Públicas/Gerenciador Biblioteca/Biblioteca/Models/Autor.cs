namespace Biblioteca.Models
{
    public class Autor
    {
        public Autor()
        {
            AutorId = Guid.NewGuid().ToString();
        }

        public string? AutorId { get; set;}

        public string? Nome { get; set; }

        public string? Sobrenome { get; set; }

        public string? Pais { get; set;}
    }
}