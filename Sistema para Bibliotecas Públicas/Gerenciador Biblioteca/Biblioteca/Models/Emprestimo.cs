namespace Biblioteca.Models
{
    public class Emprestimo
    {
        public Emprestimo()
        {
            EmprestimoId = Guid.NewGuid().ToString();
        }

        public string? EmprestimoId { get; set; }

        public string? LivroId { get; set; }

        public Livro Livro { get; set; }

        public string LeitorId { get; set; }

        public Leitor Leitor { get; set; }

        public DateTime DataEmprestimo { get; set; } = DateTime.Now;
        
        public DateTime PrazoDevolucao { get; set; } = DateTime.Now.AddDays(14);

        public DateTime DataDevolucao  { get; set; }

        public bool Ativo { get; set; } = true;
    }
}