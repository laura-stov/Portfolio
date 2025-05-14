import { useEffect, useState } from "react";
import { Livro } from "../../../models/Livro";
import { Leitor } from "../../../models/Leitor";
import { useNavigate, useParams } from "react-router-dom";
import axios from "axios";
import { Emprestimo } from "../../../models/Emprestimo";

function AlterarEmprestimo() {
    const { id } = useParams();
    const [livros, setLivros] = useState<Livro[]>([]);
    const [leitores, setLeitores] = useState<Leitor[]>([]);
    const [livroId, setLivroId] = useState("");
    const [leitorId, setLeitorId] = useState("");

    const navigate = useNavigate();

    useEffect(() => {
        if(id){
            axios
            .get<Emprestimo[]>(`http://localhost:5274/biblioteca/emprestimo/buscar/${id}`)
            .then(() => {
                buscarLivros();
                buscarLeitores();
            })
            .catch((error) => {
                console.error("Erro ao buscar dados:", error);
            });
        }
    }, [id]);

    function buscarLivros() {
        axios
            .get<Livro[]>("http://localhost:5274/biblioteca/livro/listar")
            .then((resposta) => {
                setLivros(resposta.data);
            })
    }

    function buscarLeitores() {
        axios
            .get<Leitor[]>("http://localhost:5274/biblioteca/leitor/listar")
            .then((resposta) => {
                setLeitores(resposta.data);
            })
    }

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();

        // Criar o objeto atualizado do empréstimo
        const emprestimoAtualizado = {
            livroId: livroId,
            leitorId: leitorId,

        };

        // Atualizar o empréstimo
        axios
            .put(`http://localhost:5274/biblioteca/emprestimo/alterar/${id}`, emprestimoAtualizado, {
                headers: {
                    "Content-Type": "application/json",
                },
            })
            .then(() => {
                console.log("Empréstimo alterado com sucesso");
                navigate("/pages/emprestimo/listar");
            })
            .catch((error) => {
                console.error("Erro ao alterar empréstimo:", error);
            });
    };

    return (
        <div id="alterar_emprestimo" className="container">
            <h1>Alterar Empréstimo</h1>
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
                                {livro.autor?.nome + " " + livro.autor?.sobrenome}
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

                <button type="submit">Salvar Alterações</button>
            </form>
        </div>
    );
}

export default AlterarEmprestimo;