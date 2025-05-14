import { useEffect, useState } from "react";
import { Livro } from "../../../models/Livro";
import { Link } from "react-router-dom";
import axios from "axios";

function LivroLista(){
    const [livros, setLivros] = useState<Livro[]>([]);

    useEffect(() => {
        fetch("http://localhost:5274/biblioteca/livro/listar", {
            method: 'GET', 
        })
            .then((resposta) => {
                if (!resposta.ok) {
                    throw new Error(`Erro na API: ${resposta.status}`);
                }
                return resposta.text(); // Lê como texto para evitar erro de JSON
            })
            .then((data) => {
                if (data) {
                    setLivros(JSON.parse(data)); // Processa somente se não estiver vazio
                } else {
                    setLivros([]); // Define lista vazia se o corpo for vazio
                }
            })
            .catch((error) => {
                console.error("Erro ao buscar empréstimos:", error);
            });
    }, []);

    function deletar(id: string) {
        axios
            .delete(`http://localhost:5274/biblioteca/livro/deletar/${id}`)
            .then(() => {
                console.log("Livro deletado com sucesso!");
                window.location.reload();
            });
    }

    const formatarDataHora = (data: string) => {
        const dataObj = new Date(data);
        return dataObj.toLocaleString('pt-BR', {
            weekday: 'short',
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
        });
    };

    return (
        <div className="container">
            <h1>Lista de Livros</h1>
            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Título</th>
                        <th>Autor</th>
                        <th>Gênero</th>
                        <th>Editora</th>
                        <th>Ano de Lançamento</th>
                        <th>Quantidade de Exemplares</th>
                        <th>Criado Em</th>
                        <th>Deletar</th>
                        <th>Alterar</th>
                    </tr>
                </thead>
                <tbody>
                    {livros.length > 0 ? (
                        livros.map((livro) => (
                            <tr key={livro.livroId}>
                                <td>{livro.livroId}</td>
                                <td>{livro.titulo}</td>
                                <td>{livro.autor?.nome + ' ' + livro.autor?.sobrenome}</td>
                                <td>{livro.genero}</td>
                                <td>{livro.editora}</td>
                                <td>{livro.anoLancamento}</td>
                                <td>{livro.qtdExemplares}</td>
                                <td>{livro.criadoEm ? formatarDataHora(livro.criadoEm) : 'Data não disponível'}</td>
                                <td>
                                    <button onClick={() => deletar(livro.livroId!)}>
                                        Deletar
                                    </button> 
                                </td>
                                <td>
                                    <Link to={`/pages/livro/alterar/${livro.livroId}`}>
                                        Alterar
                                    </Link>
                                </td>
                            </tr>
                        ))
                    ) : (
                        <tr>
                            <td colSpan={10}>Nenhum livro encontrado.</td>
                        </tr>
                    )}
                </tbody>
            </table>
        </div>
    );
}

export default LivroLista;