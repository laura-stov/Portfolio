import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Emprestimo } from "../../../models/Emprestimo";
import axios from "axios";

function EmprestimoLista() {
    const [emprestimos, setEmprestimos] = useState<Emprestimo[]>([]);
    const navigate = useNavigate();

    useEffect(() => {
        fetch("http://localhost:5274/biblioteca/emprestimo/listar", {
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
                    setEmprestimos(JSON.parse(data)); // Processa somente se não estiver vazio
                } else {
                    setEmprestimos([]); // Define lista vazia se o corpo for vazio
                }
            })
            .catch((error) => {
                console.error("Erro ao buscar empréstimos:", error);
            });
    }, []);

    function deletar(id: string) {
        axios
            .delete(`http://localhost:5274/biblioteca/emprestimo/deletar/${id}`)
            .then(() => {
                console.log("Empréstimo deletado com sucesso!");
                window.location.reload();
            });
    }

    function devolver(id: string) {
        axios
            .put(`http://localhost:5274/biblioteca/emprestimo/devolver/${id}`)
            .then(() => {
                console.log("Livro devolvido com sucesso!");
                navigate("/pages/devolucao/listar");
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
            <h1>Lista de Empréstimos</h1>
            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Leitor</th>
                        <th>CPF do Leitor</th>
                        <th>Livro</th>
                        <th>Autor</th>
                        <th>Data Empréstimo</th>
                        <th>Prazo Devolução</th>
                        <th>Status</th>
                        <th>Devolver</th>
                        <th>Deletar</th>
                        <th>Alterar</th>
                    </tr>
                </thead>
                <tbody>
                    {emprestimos.length > 0 ? (
                        emprestimos.map((emprestimo) => (
                            <tr key={emprestimo.emprestimoId}>
                                <td>{emprestimo.emprestimoId}</td>
                                <td>{emprestimo.leitor.nome + ' ' + emprestimo.leitor.sobrenome}</td>
                                <td>{emprestimo.leitor.cpf}</td>
                                <td>{emprestimo.livro.titulo}</td>
                                <td>{emprestimo.livro.autor?.nome + ' ' + emprestimo.livro.autor?.sobrenome}</td>
                                <td>{formatarDataHora(emprestimo.dataEmprestimo)}</td>
                                <td>{formatarDataHora(emprestimo.prazoDevolucao)}</td>
                                <td>{emprestimo.ativo ? "Ativo" : "Devolvido"}</td>
                                <td>
                                    <button className="devolver" onClick={() => devolver(emprestimo.emprestimoId!)}>
                                        Devolver
                                    </button> 
                                </td>
                                <td>
                                    <button onClick={() => deletar(emprestimo.emprestimoId!)}>
                                        Deletar
                                    </button> 
                                </td>
                                <td>
                                    <Link to={`/pages/emprestimo/alterar/${emprestimo.emprestimoId}`}>
                                        Alterar
                                    </Link>
                                </td>
                            </tr>
                        ))
                    ) : (
                        <tr>
                            <td colSpan={11}>Nenhum empréstimo encontrado.</td>
                        </tr>
                    )}
                </tbody>
            </table>
        </div>
    );
}

export default EmprestimoLista;
