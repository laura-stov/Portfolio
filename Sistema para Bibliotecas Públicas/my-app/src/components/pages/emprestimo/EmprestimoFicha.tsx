import { useEffect, useState } from "react";
import { Livro } from "../../../models/Livro";
import { Leitor } from "../../../models/Leitor";
import axios from "axios";
import { useNavigate } from "react-router-dom";

function EmprestimoFicha() {
    const [livros, setLivros] = useState<Livro[]>([]);
    const [leitores, setLeitores] = useState<Leitor[]>([]);
    const [livroId, setLivroId] = useState("");
    const [leitorId, setLeitorId] = useState("");

    const navigate = useNavigate();

    useEffect(() => {
        // Buscar livros e leitores
        axios
            .all([
                axios.get<Livro[]>("http://localhost:5274/biblioteca/livro/listar"),
                axios.get<Leitor[]>("http://localhost:5274/biblioteca/leitor/listar")
            ])
            .then(([livrosResponse, leitoresResponse]) => {
                setLivros(livrosResponse.data);
                setLeitores(leitoresResponse.data);
            })
            .catch((error) => {
                console.error("Erro ao buscar livros e leitores:", error);
            });
    }, []);

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();

        // Criar o objeto do empréstimo
        const emprestimo = {
            livroId: livroId,
            leitorId: leitorId
        };

        // Enviar os dados de empréstimo
        fetch("http://localhost:5274/biblioteca/emprestimo/ficha", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify(emprestimo),
        })
            .then((resposta) => resposta.json())
            .then(() => {
                console.log("Empréstimo cadastrado com sucesso");
                navigate("/pages/emprestimo/listar");
            })
            .catch((error) => {
                console.error("Erro ao cadastrar empréstimo:", error);
            });
    };

    return (
        <div className="container">
            <h1>Realizar Empréstimo</h1>
            <form onSubmit={handleSubmit}>
                <div>
                    <label>Título do livro:</label>
                    <select
                        value={livroId}
                        onChange={(e) => setLivroId(e.target.value)}
                        required
                    >
                        <option value="">Selecione um livro</option>
                        {livros.map((livro) => (
                            <option key={livro.livroId} value={livro.livroId}>
                                {livro.titulo}
                            </option>
                        ))}
                    </select>
                </div>

                <div>
                    <label>Autor do livro:</label>
                    <select
                        value={livroId}
                        onChange={(e) => setLivroId(e.target.value)}
                        required
                    >
                        <option value="">Selecione um autor</option>
                        {livros.map((livro) => (
                            <option key={livro.livroId} value={livro.livroId}>
                                {livro.autor?.nome + ' ' + livro.autor?.sobrenome}
                            </option>
                        ))}
                    </select>
                </div>

                <div>
                    <label>CPF do leitor:</label>
                    <select
                        value={leitorId}
                        onChange={(e) => setLeitorId(e.target.value)}
                        required
                    >
                        <option value="">Selecione o CPF do leitor</option>
                        {leitores.map((leitor) => (
                            <option key={leitor.leitorId} value={leitor.leitorId}>
                                {leitor.cpf}
                            </option>
                        ))}
                    </select>
                </div>

                <button type="submit">Realizar Empréstimo</button>
            </form>
        </div>
    );
}

export default EmprestimoFicha;
