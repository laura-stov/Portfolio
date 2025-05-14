namespace Biblioteca.Models
{
    public class Leitor
    {
        public Leitor()
        {
            LeitorId = Guid.NewGuid().ToString();
        }

        public string? LeitorId { get; set;}

        public string? Nome { get; set; }

        public string? Sobrenome { get; set; }

        public string? Email { get; set;}

        public string Telefone { get; set; }

        public string CPF { get; set; }
    }
}